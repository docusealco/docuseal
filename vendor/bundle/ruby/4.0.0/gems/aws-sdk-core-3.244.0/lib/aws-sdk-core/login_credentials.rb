# frozen_string_literal: true

module Aws
  # An auto-refreshing credential provider that retrieves credentials from
  # a cached login token. This class does NOT implement the AWS Sign-In
  # login flow - tokens must be generated separately by running `aws login`
  # from the AWS CLI/AWS Tools for PowerShell with the correct profile.
  # The {LoginCredentials} will auto-refresh the AWS credentials from AWS Sign-In.
  #
  #     # You must first run aws login --profile your-login-profile
  #     login_credentials = Aws::LoginCredentials.new(login_session: 'my_login_session')
  #     ec2 = Aws::EC2::Client.new(credentials: login_credentials)
  #
  # If you omit the `:client` option, a new {Aws::Signin::Client} object will
  # be constructed with additional options that were provided.
  class LoginCredentials
    include CredentialProvider
    include RefreshingCredentials

    # @option options [required, String] :login_session An opaque string
    #   used to determine the cache file location. This value can be found
    #   in the AWS config file which is set by the AWS CLI/AWS Tools for
    #   PowerShell automatically.
    #
    # @option options [Signin::Client] :client Optional `Signin::Client`.
    #   If not provided, a client will be constructed.
    def initialize(options = {})
      raise ArgumentError, 'Missing login_session' unless options[:login_session]

      @login_session = options.delete(:login_session)
      @client = options[:client]
      unless @client
        client_opts = options.reject { |key, _| CLIENT_EXCLUDE_OPTIONS.include?(key) }
        @client = Signin::Client.new(client_opts.merge(credentials: nil))
      end
      @metrics = ['CREDENTIALS_LOGIN']
      @async_refresh = true
      super
    end

    # @return [Signin::Client]
    attr_reader :client

    private

    def refresh
      # First reload the token from disk to ensure it hasn't been refreshed externally
      token_json = read_cached_token
      update_creds(token_json['accessToken'])
      return if @credentials && @expiration && !near_expiration?(sync_expiration_length)

      # Using OpenSSL 3.6.0 may result in errors like "certificate verify failed (unable to get certificate CRL)."
      # A recommended workaround is to use OpenSSL version < 3.6.0 or requiring the openssl gem with a version of at
      # least 3.2.2. GitHub issue: https://github.com/openssl/openssl/issues/28752.
      if OpenSSL::OPENSSL_LIBRARY_VERSION.include?('3.6.') &&
         (!Gem.loaded_specs['openssl'] || Gem.loaded_specs['openssl'].version < Gem::Version.new('3.2.2'))
        warn 'WARNING: OpenSSL 3.6.x may cause certificate verify errors - use OpenSSL < 3.6.0 or openssl gem >= 3.2.2'
      end

      # Attempt to refresh the token
      attempt_refresh(token_json)

      # Raise if token is hard expired
      return unless !@expiration || @expiration < Time.now

      raise Errors::InvalidLoginToken,
            'Login token is invalid and failed to refresh. Please reauthenticate.'
    end

    def read_cached_token
      cached_token = JSON.load_file(login_cache_file)
      validate_cached_token(cached_token)
      cached_token
    rescue Errno::ENOENT, Aws::Json::ParseError
      raise Errors::InvalidLoginToken,
            "Failed to load a Login token for login session #{@login_session}. Please reauthenticate."
    end

    def login_cache_file
      directory = ENV['AWS_LOGIN_CACHE_DIRECTORY'] || File.join(Dir.home, '.aws', 'login', 'cache')
      login_session_sha = OpenSSL::Digest::SHA256.hexdigest(@login_session.strip.encode('utf-8'))
      File.join(directory, "#{login_session_sha}.json")
    end

    def validate_cached_token(cached_token)
      required_cached_token_fields = %w[accessToken clientId refreshToken dpopKey]
      missing_fields = required_cached_token_fields.reject { |field| cached_token[field] }
      unless missing_fields.empty?
        raise ArgumentError, "Cached login token is missing required field(s): #{missing_fields}. " \
          'Please reauthenticate.'
      end

      access_token = cached_token['accessToken']
      required_access_token_fields = %w[accessKeyId secretAccessKey sessionToken accountId expiresAt]
      missing_fields = required_access_token_fields.reject { |field| access_token[field] }

      return if missing_fields.empty?

      raise ArgumentError, "Access token in cached login token is missing required field(s): #{missing_fields}. " \
        'Please reauthenticate.'
    end

    def update_creds(access_token)
      @credentials = Credentials.new(
        access_token['accessKeyId'],
        access_token['secretAccessKey'],
        access_token['sessionToken'],
        account_id: access_token['accountId']
      )
      @expiration = Time.parse(access_token['expiresAt'])
    end

    def attempt_refresh(token_json)
      resp = make_request(token_json)
      parse_resp(resp.token_output, token_json)
      update_creds(token_json['accessToken'])
      update_token_cache(token_json)
    rescue Signin::Errors::AccessDeniedException => e
      case e.error
      when 'TOKEN_EXPIRED'
        warn 'Your session has expired. Please reauthenticate.'
      when 'USER_CREDENTIALS_CHANGED'
        warn 'Unable to refresh credentials because of a change in your password. ' \
          'Please reauthenticate with your new password.'
      when 'INSUFFICIENT_PERMISSIONS'
        warn 'Unable to refresh credentials due to insufficient permissions. ' \
          'You may be missing permission for the `CreateOAuth2Token` action.'
      end
    rescue StandardError => e
      warn("Failed to refresh Login token for LoginCredentials: #{e.message}")
    end

    def make_request(token_json)
      options = {
        token_input: {
          client_id: token_json['clientId'],
          grant_type: 'refresh_token',
          refresh_token: token_json['refreshToken']
        }
      }
      req = @client.build_request(:create_o_auth_2_token, options)
      endpoint_params = Aws::Signin::EndpointParameters.create(req.context.config)
      endpoint = req.context.config.endpoint_provider.resolve_endpoint(endpoint_params)
      endpoint = URI.join(endpoint.url, @client.config.api.operation(:create_o_auth_2_token).http_request_uri).to_s
      req.context.http_request.headers['DPoP'] = dpop_proof(token_json['dpopKey'], endpoint)
      req.send_request
    end

    def dpop_proof(dpop_key, endpoint)
      # Load private key from cached token file
      private_key = OpenSSL::PKey.read(dpop_key)
      public_key = private_key.public_key.to_octet_string(:uncompressed)

      # Construct header and payload
      header = build_header(public_key[1, 32], public_key[33, 32])
      payload = build_payload(endpoint)

      # Base64URL encode header and payload, sign message using private key, and create header
      message = build_message(header, payload)
      signature = private_key.sign(OpenSSL::Digest.new('SHA256'), message)
      jws_signature = der_to_jws(signature)
      "#{message}.#{Base64.urlsafe_encode64(jws_signature, padding: false)}"
    end

    def build_header(x_bytes, y_bytes)
      {
        'alg' => 'ES256', # signing algorithm
        'jwk' => {
          'crv' => 'P-256', # curve name
          'kty' => 'EC', # key type
          'x' => Base64.urlsafe_encode64(x_bytes, padding: false), # public x coordinate
          'y' => Base64.urlsafe_encode64(y_bytes, padding: false) # public y coordinate
        },
        'typ' => 'dpop+jwt' # hardcoded
      }
    end

    def build_payload(htu)
      {
        'jti' => SecureRandom.uuid, # unique identifier (UUID4)
        'htm' => @client.config.api.operation(:create_o_auth_2_token).http_method, # POST
        'htu' => htu, # endpoint of the CreateOAuth2Token operation, with path
        'iat' => Time.now.utc.to_i # UTC timestamp, specified number of seconds from 1970-01-01T00:00:00Z UTC
      }
    end

    def build_message(header, payload)
      encoded_header = Base64.urlsafe_encode64(JSON.dump(header), padding: false)
      encoded_payload = Base64.urlsafe_encode64(JSON.dump(payload), padding: false)
      "#{encoded_header}.#{encoded_payload}"
    end

    # Converts DER-encoded ASN.1 signature to JWS
    def der_to_jws(der_signature)
      asn1 = OpenSSL::ASN1.decode(der_signature)
      r = asn1.value[0].value
      s = asn1.value[1].value

      r_hex = r.to_s(16).rjust(64, '0')
      s_hex = s.to_s(16).rjust(64, '0')

      [r_hex + s_hex].pack('H*')
    end

    def parse_resp(resp, token_json)
      access_token = token_json['accessToken']
      access_token.merge!(
        'accessKeyId' => resp.access_token.access_key_id,
        'secretAccessKey' => resp.access_token.secret_access_key,
        'sessionToken' => resp.access_token.session_token,
        'expiresAt' => (Time.now.utc + resp.expires_in).to_datetime.rfc3339
      )
      token_json['refreshToken'] = resp.refresh_token
    end

    def update_token_cache(token_json)
      cached_token = token_json.dup
      # File.write is not atomic so use temp file and move
      temp_file = Tempfile.new('temp_file')
      begin
        temp_file.write(Json.dump(cached_token))
        temp_file.close
        FileUtils.mv(temp_file.path, login_cache_file)
      ensure
        temp_file.unlink if File.exist?(temp_file.path) # Ensure temp file is cleaned up
      end
    end
  end
end
