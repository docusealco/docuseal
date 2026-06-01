# frozen_string_literal: true

require 'time'
require 'net/http'

module Aws
  # An auto-refreshing credential provider that loads credentials from EC2 instances.
  #
  #     instance_credentials = Aws::InstanceProfileCredentials.new
  #     ec2 = Aws::EC2::Client.new(credentials: instance_credentials)
  #
  # ## Retries
  # When initialized from the default credential chain, this provider defaults to `0` retries.
  # Breakdown of retries is as follows:
  #
  #  * **Configurable retries** (defaults to `1`): these retries handle errors when communicating
  #     with the IMDS endpoint. There are two separate retry mechanisms within the provider:
  #       * Entire token fetch and credential retrieval process
  #       * Token fetching
  #  * **JSON parsing retries**: Fixed at 3 attempts to handle cases when IMDS returns malformed JSON
  #     responses. These retries are separate from configurable retries.
  #
  # @see https://docs.aws.amazon.com/sdkref/latest/guide/feature-imds-credentials.html IMDS Credential Provider
  class InstanceProfileCredentials
    include CredentialProvider
    include RefreshingCredentials

    # @api private
    class Non200Response < RuntimeError
      attr_reader :status_code, :body

      def initialize(status_code, body = nil)
        @status_code = status_code
        @body = body
        msg = "HTTP #{status_code}"
        msg += ": #{body}" if body && !body.empty?
        super(msg)
      end
    end

    # @api private
    class TokenRetrivalError < RuntimeError; end

    # @api private
    class TokenExpiredError < RuntimeError; end

    # These are the errors we trap when attempting to talk to the instance metadata service.
    # Any of these imply the service is not present, no responding or some other non-recoverable error.
    # @api private
    NETWORK_ERRORS = [
      Errno::EHOSTUNREACH,
      Errno::ECONNREFUSED,
      Errno::EHOSTDOWN,
      Errno::ENETUNREACH,
      SocketError,
      Timeout::Error,
      Non200Response
    ].freeze

    # Path base for GET request for profile and credentials
    # @api private
    METADATA_PATH_BASE = '/latest/meta-data/iam/security-credentials/'.freeze

    # Path for PUT request for token
    # @api private
    METADATA_TOKEN_PATH = '/latest/api/token'.freeze

    # @param [Hash] options
    # @option options [Integer] :retries (1) Number of times to retry when retrieving credentials.
    # @option options [Numeric, Proc] :backoff By default, failures are retried with exponential back-off, i.e.
    #   `lambda { |num_failures| sleep(1.2 ** num_failures) }`. You can pass a number of seconds to sleep
    #   between failed attempts, or a Proc that accepts the number of failures.
    # @option options [String] :endpoint ('http://169.254.169.254') The IMDS endpoint. This option has precedence
    #    over the `:endpoint_mode`.
    # @option options [String] :endpoint_mode ('IPv4') The endpoint mode for the instance metadata service. This is
    #   either 'IPv4' (`169.254.169.254`) or IPv6' (`[fd00:ec2::254]`).
    # @option options [Boolean] :disable_imds_v1 (false) Disable the use of the legacy EC2 Metadata Service v1.
    # @option options [String] :ip_address ('169.254.169.254') Deprecated. Use `:endpoint` instead.
    #   The IP address for the endpoint.
    # @option options [Integer] :port (80)
    # @option options [Float] :http_open_timeout (1)
    # @option options [Float] :http_read_timeout (1)
    # @option options [IO] :http_debug_output (nil) HTTP wire traces are sent to this object.
    #   You can specify something like `$stdout`.
    # @option options [Integer] :token_ttl (21600) Time-to-Live in seconds for EC2 Metadata Token used for fetching
    #   Metadata Profile Credentials.
    # @option options [Proc] :before_refresh A Proc called before credentials are refreshed. `:before_refresh`
    #   is called with an instance of this object when AWS credentials are required and need to be refreshed.
    def initialize(options = {})
      @backoff = resolve_backoff(options[:backoff])
      @disable_imds_v1 = resolve_disable_v1(options)
      @endpoint = resolve_endpoint(options)
      @http_open_timeout = options[:http_open_timeout] || 1
      @http_read_timeout = options[:http_read_timeout] || 1
      @http_debug_output = options[:http_debug_output]
      @port = options[:port] || 80
      @retries = options[:retries] || 1
      @token_ttl = options[:token_ttl] || 21_600

      @async_refresh = false
      @imds_v1_fallback = false
      @no_refresh_until = nil
      @token = nil
      @metrics = ['CREDENTIALS_IMDS']
      super
    end

    # @return [Boolean]
    attr_reader :disable_imds_v1

    # @return [Integer]
    attr_reader :token_ttl

    # @return [Integer]
    attr_reader :retries

    # @return [Proc]
    attr_reader :backoff

    # @return [String]
    attr_reader :endpoint

    # @return [Integer]
    attr_reader :port

    # @return [Integer]
    attr_reader :http_open_timeout

    # @return [Integer]
    attr_reader :http_read_timeout

    # @return [IO, nil]
    attr_reader :http_debug_output

    private

    def resolve_endpoint_mode(options)
      options[:endpoint_mode] ||
        ENV['AWS_EC2_METADATA_SERVICE_ENDPOINT_MODE'] ||
        Aws.shared_config.ec2_metadata_service_endpoint_mode(profile: options[:profile]) ||
        'IPv4'
    end

    def resolve_endpoint(options)
      if (value = options[:ip_address])
        warn('The `:ip_address` option is deprecated. Use `:endpoint` instead.')
        return value
      end

      value =
        options[:endpoint] ||
        ENV['AWS_EC2_METADATA_SERVICE_ENDPOINT'] ||
        Aws.shared_config.ec2_metadata_service_endpoint(profile: options[:profile]) ||
        nil
      return value if value

      endpoint_mode = resolve_endpoint_mode(options)
      case endpoint_mode.downcase
      when 'ipv4' then 'http://169.254.169.254'
      when 'ipv6' then 'http://[fd00:ec2::254]'
      else
        raise ArgumentError, ":endpoint_mode is not valid, expected IPv4 or IPv6, got: #{endpoint_mode}"
      end
    end

    def resolve_disable_v1(options)
      value =
        options[:disable_imds_v1] ||
        ENV['AWS_EC2_METADATA_V1_DISABLED'] ||
        Aws.shared_config.ec2_metadata_v1_disabled(profile: options[:profile]) ||
        'false'
      Aws::Util.str_2_bool(value.to_s.downcase)
    end

    def resolve_backoff(backoff)
      case backoff
      when Proc then backoff
      when Numeric then ->(_) { sleep(backoff) }
      else ->(num_failures) { Kernel.sleep(1.2**num_failures) }
      end
    end

    def refresh
      if @no_refresh_until && @no_refresh_until > Time.now
        warn_expired_credentials
        return
      end

      new_creds =
        begin
          # Retry loading credentials up to 3 times is the instance metadata
          # service is responding but is returning invalid JSON documents
          # in response to the GET profile credentials call.
          retry_errors([Aws::Json::ParseError], max_retries: 3) do
            Aws::Json.load(retrieve_credentials.to_s)
          end
        rescue Aws::Json::ParseError
          raise Aws::Errors::MetadataParserError
        end

      if @credentials&.set? && empty_credentials?(new_creds)
        # credentials are already set, but there was an error getting new credentials
        # so don't update the credentials and use stale ones (static stability)
        @no_refresh_until = Time.now + rand(300..360)
        warn_expired_credentials
      else
        # credentials are empty or successfully retrieved, update them
        update_credentials(new_creds)
      end
    end

    def retrieve_credentials
      # Retry loading credentials a configurable number of times if
      # the instance metadata service is not responding.
      begin
        retry_errors(NETWORK_ERRORS, max_retries: @retries) do
          open_connection do |conn|
            # attempt to fetch token to start secure flow first
            # and rescue to failover
            fetch_token(conn) unless @imds_v1_fallback || (@token && !@token.expired?)

            # disable insecure flow if we couldn't get token and imds v1 is disabled
            raise TokenRetrivalError if @token.nil? && @disable_imds_v1

            fetch_credentials(conn)
          end
        end
      rescue StandardError => e
        warn("Error retrieving instance profile credentials: #{e}")
        '{}'
      end
    end

    def update_credentials(creds)
      @credentials = Credentials.new(creds['AccessKeyId'], creds['SecretAccessKey'], creds['Token'])
      @expiration = creds['Expiration'] ? Time.iso8601(creds['Expiration']) : nil
      return unless @expiration && @expiration < Time.now

      @no_refresh_until = Time.now + rand(300..360)
      warn_expired_credentials
    end

    def fetch_token(conn)
      created_time = Time.now
      token_value, ttl = http_put(conn)
      @token = Token.new(token_value, ttl, created_time) if token_value && ttl
    rescue *NETWORK_ERRORS
      # token attempt failed, reset token
      # fallback to non-token mode
      @imds_v1_fallback = true
    end

    def fetch_credentials(conn)
      metadata = http_get(conn, METADATA_PATH_BASE)
      profile_name = metadata.lines.first.strip
      http_get(conn, METADATA_PATH_BASE + profile_name)
    rescue TokenExpiredError
      # Token has expired, reset it
      # The next retry should fetch it
      @token = nil
      @imds_v1_fallback = false
      raise Non200Response.new(401, 'Token expired')
    end

    def token_set?
      @token && !@token.expired?
    end

    def open_connection
      uri = URI.parse(@endpoint)
      http = Net::HTTP.new(uri.hostname || @endpoint, uri.port || @port)
      http.open_timeout = @http_open_timeout
      http.read_timeout = @http_read_timeout
      http.set_debug_output(@http_debug_output) if @http_debug_output
      http.start
      yield(http).tap { http.finish }
    end

    # GET request fetch profile and credentials
    def http_get(connection, path)
      headers = { 'User-Agent' => "aws-sdk-ruby3/#{CORE_GEM_VERSION}" }
      headers['x-aws-ec2-metadata-token'] = @token.value if @token
      response = connection.request(Net::HTTP::Get.new(path, headers))

      case response.code.to_i
      when 200
        response.body
      when 401
        raise TokenExpiredError
      else
        raise Non200Response.new(response.code.to_i, response.body)
      end
    end

    # PUT request fetch token with ttl
    def http_put(connection)
      headers = {
        'User-Agent' => "aws-sdk-ruby3/#{CORE_GEM_VERSION}",
        'x-aws-ec2-metadata-token-ttl-seconds' => @token_ttl.to_s
      }
      response = connection.request(Net::HTTP::Put.new(METADATA_TOKEN_PATH, headers))
      case response.code.to_i
      when 200
        [
          response.body,
          response.header['x-aws-ec2-metadata-token-ttl-seconds'].to_i
        ]
      when 400
        raise TokenRetrivalError
      else
        raise Non200Response.new(response.code.to_i, response.body)
      end
    end

    def retry_errors(error_classes, options = {}, &_block)
      max_retries = options[:max_retries]
      retries = 0
      begin
        yield
      rescue *error_classes
        raise unless retries < max_retries

        @backoff.call(retries)
        retries += 1
        retry
      end
    end

    def warn_expired_credentials
      warn('Attempting credential expiration extension due to a credential service availability issue. '\
             'A refresh of these credentials will be attempted again in 5 minutes.')
    end

    def empty_credentials?(creds_hash)
      !creds_hash['AccessKeyId'] || creds_hash['AccessKeyId'].empty?
    end

    # @api private
    # Token used to fetch IMDS profile and credentials
    class Token
      def initialize(value, ttl, created_time = Time.now)
        @ttl = ttl
        @value = value
        @created_time = created_time
      end

      # [String] token value
      attr_reader :value

      def expired?
        Time.now - @created_time > @ttl
      end
    end
  end
end
