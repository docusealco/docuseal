# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

require 'seahorse/client/plugins/content_length'
require 'aws-sdk-core/plugins/credentials_configuration'
require 'aws-sdk-core/plugins/logging'
require 'aws-sdk-core/plugins/param_converter'
require 'aws-sdk-core/plugins/param_validator'
require 'aws-sdk-core/plugins/user_agent'
require 'aws-sdk-core/plugins/helpful_socket_errors'
require 'aws-sdk-core/plugins/retry_errors'
require 'aws-sdk-core/plugins/global_configuration'
require 'aws-sdk-core/plugins/regional_endpoint'
require 'aws-sdk-core/plugins/endpoint_discovery'
require 'aws-sdk-core/plugins/endpoint_pattern'
require 'aws-sdk-core/plugins/response_paging'
require 'aws-sdk-core/plugins/stub_responses'
require 'aws-sdk-core/plugins/idempotency_token'
require 'aws-sdk-core/plugins/invocation_id'
require 'aws-sdk-core/plugins/jsonvalue_converter'
require 'aws-sdk-core/plugins/client_metrics_plugin'
require 'aws-sdk-core/plugins/client_metrics_send_plugin'
require 'aws-sdk-core/plugins/transfer_encoding'
require 'aws-sdk-core/plugins/http_checksum'
require 'aws-sdk-core/plugins/checksum_algorithm'
require 'aws-sdk-core/plugins/request_compression'
require 'aws-sdk-core/plugins/defaults_mode'
require 'aws-sdk-core/plugins/recursion_detection'
require 'aws-sdk-core/plugins/telemetry'
require 'aws-sdk-core/plugins/sign'
require 'aws-sdk-core/plugins/protocols/json_rpc'

module Aws::KMS
  # An API client for KMS.  To construct a client, you need to configure a `:region` and `:credentials`.
  #
  #     client = Aws::KMS::Client.new(
  #       region: region_name,
  #       credentials: credentials,
  #       # ...
  #     )
  #
  # For details on configuring region and credentials see
  # the [developer guide](/sdk-for-ruby/v3/developer-guide/setup-config.html).
  #
  # See {#initialize} for a full list of supported configuration options.
  class Client < Seahorse::Client::Base

    include Aws::ClientStubs

    @identifier = :kms

    set_api(ClientApi::API)

    add_plugin(Seahorse::Client::Plugins::ContentLength)
    add_plugin(Aws::Plugins::CredentialsConfiguration)
    add_plugin(Aws::Plugins::Logging)
    add_plugin(Aws::Plugins::ParamConverter)
    add_plugin(Aws::Plugins::ParamValidator)
    add_plugin(Aws::Plugins::UserAgent)
    add_plugin(Aws::Plugins::HelpfulSocketErrors)
    add_plugin(Aws::Plugins::RetryErrors)
    add_plugin(Aws::Plugins::GlobalConfiguration)
    add_plugin(Aws::Plugins::RegionalEndpoint)
    add_plugin(Aws::Plugins::EndpointDiscovery)
    add_plugin(Aws::Plugins::EndpointPattern)
    add_plugin(Aws::Plugins::ResponsePaging)
    add_plugin(Aws::Plugins::StubResponses)
    add_plugin(Aws::Plugins::IdempotencyToken)
    add_plugin(Aws::Plugins::InvocationId)
    add_plugin(Aws::Plugins::JsonvalueConverter)
    add_plugin(Aws::Plugins::ClientMetricsPlugin)
    add_plugin(Aws::Plugins::ClientMetricsSendPlugin)
    add_plugin(Aws::Plugins::TransferEncoding)
    add_plugin(Aws::Plugins::HttpChecksum)
    add_plugin(Aws::Plugins::ChecksumAlgorithm)
    add_plugin(Aws::Plugins::RequestCompression)
    add_plugin(Aws::Plugins::DefaultsMode)
    add_plugin(Aws::Plugins::RecursionDetection)
    add_plugin(Aws::Plugins::Telemetry)
    add_plugin(Aws::Plugins::Sign)
    add_plugin(Aws::Plugins::Protocols::JsonRpc)
    add_plugin(Aws::KMS::Plugins::Endpoints)

    # @overload initialize(options)
    #   @param [Hash] options
    #
    #   @option options [Array<Seahorse::Client::Plugin>] :plugins ([]])
    #     A list of plugins to apply to the client. Each plugin is either a
    #     class name or an instance of a plugin class.
    #
    #   @option options [required, Aws::CredentialProvider] :credentials
    #     Your AWS credentials used for authentication. This can be any class that includes and implements
    #     `Aws::CredentialProvider`, or instance of any one of the following classes:
    #
    #     * `Aws::Credentials` - Used for configuring static, non-refreshing
    #       credentials.
    #
    #     * `Aws::SharedCredentials` - Used for loading static credentials from a
    #       shared file, such as `~/.aws/config`.
    #
    #     * `Aws::AssumeRoleCredentials` - Used when you need to assume a role.
    #
    #     * `Aws::AssumeRoleWebIdentityCredentials` - Used when you need to
    #       assume a role after providing credentials via the web.
    #
    #     * `Aws::SSOCredentials` - Used for loading credentials from AWS SSO using an
    #       access token generated from `aws login`.
    #
    #     * `Aws::ProcessCredentials` - Used for loading credentials from a
    #       process that outputs to stdout.
    #
    #     * `Aws::InstanceProfileCredentials` - Used for loading credentials
    #       from an EC2 IMDS on an EC2 instance.
    #
    #     * `Aws::ECSCredentials` - Used for loading credentials from
    #       instances running in ECS.
    #
    #     * `Aws::CognitoIdentityCredentials` - Used for loading credentials
    #       from the Cognito Identity service.
    #
    #     When `:credentials` are not configured directly, the following locations will be searched for credentials:
    #
    #     * `Aws.config[:credentials]`
    #
    #     * The `:access_key_id`, `:secret_access_key`, `:session_token`, and
    #       `:account_id` options.
    #
    #     * `ENV['AWS_ACCESS_KEY_ID']`, `ENV['AWS_SECRET_ACCESS_KEY']`,
    #       `ENV['AWS_SESSION_TOKEN']`, and `ENV['AWS_ACCOUNT_ID']`.
    #
    #     * `~/.aws/credentials`
    #
    #     * `~/.aws/config`
    #
    #     * EC2/ECS IMDS instance profile - When used by default, the timeouts are very aggressive.
    #       Construct and pass an instance of `Aws::InstanceProfileCredentials` or `Aws::ECSCredentials` to
    #       enable retries and extended timeouts. Instance profile credential fetching can be disabled by
    #       setting `ENV['AWS_EC2_METADATA_DISABLED']` to `true`.
    #
    #   @option options [required, String] :region
    #     The AWS region to connect to.  The configured `:region` is
    #     used to determine the service `:endpoint`. When not passed,
    #     a default `:region` is searched for in the following locations:
    #
    #     * `Aws.config[:region]`
    #     * `ENV['AWS_REGION']`
    #     * `ENV['AMAZON_REGION']`
    #     * `ENV['AWS_DEFAULT_REGION']`
    #     * `~/.aws/credentials`
    #     * `~/.aws/config`
    #
    #   @option options [String] :access_key_id
    #
    #   @option options [String] :account_id
    #
    #   @option options [Boolean] :active_endpoint_cache (false)
    #     When set to `true`, a thread polling for endpoints will be running in
    #     the background every 60 secs (default). Defaults to `false`.
    #
    #   @option options [Boolean] :adaptive_retry_wait_to_fill (true)
    #     Used only in `adaptive` retry mode.  When true, the request will sleep
    #     until there is sufficent client side capacity to retry the request.
    #     When false, the request will raise a `RetryCapacityNotAvailableError` and will
    #     not retry instead of sleeping.
    #
    #   @option options [Array<String>] :auth_scheme_preference
    #     A list of preferred authentication schemes to use when making a request. Supported values are:
    #     `sigv4`, `sigv4a`, `httpBearerAuth`, and `noAuth`. When set using `ENV['AWS_AUTH_SCHEME_PREFERENCE']` or in
    #     shared config as `auth_scheme_preference`, the value should be a comma-separated list.
    #
    #   @option options [Boolean] :client_side_monitoring (false)
    #     When `true`, client-side metrics will be collected for all API requests from
    #     this client.
    #
    #   @option options [String] :client_side_monitoring_client_id ("")
    #     Allows you to provide an identifier for this client which will be attached to
    #     all generated client side metrics. Defaults to an empty string.
    #
    #   @option options [String] :client_side_monitoring_host ("127.0.0.1")
    #     Allows you to specify the DNS hostname or IPv4 or IPv6 address that the client
    #     side monitoring agent is running on, where client metrics will be published via UDP.
    #
    #   @option options [Integer] :client_side_monitoring_port (31000)
    #     Required for publishing client metrics. The port that the client side monitoring
    #     agent is running on, where client metrics will be published via UDP.
    #
    #   @option options [Aws::ClientSideMonitoring::Publisher] :client_side_monitoring_publisher (Aws::ClientSideMonitoring::Publisher)
    #     Allows you to provide a custom client-side monitoring publisher class. By default,
    #     will use the Client Side Monitoring Agent Publisher.
    #
    #   @option options [Boolean] :convert_params (true)
    #     When `true`, an attempt is made to coerce request parameters into
    #     the required types.
    #
    #   @option options [Boolean] :correct_clock_skew (true)
    #     Used only in `standard` and adaptive retry modes. Specifies whether to apply
    #     a clock skew correction and retry requests with skewed client clocks.
    #
    #   @option options [String] :defaults_mode ("legacy")
    #     See {Aws::DefaultsModeConfiguration} for a list of the
    #     accepted modes and the configuration defaults that are included.
    #
    #   @option options [Boolean] :disable_host_prefix_injection (false)
    #     When `true`, the SDK will not prepend the modeled host prefix to the endpoint.
    #
    #   @option options [Boolean] :disable_request_compression (false)
    #     When set to 'true' the request body will not be compressed
    #     for supported operations.
    #
    #   @option options [String, URI::HTTPS, URI::HTTP] :endpoint
    #     Normally you should not configure the `:endpoint` option
    #     directly. This is normally constructed from the `:region`
    #     option. Configuring `:endpoint` is normally reserved for
    #     connecting to test or custom endpoints. The endpoint should
    #     be a URI formatted like:
    #
    #         'http://example.com'
    #         'https://example.com'
    #         'http://example.com:123'
    #
    #   @option options [Integer] :endpoint_cache_max_entries (1000)
    #     Used for the maximum size limit of the LRU cache storing endpoints data
    #     for endpoint discovery enabled operations. Defaults to 1000.
    #
    #   @option options [Integer] :endpoint_cache_max_threads (10)
    #     Used for the maximum threads in use for polling endpoints to be cached, defaults to 10.
    #
    #   @option options [Integer] :endpoint_cache_poll_interval (60)
    #     When :endpoint_discovery and :active_endpoint_cache is enabled,
    #     Use this option to config the time interval in seconds for making
    #     requests fetching endpoints information. Defaults to 60 sec.
    #
    #   @option options [Boolean] :endpoint_discovery (false)
    #     When set to `true`, endpoint discovery will be enabled for operations when available.
    #
    #   @option options [Boolean] :ignore_configured_endpoint_urls
    #     Setting to true disables use of endpoint URLs provided via environment
    #     variables and the shared configuration file.
    #
    #   @option options [Aws::Log::Formatter] :log_formatter (Aws::Log::Formatter.default)
    #     The log formatter.
    #
    #   @option options [Symbol] :log_level (:info)
    #     The log level to send messages to the `:logger` at.
    #
    #   @option options [Logger] :logger
    #     The Logger instance to send log messages to.  If this option
    #     is not set, logging will be disabled.
    #
    #   @option options [Integer] :max_attempts (3)
    #     An integer representing the maximum number attempts that will be made for
    #     a single request, including the initial attempt.  For example,
    #     setting this value to 5 will result in a request being retried up to
    #     4 times. Used in `standard` and `adaptive` retry modes.
    #
    #   @option options [String] :profile ("default")
    #     Used when loading credentials from the shared credentials file at `HOME/.aws/credentials`.
    #     When not specified, 'default' is used.
    #
    #   @option options [String] :request_checksum_calculation ("when_supported")
    #     Determines when a checksum will be calculated for request payloads. Values are:
    #
    #     * `when_supported` - (default) When set, a checksum will be
    #       calculated for all request payloads of operations modeled with the
    #       `httpChecksum` trait where `requestChecksumRequired` is `true` and/or a
    #       `requestAlgorithmMember` is modeled.
    #     * `when_required` - When set, a checksum will only be calculated for
    #       request payloads of operations modeled with the  `httpChecksum` trait where
    #       `requestChecksumRequired` is `true` or where a `requestAlgorithmMember`
    #       is modeled and supplied.
    #
    #   @option options [Integer] :request_min_compression_size_bytes (10240)
    #     The minimum size in bytes that triggers compression for request
    #     bodies. The value must be non-negative integer value between 0
    #     and 10485780 bytes inclusive.
    #
    #   @option options [String] :response_checksum_validation ("when_supported")
    #     Determines when checksum validation will be performed on response payloads. Values are:
    #
    #     * `when_supported` - (default) When set, checksum validation is performed on all
    #       response payloads of operations modeled with the `httpChecksum` trait where
    #       `responseAlgorithms` is modeled, except when no modeled checksum algorithms
    #       are supported.
    #     * `when_required` - When set, checksum validation is not performed on
    #       response payloads of operations unless the checksum algorithm is supported and
    #       the `requestValidationModeMember` member is set to `ENABLED`.
    #
    #   @option options [Proc] :retry_backoff
    #     A proc or lambda used for backoff. Defaults to 2**retries * retry_base_delay.
    #     This option is only used in the `legacy` retry mode.
    #
    #   @option options [Float] :retry_base_delay (0.3)
    #     The base delay in seconds used by the default backoff function. This option
    #     is only used in the `legacy` retry mode.
    #
    #   @option options [Symbol] :retry_jitter (:none)
    #     A delay randomiser function used by the default backoff function.
    #     Some predefined functions can be referenced by name - :none, :equal, :full,
    #     otherwise a Proc that takes and returns a number. This option is only used
    #     in the `legacy` retry mode.
    #
    #     @see https://www.awsarchitectureblog.com/2015/03/backoff.html
    #
    #   @option options [Integer] :retry_limit (3)
    #     The maximum number of times to retry failed requests.  Only
    #     ~ 500 level server errors and certain ~ 400 level client errors
    #     are retried.  Generally, these are throttling errors, data
    #     checksum errors, networking errors, timeout errors, auth errors,
    #     endpoint discovery, and errors from expired credentials.
    #     This option is only used in the `legacy` retry mode.
    #
    #   @option options [Integer] :retry_max_delay (0)
    #     The maximum number of seconds to delay between retries (0 for no limit)
    #     used by the default backoff function. This option is only used in the
    #     `legacy` retry mode.
    #
    #   @option options [String] :retry_mode ("legacy")
    #     Specifies which retry algorithm to use. Values are:
    #
    #     * `legacy` - The pre-existing retry behavior.  This is default value if
    #       no retry mode is provided.
    #
    #     * `standard` - A standardized set of retry rules across the AWS SDKs.
    #       This includes support for retry quotas, which limit the number of
    #       unsuccessful retries a client can make.
    #
    #     * `adaptive` - An experimental retry mode that includes all the
    #       functionality of `standard` mode along with automatic client side
    #       throttling.  This is a provisional mode that may change behavior
    #       in the future.
    #
    #   @option options [String] :sdk_ua_app_id
    #     A unique and opaque application ID that is appended to the
    #     User-Agent header as app/sdk_ua_app_id. It should have a
    #     maximum length of 50. This variable is sourced from environment
    #     variable AWS_SDK_UA_APP_ID or the shared config profile attribute sdk_ua_app_id.
    #
    #   @option options [String] :secret_access_key
    #
    #   @option options [String] :session_token
    #
    #   @option options [Array] :sigv4a_signing_region_set
    #     A list of regions that should be signed with SigV4a signing. When
    #     not passed, a default `:sigv4a_signing_region_set` is searched for
    #     in the following locations:
    #
    #     * `Aws.config[:sigv4a_signing_region_set]`
    #     * `ENV['AWS_SIGV4A_SIGNING_REGION_SET']`
    #     * `~/.aws/config`
    #
    #   @option options [Boolean] :simple_json (false)
    #     Disables request parameter conversion, validation, and formatting.
    #     Also disables response data type conversions. The request parameters
    #     hash must be formatted exactly as the API expects.This option is useful
    #     when you want to ensure the highest level of performance by avoiding
    #     overhead of walking request parameters and response data structures.
    #
    #   @option options [Boolean] :stub_responses (false)
    #     Causes the client to return stubbed responses. By default
    #     fake responses are generated and returned. You can specify
    #     the response data to return or errors to raise by calling
    #     {ClientStubs#stub_responses}. See {ClientStubs} for more information.
    #
    #     ** Please note ** When response stubbing is enabled, no HTTP
    #     requests are made, and retries are disabled.
    #
    #   @option options [Aws::Telemetry::TelemetryProviderBase] :telemetry_provider (Aws::Telemetry::NoOpTelemetryProvider)
    #     Allows you to provide a telemetry provider, which is used to
    #     emit telemetry data. By default, uses `NoOpTelemetryProvider` which
    #     will not record or emit any telemetry data. The SDK supports the
    #     following telemetry providers:
    #
    #     * OpenTelemetry (OTel) - To use the OTel provider, install and require the
    #     `opentelemetry-sdk` gem and then, pass in an instance of a
    #     `Aws::Telemetry::OTelProvider` for telemetry provider.
    #
    #   @option options [Aws::TokenProvider] :token_provider
    #     Your Bearer token used for authentication. This can be any class that includes and implements
    #     `Aws::TokenProvider`, or instance of any one of the following classes:
    #
    #     * `Aws::StaticTokenProvider` - Used for configuring static, non-refreshing
    #       tokens.
    #
    #     * `Aws::SSOTokenProvider` - Used for loading tokens from AWS SSO using an
    #       access token generated from `aws login`.
    #
    #     When `:token_provider` is not configured directly, the `Aws::TokenProviderChain`
    #     will be used to search for tokens configured for your profile in shared configuration files.
    #
    #   @option options [Boolean] :use_dualstack_endpoint
    #     When set to `true`, dualstack enabled endpoints (with `.aws` TLD)
    #     will be used if available.
    #
    #   @option options [Boolean] :use_fips_endpoint
    #     When set to `true`, fips compatible endpoints will be used if available.
    #     When a `fips` region is used, the region is normalized and this config
    #     is set to `true`.
    #
    #   @option options [Boolean] :validate_params (true)
    #     When `true`, request parameters are validated before
    #     sending the request.
    #
    #   @option options [Aws::KMS::EndpointProvider] :endpoint_provider
    #     The endpoint provider used to resolve endpoints. Any object that responds to
    #     `#resolve_endpoint(parameters)` where `parameters` is a Struct similar to
    #     `Aws::KMS::EndpointParameters`.
    #
    #   @option options [Float] :http_continue_timeout (1)
    #     The number of seconds to wait for a 100-continue response before sending the
    #     request body.  This option has no effect unless the request has "Expect"
    #     header set to "100-continue".  Defaults to `nil` which  disables this
    #     behaviour.  This value can safely be set per request on the session.
    #
    #   @option options [Float] :http_idle_timeout (5)
    #     The number of seconds a connection is allowed to sit idle before it
    #     is considered stale.  Stale connections are closed and removed from the
    #     pool before making a request.
    #
    #   @option options [Float] :http_open_timeout (15)
    #     The default number of seconds to wait for response data.
    #     This value can safely be set per-request on the session.
    #
    #   @option options [URI::HTTP,String] :http_proxy
    #     A proxy to send requests through.  Formatted like 'http://proxy.com:123'.
    #
    #   @option options [Float] :http_read_timeout (60)
    #     The default number of seconds to wait for response data.
    #     This value can safely be set per-request on the session.
    #
    #   @option options [Boolean] :http_wire_trace (false)
    #     When `true`,  HTTP debug output will be sent to the `:logger`.
    #
    #   @option options [Proc] :on_chunk_received
    #     When a Proc object is provided, it will be used as callback when each chunk
    #     of the response body is received. It provides three arguments: the chunk,
    #     the number of bytes received, and the total number of
    #     bytes in the response (or nil if the server did not send a `content-length`).
    #
    #   @option options [Proc] :on_chunk_sent
    #     When a Proc object is provided, it will be used as callback when each chunk
    #     of the request body is sent. It provides three arguments: the chunk,
    #     the number of bytes read from the body, and the total number of
    #     bytes in the body.
    #
    #   @option options [Boolean] :raise_response_errors (true)
    #     When `true`, response errors are raised.
    #
    #   @option options [String] :ssl_ca_bundle
    #     Full path to the SSL certificate authority bundle file that should be used when
    #     verifying peer certificates.  If you do not pass `:ssl_ca_bundle` or
    #     `:ssl_ca_directory` the the system default will be used if available.
    #
    #   @option options [String] :ssl_ca_directory
    #     Full path of the directory that contains the unbundled SSL certificate
    #     authority files for verifying peer certificates.  If you do
    #     not pass `:ssl_ca_bundle` or `:ssl_ca_directory` the the system
    #     default will be used if available.
    #
    #   @option options [String] :ssl_ca_store
    #     Sets the X509::Store to verify peer certificate.
    #
    #   @option options [OpenSSL::X509::Certificate] :ssl_cert
    #     Sets a client certificate when creating http connections.
    #
    #   @option options [OpenSSL::PKey] :ssl_key
    #     Sets a client key when creating http connections.
    #
    #   @option options [Float] :ssl_timeout
    #     Sets the SSL timeout in seconds
    #
    #   @option options [Boolean] :ssl_verify_peer (true)
    #     When `true`, SSL peer certificates are verified when establishing a connection.
    #
    def initialize(*args)
      super
    end

    # @!group API Operations

    # Cancels the deletion of a KMS key. When this operation succeeds, the
    # key state of the KMS key is `Disabled`. To enable the KMS key, use
    # EnableKey.
    #
    # For more information about scheduling and canceling deletion of a KMS
    # key, see [Deleting KMS keys][1] in the *Key Management Service
    # Developer Guide*.
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][2] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: No. You cannot perform this operation on a KMS
    # key in a different Amazon Web Services account.
    #
    # **Required permissions**: [kms:CancelKeyDeletion][3] (key policy)
    #
    # **Related operations**: ScheduleKeyDeletion
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][4].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Identifies the KMS key whose deletion is being canceled.
    #
    #   Specify the key ID or key ARN of the KMS key.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    # @return [Types::CancelKeyDeletionResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::CancelKeyDeletionResponse#key_id #key_id} => String
    #
    #
    # @example Example: To cancel deletion of a KMS key
    #
    #   # The following example cancels deletion of the specified KMS key.
    #
    #   resp = client.cancel_key_deletion({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key whose deletion you are canceling. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The ARN of the KMS key whose deletion you canceled.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.cancel_key_deletion({
    #     key_id: "KeyIdType", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.key_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CancelKeyDeletion AWS API Documentation
    #
    # @overload cancel_key_deletion(params = {})
    # @param [Hash] params ({})
    def cancel_key_deletion(params = {}, options = {})
      req = build_request(:cancel_key_deletion, params)
      req.send_request(options)
    end

    # Connects or reconnects a [custom key store][1] to its backing key
    # store. For an CloudHSM key store, `ConnectCustomKeyStore` connects the
    # key store to its associated CloudHSM cluster. For an external key
    # store, `ConnectCustomKeyStore` connects the key store to the external
    # key store proxy that communicates with your external key manager.
    #
    # The custom key store must be connected before you can create KMS keys
    # in the key store or use the KMS keys it contains. You can disconnect
    # and reconnect a custom key store at any time.
    #
    # The connection process for a custom key store can take an extended
    # amount of time to complete. This operation starts the connection
    # process, but it does not wait for it to complete. When it succeeds,
    # this operation quickly returns an HTTP 200 response and a JSON object
    # with no properties. However, this response does not indicate that the
    # custom key store is connected. To get the connection state of the
    # custom key store, use the DescribeCustomKeyStores operation.
    #
    # This operation is part of the custom key stores feature in KMS, which
    # combines the convenience and extensive integration of KMS with the
    # isolation and control of a key store that you own and manage.
    #
    # The `ConnectCustomKeyStore` operation might fail for various reasons.
    # To find the reason, use the DescribeCustomKeyStores operation and see
    # the `ConnectionErrorCode` in the response. For help interpreting the
    # `ConnectionErrorCode`, see CustomKeyStoresListEntry.
    #
    # To fix the failure, use the DisconnectCustomKeyStore operation to
    # disconnect the custom key store, correct the error, use the
    # UpdateCustomKeyStore operation if necessary, and then use
    # `ConnectCustomKeyStore` again.
    #
    # **CloudHSM key store**
    #
    # During the connection process for an CloudHSM key store, KMS finds the
    # CloudHSM cluster that is associated with the custom key store, creates
    # the connection infrastructure, connects to the cluster, logs into the
    # CloudHSM client as the `kmsuser` CU, and rotates its password.
    #
    # To connect an CloudHSM key store, its associated CloudHSM cluster must
    # have at least one active HSM. To get the number of active HSMs in a
    # cluster, use the [DescribeClusters][2] operation. To add HSMs to the
    # cluster, use the [CreateHsm][3] operation. Also, the [ `kmsuser`
    # crypto user][4] (CU) must not be logged into the cluster. This
    # prevents KMS from using this account to log in.
    #
    # If you are having trouble connecting or disconnecting a CloudHSM key
    # store, see [Troubleshooting an CloudHSM key store][5] in the *Key
    # Management Service Developer Guide*.
    #
    # **External key store**
    #
    # When you connect an external key store that uses public endpoint
    # connectivity, KMS tests its ability to communicate with your external
    # key manager by sending a request via the external key store proxy.
    #
    # When you connect to an external key store that uses VPC endpoint
    # service connectivity, KMS establishes the networking elements that it
    # needs to communicate with your external key manager via the external
    # key store proxy. This includes creating an interface endpoint to the
    # VPC endpoint service and a private hosted zone for traffic between KMS
    # and the VPC endpoint service.
    #
    # To connect an external key store, KMS must be able to connect to the
    # external key store proxy, the external key store proxy must be able to
    # communicate with your external key manager, and the external key
    # manager must be available for cryptographic operations.
    #
    # If you are having trouble connecting or disconnecting an external key
    # store, see [Troubleshooting an external key store][6] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: No. You cannot perform this operation on a
    # custom key store in a different Amazon Web Services account.
    #
    # **Required permissions**: [kms:ConnectCustomKeyStore][7] (IAM policy)
    #
    # **Related operations**
    #
    # * CreateCustomKeyStore
    #
    # * DeleteCustomKeyStore
    #
    # * DescribeCustomKeyStores
    #
    # * DisconnectCustomKeyStore
    #
    # * UpdateCustomKeyStore
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][8].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-store-overview.html
    # [2]: https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_DescribeClusters.html
    # [3]: https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_CreateHsm.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/keystore-cloudhsm.html#concept-kmsuser
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html
    # [6]: https://docs.aws.amazon.com/kms/latest/developerguide/xks-troubleshooting.html
    # [7]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [8]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :custom_key_store_id
    #   Enter the key store ID of the custom key store that you want to
    #   connect. To find the ID of a custom key store, use the
    #   DescribeCustomKeyStores operation.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To connect a custom key store
    #
    #   # This example connects an AWS KMS custom key store to its backing key store. For an AWS CloudHSM key store, it connects
    #   # the key store to its AWS CloudHSM cluster. For an external key store, it connects the key store to the external key
    #   # store proxy that communicates with your external key manager. This operation does not return any data. To verify that
    #   # the custom key store is connected, use the <code>DescribeCustomKeyStores</code> operation.
    #
    #   resp = client.connect_custom_key_store({
    #     custom_key_store_id: "cks-1234567890abcdef0", # The ID of the AWS KMS custom key store.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.connect_custom_key_store({
    #     custom_key_store_id: "CustomKeyStoreIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ConnectCustomKeyStore AWS API Documentation
    #
    # @overload connect_custom_key_store(params = {})
    # @param [Hash] params ({})
    def connect_custom_key_store(params = {}, options = {})
      req = build_request(:connect_custom_key_store, params)
      req.send_request(options)
    end

    # Creates a friendly name for a KMS key.
    #
    # <note markdown="1"> Adding, deleting, or updating an alias can allow or deny permission to
    # the KMS key. For details, see [ABAC for KMS][1] in the *Key Management
    # Service Developer Guide*.
    #
    #  </note>
    #
    # You can use an alias to identify a KMS key in the KMS console, in the
    # DescribeKey operation and in [cryptographic operations][2], such as
    # Encrypt and GenerateDataKey. You can also change the KMS key that's
    # associated with the alias (UpdateAlias) or delete the alias
    # (DeleteAlias) at any time. These operations don't affect the
    # underlying KMS key.
    #
    # You can associate the alias with any customer managed key in the same
    # Amazon Web Services Region. Each alias is associated with only one KMS
    # key at a time, but a KMS key can have multiple aliases. A valid KMS
    # key is required. You can't create an alias without a KMS key.
    #
    # The alias must be unique in the account and Region, but you can have
    # aliases with the same name in different Regions. For detailed
    # information about aliases, see [Aliases in KMS][3] in the *Key
    # Management Service Developer Guide*.
    #
    # This operation does not return a response. To get the alias that you
    # created, use the ListAliases operation.
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][4] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: No. You cannot perform this operation on an
    # alias in a different Amazon Web Services account.
    #
    # **Required permissions**
    #
    # * [kms:CreateAlias][5] on the alias (IAM policy).
    #
    # * [kms:CreateAlias][5] on the KMS key (key policy).
    #
    # For details, see [Controlling access to aliases][6] in the *Key
    # Management Service Developer Guide*.
    #
    # **Related operations:**
    #
    # * DeleteAlias
    #
    # * ListAliases
    #
    # * UpdateAlias
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][7].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/abac.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-cryptography.html#cryptographic-operations
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-alias.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [6]: https://docs.aws.amazon.com/kms/latest/developerguide/alias-access.html
    # [7]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :alias_name
    #   Specifies the alias name. This value must begin with `alias/` followed
    #   by a name, such as `alias/ExampleAlias`.
    #
    #   Do not include confidential or sensitive information in this field.
    #   This field may be displayed in plaintext in CloudTrail logs and other
    #   output.
    #
    #   The `AliasName` value must be string of 1-256 characters. It can
    #   contain only alphanumeric characters, forward slashes (/), underscores
    #   (\_), and dashes (-). The alias name cannot begin with `alias/aws/`.
    #   The `alias/aws/` prefix is reserved for [Amazon Web Services managed
    #   keys][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-key
    #
    # @option params [required, String] :target_key_id
    #   Associates the alias with the specified [customer managed key][1]. The
    #   KMS key must be in the same Amazon Web Services Region.
    #
    #   A valid key ID is required. If you supply a null or empty string
    #   value, this operation returns an error.
    #
    #   For help finding the key ID and ARN, see [Find the key ID and key
    #   ARN][2] in the <i> <i>Key Management Service Developer Guide</i> </i>.
    #
    #   Specify the key ID or key ARN of the KMS key.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-mgn-key
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/find-cmk-id-arn.html
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To create an alias
    #
    #   # The following example creates an alias for the specified KMS key.
    #
    #   resp = client.create_alias({
    #     alias_name: "alias/ExampleAlias", # The alias to create. Aliases must begin with 'alias/'. Do not use aliases that begin with 'alias/aws' because they are reserved for use by AWS.
    #     target_key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key whose alias you are creating. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.create_alias({
    #     alias_name: "AliasNameType", # required
    #     target_key_id: "KeyIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CreateAlias AWS API Documentation
    #
    # @overload create_alias(params = {})
    # @param [Hash] params ({})
    def create_alias(params = {}, options = {})
      req = build_request(:create_alias, params)
      req.send_request(options)
    end

    # Creates a [custom key store][1] backed by a key store that you own and
    # manage. When you use a KMS key in a custom key store for a
    # cryptographic operation, the cryptographic operation is actually
    # performed in your key store using your keys. KMS supports [CloudHSM
    # key stores][2] backed by an [CloudHSM cluster][3] and [external key
    # stores][4] backed by an external key store proxy and external key
    # manager outside of Amazon Web Services.
    #
    # This operation is part of the custom key stores feature in KMS, which
    # combines the convenience and extensive integration of KMS with the
    # isolation and control of a key store that you own and manage.
    #
    # Before you create the custom key store, the required elements must be
    # in place and operational. We recommend that you use the test tools
    # that KMS provides to verify the configuration your external key store
    # proxy. For details about the required elements and verification tests,
    # see [Assemble the prerequisites (for CloudHSM key stores)][5] or
    # [Assemble the prerequisites (for external key stores)][6] in the *Key
    # Management Service Developer Guide*.
    #
    # To create a custom key store, use the following parameters.
    #
    # * To create an CloudHSM key store, specify the `CustomKeyStoreName`,
    #   `CloudHsmClusterId`, `KeyStorePassword`, and
    #   `TrustAnchorCertificate`. The `CustomKeyStoreType` parameter is
    #   optional for CloudHSM key stores. If you include it, set it to the
    #   default value, `AWS_CLOUDHSM`. For help with failures, see
    #   [Troubleshooting an CloudHSM key store][7] in the *Key Management
    #   Service Developer Guide*.
    #
    # * To create an external key store, specify the `CustomKeyStoreName`
    #   and a `CustomKeyStoreType` of `EXTERNAL_KEY_STORE`. Also, specify
    #   values for `XksProxyConnectivity`,
    #   `XksProxyAuthenticationCredential`, `XksProxyUriEndpoint`, and
    #   `XksProxyUriPath`. If your `XksProxyConnectivity` value is
    #   `VPC_ENDPOINT_SERVICE`, specify the `XksProxyVpcEndpointServiceName`
    #   parameter. For help with failures, see [Troubleshooting an external
    #   key store][8] in the *Key Management Service Developer Guide*.
    #
    # <note markdown="1"> For external key stores:
    #
    #  Some external key managers provide a simpler method for creating an
    # external key store. For details, see your external key manager
    # documentation.
    #
    #  When creating an external key store in the KMS console, you can upload
    # a JSON-based proxy configuration file with the desired values. You
    # cannot use a proxy configuration with the `CreateCustomKeyStore`
    # operation. However, you can use the values in the file to help you
    # determine the correct values for the `CreateCustomKeyStore`
    # parameters.
    #
    #  </note>
    #
    # When the operation completes successfully, it returns the ID of the
    # new custom key store. Before you can use your new custom key store,
    # you need to use the ConnectCustomKeyStore operation to connect a new
    # CloudHSM key store to its CloudHSM cluster, or to connect a new
    # external key store to the external key store proxy for your external
    # key manager. Even if you are not going to use your custom key store
    # immediately, you might want to connect it to verify that all settings
    # are correct and then disconnect it until you are ready to use it.
    #
    # **Cross-account use**: No. You cannot perform this operation on a
    # custom key store in a different Amazon Web Services account.
    #
    # **Required permissions**: [kms:CreateCustomKeyStore][9] (IAM policy).
    #
    # **Related operations:**
    #
    # * ConnectCustomKeyStore
    #
    # * DeleteCustomKeyStore
    #
    # * DescribeCustomKeyStores
    #
    # * DisconnectCustomKeyStore
    #
    # * UpdateCustomKeyStore
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][10].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-store-overview.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/keystore-cloudhsm.html
    # [3]: https://docs.aws.amazon.com/cloudhsm/latest/userguide/clusters.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/keystore-external.html
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/create-keystore.html#before-keystore
    # [6]: https://docs.aws.amazon.com/kms/latest/developerguide/create-xks-keystore.html#xks-requirements
    # [7]: https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html
    # [8]: https://docs.aws.amazon.com/kms/latest/developerguide/xks-troubleshooting.html
    # [9]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [10]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :custom_key_store_name
    #   Specifies a friendly name for the custom key store. The name must be
    #   unique in your Amazon Web Services account and Region. This parameter
    #   is required for all custom key stores.
    #
    #   Do not include confidential or sensitive information in this field.
    #   This field may be displayed in plaintext in CloudTrail logs and other
    #   output.
    #
    # @option params [String] :cloud_hsm_cluster_id
    #   Identifies the CloudHSM cluster for an CloudHSM key store. This
    #   parameter is required for custom key stores with `CustomKeyStoreType`
    #   of `AWS_CLOUDHSM`.
    #
    #   Enter the cluster ID of any active CloudHSM cluster that is not
    #   already associated with a custom key store. To find the cluster ID,
    #   use the [DescribeClusters][1] operation.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_DescribeClusters.html
    #
    # @option params [String] :trust_anchor_certificate
    #   Specifies the certificate for an CloudHSM key store. This parameter is
    #   required for custom key stores with a `CustomKeyStoreType` of
    #   `AWS_CLOUDHSM`.
    #
    #   Enter the content of the trust anchor certificate for the CloudHSM
    #   cluster. This is the content of the `customerCA.crt` file that you
    #   created when you [initialized the cluster][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/cloudhsm/latest/userguide/initialize-cluster.html
    #
    # @option params [String] :key_store_password
    #   Specifies the `kmsuser` password for an CloudHSM key store. This
    #   parameter is required for custom key stores with a
    #   `CustomKeyStoreType` of `AWS_CLOUDHSM`.
    #
    #   Enter the password of the [ `kmsuser` crypto user (CU) account][1] in
    #   the specified CloudHSM cluster. KMS logs into the cluster as this user
    #   to manage key material on your behalf.
    #
    #   The password must be a string of 7 to 32 characters. Its value is case
    #   sensitive.
    #
    #   This parameter tells KMS the `kmsuser` account password; it does not
    #   change the password in the CloudHSM cluster.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/keystore-cloudhsm.html#concept-kmsuser
    #
    # @option params [String] :custom_key_store_type
    #   Specifies the type of custom key store. The default value is
    #   `AWS_CLOUDHSM`.
    #
    #   For a custom key store backed by an CloudHSM cluster, omit the
    #   parameter or enter `AWS_CLOUDHSM`. For a custom key store backed by an
    #   external key manager outside of Amazon Web Services, enter
    #   `EXTERNAL_KEY_STORE`. You cannot change this property after the key
    #   store is created.
    #
    # @option params [String] :xks_proxy_uri_endpoint
    #   Specifies the endpoint that KMS uses to send requests to the external
    #   key store proxy (XKS proxy). This parameter is required for custom key
    #   stores with a `CustomKeyStoreType` of `EXTERNAL_KEY_STORE`.
    #
    #   The protocol must be HTTPS. KMS communicates on port 443. Do not
    #   specify the port in the `XksProxyUriEndpoint` value.
    #
    #   For external key stores with `XksProxyConnectivity` value of
    #   `VPC_ENDPOINT_SERVICE`, specify `https://` followed by the private DNS
    #   name of the VPC endpoint service.
    #
    #   For external key stores with `PUBLIC_ENDPOINT` connectivity, this
    #   endpoint must be reachable before you create the custom key store. KMS
    #   connects to the external key store proxy while creating the custom key
    #   store. For external key stores with `VPC_ENDPOINT_SERVICE`
    #   connectivity, KMS connects when you call the ConnectCustomKeyStore
    #   operation.
    #
    #   The value of this parameter must begin with `https://`. The remainder
    #   can contain upper and lower case letters (A-Z and a-z), numbers (0-9),
    #   dots (`.`), and hyphens (`-`). Additional slashes (`/` and ``) are
    #   not permitted.
    #
    #   <b>Uniqueness requirements: </b>
    #
    #   * The combined `XksProxyUriEndpoint` and `XksProxyUriPath` values must
    #     be unique in the Amazon Web Services account and Region.
    #
    #   * An external key store with `PUBLIC_ENDPOINT` connectivity cannot use
    #     the same `XksProxyUriEndpoint` value as an external key store with
    #     `VPC_ENDPOINT_SERVICE` connectivity in this Amazon Web Services
    #     Region.
    #
    #   * Each external key store with `VPC_ENDPOINT_SERVICE` connectivity
    #     must have its own private DNS name. The `XksProxyUriEndpoint` value
    #     for external key stores with `VPC_ENDPOINT_SERVICE` connectivity
    #     (private DNS name) must be unique in the Amazon Web Services account
    #     and Region.
    #
    # @option params [String] :xks_proxy_uri_path
    #   Specifies the base path to the proxy APIs for this external key store.
    #   To find this value, see the documentation for your external key store
    #   proxy. This parameter is required for all custom key stores with a
    #   `CustomKeyStoreType` of `EXTERNAL_KEY_STORE`.
    #
    #   The value must start with `/` and must end with `/kms/xks/v1` where
    #   `v1` represents the version of the KMS external key store proxy API.
    #   This path can include an optional prefix between the required elements
    #   such as `/prefix/kms/xks/v1`.
    #
    #   <b>Uniqueness requirements: </b>
    #
    #   * The combined `XksProxyUriEndpoint` and `XksProxyUriPath` values must
    #     be unique in the Amazon Web Services account and Region.
    #
    #   ^
    #
    # @option params [String] :xks_proxy_vpc_endpoint_service_name
    #   Specifies the name of the Amazon VPC endpoint service for interface
    #   endpoints that is used to communicate with your external key store
    #   proxy (XKS proxy). This parameter is required when the value of
    #   `CustomKeyStoreType` is `EXTERNAL_KEY_STORE` and the value of
    #   `XksProxyConnectivity` is `VPC_ENDPOINT_SERVICE`.
    #
    #   The Amazon VPC endpoint service must [fulfill all requirements][1] for
    #   use with an external key store.
    #
    #   **Uniqueness requirements:**
    #
    #   * External key stores with `VPC_ENDPOINT_SERVICE` connectivity can
    #     share an Amazon VPC, but each external key store must have its own
    #     VPC endpoint service and private DNS name.
    #
    #   ^
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/create-xks-keystore.html#xks-requirements
    #
    # @option params [String] :xks_proxy_vpc_endpoint_service_owner
    #   Specifies the Amazon Web Services account ID that owns the Amazon VPC
    #   service endpoint for the interface that is used to communicate with
    #   your external key store proxy (XKS proxy). This parameter is optional.
    #   If not provided, the Amazon Web Services account ID calling the action
    #   will be used.
    #
    # @option params [Types::XksProxyAuthenticationCredentialType] :xks_proxy_authentication_credential
    #   Specifies an authentication credential for the external key store
    #   proxy (XKS proxy). This parameter is required for all custom key
    #   stores with a `CustomKeyStoreType` of `EXTERNAL_KEY_STORE`.
    #
    #   The `XksProxyAuthenticationCredential` has two required elements:
    #   `RawSecretAccessKey`, a secret key, and `AccessKeyId`, a unique
    #   identifier for the `RawSecretAccessKey`. For character requirements,
    #   see
    #   [XksProxyAuthenticationCredentialType](API_XksProxyAuthenticationCredentialType.html).
    #
    #   KMS uses this authentication credential to sign requests to the
    #   external key store proxy on your behalf. This credential is unrelated
    #   to Identity and Access Management (IAM) and Amazon Web Services
    #   credentials.
    #
    #   This parameter doesn't set or change the authentication credentials
    #   on the XKS proxy. It just tells KMS the credential that you
    #   established on your external key store proxy. If you rotate your proxy
    #   authentication credential, use the UpdateCustomKeyStore operation to
    #   provide the new credential to KMS.
    #
    # @option params [String] :xks_proxy_connectivity
    #   Indicates how KMS communicates with the external key store proxy. This
    #   parameter is required for custom key stores with a
    #   `CustomKeyStoreType` of `EXTERNAL_KEY_STORE`.
    #
    #   If the external key store proxy uses a public endpoint, specify
    #   `PUBLIC_ENDPOINT`. If the external key store proxy uses a Amazon VPC
    #   endpoint service for communication with KMS, specify
    #   `VPC_ENDPOINT_SERVICE`. For help making this choice, see [Choosing a
    #   connectivity option][1] in the *Key Management Service Developer
    #   Guide*.
    #
    #   An Amazon VPC endpoint service keeps your communication with KMS in a
    #   private address space entirely within Amazon Web Services, but it
    #   requires more configuration, including establishing a Amazon VPC with
    #   multiple subnets, a VPC endpoint service, a network load balancer, and
    #   a verified private DNS name. A public endpoint is simpler to set up,
    #   but it might be slower and might not fulfill your security
    #   requirements. You might consider testing with a public endpoint, and
    #   then establishing a VPC endpoint service for production tasks. Note
    #   that this choice does not determine the location of the external key
    #   store proxy. Even if you choose a VPC endpoint service, the proxy can
    #   be hosted within the VPC or outside of Amazon Web Services such as in
    #   your corporate data center.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/choose-xks-connectivity.html
    #
    # @return [Types::CreateCustomKeyStoreResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::CreateCustomKeyStoreResponse#custom_key_store_id #custom_key_store_id} => String
    #
    #
    # @example Example: To create an AWS CloudHSM key store
    #
    #   # This example creates a custom key store that is associated with an AWS CloudHSM cluster.
    #
    #   resp = client.create_custom_key_store({
    #     cloud_hsm_cluster_id: "cluster-234abcdefABC", # The ID of the CloudHSM cluster.
    #     custom_key_store_name: "ExampleKeyStore", # A friendly name for the custom key store.
    #     key_store_password: "kmsPswd", # The password for the kmsuser CU account in the specified cluster.
    #     trust_anchor_certificate: "<certificate-goes-here>", # The content of the customerCA.crt file that you created when you initialized the cluster.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     custom_key_store_id: "cks-1234567890abcdef0", # The ID of the new custom key store.
    #   }
    #
    # @example Example: To create an external key store with VPC endpoint service connectivity
    #
    #   # This example creates an external key store that uses an Amazon VPC endpoint service to communicate with AWS KMS.
    #
    #   resp = client.create_custom_key_store({
    #     custom_key_store_name: "ExampleVPCEndpointKeyStore", # A friendly name for the custom key store
    #     custom_key_store_type: "EXTERNAL_KEY_STORE", # For external key stores, the value must be EXTERNAL_KEY_STORE
    #     xks_proxy_authentication_credential: {
    #       access_key_id: "ABCDE12345670EXAMPLE", 
    #       raw_secret_access_key: "DXjSUawnel2fr6SKC7G25CNxTyWKE5PF9XX6H/u9pSo=", 
    #     }, # The access key ID and secret access key that KMS uses to authenticate to your external key store proxy
    #     xks_proxy_connectivity: "VPC_ENDPOINT_SERVICE", # Indicates how AWS KMS communicates with the external key store proxy
    #     xks_proxy_uri_endpoint: "https://myproxy-private.xks.example.com", # The URI that AWS KMS uses to connect to the external key store proxy
    #     xks_proxy_uri_path: "/example-prefix/kms/xks/v1", # The URI path to the external key store proxy APIs
    #     xks_proxy_vpc_endpoint_service_name: "com.amazonaws.vpce.us-east-1.vpce-svc-example1", # The VPC endpoint service that KMS uses to communicate with the external key store proxy
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     custom_key_store_id: "cks-1234567890abcdef0", # The ID of the new custom key store.
    #   }
    #
    # @example Example: To create an external key store with public endpoint connectivity
    #
    #   # This example creates an external key store with public endpoint connectivity.
    #
    #   resp = client.create_custom_key_store({
    #     custom_key_store_name: "ExamplePublicEndpointKeyStore", # A friendly name for the custom key store
    #     custom_key_store_type: "EXTERNAL_KEY_STORE", # For external key stores, the value must be EXTERNAL_KEY_STORE
    #     xks_proxy_authentication_credential: {
    #       access_key_id: "ABCDE12345670EXAMPLE", 
    #       raw_secret_access_key: "DXjSUawnel2fr6SKC7G25CNxTyWKE5PF9XX6H/u9pSo=", 
    #     }, # The access key ID and secret access key that KMS uses to authenticate to your external key store proxy
    #     xks_proxy_connectivity: "PUBLIC_ENDPOINT", # Indicates how AWS KMS communicates with the external key store proxy
    #     xks_proxy_uri_endpoint: "https://myproxy.xks.example.com", # The URI that AWS KMS uses to connect to the external key store proxy
    #     xks_proxy_uri_path: "/kms/xks/v1", # The URI path to your external key store proxy API
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     custom_key_store_id: "cks-987654321abcdef0", # The ID of the new custom key store.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.create_custom_key_store({
    #     custom_key_store_name: "CustomKeyStoreNameType", # required
    #     cloud_hsm_cluster_id: "CloudHsmClusterIdType",
    #     trust_anchor_certificate: "TrustAnchorCertificateType",
    #     key_store_password: "KeyStorePasswordType",
    #     custom_key_store_type: "AWS_CLOUDHSM", # accepts AWS_CLOUDHSM, EXTERNAL_KEY_STORE
    #     xks_proxy_uri_endpoint: "XksProxyUriEndpointType",
    #     xks_proxy_uri_path: "XksProxyUriPathType",
    #     xks_proxy_vpc_endpoint_service_name: "XksProxyVpcEndpointServiceNameType",
    #     xks_proxy_vpc_endpoint_service_owner: "AccountIdType",
    #     xks_proxy_authentication_credential: {
    #       access_key_id: "XksProxyAuthenticationAccessKeyIdType", # required
    #       raw_secret_access_key: "XksProxyAuthenticationRawSecretAccessKeyType", # required
    #     },
    #     xks_proxy_connectivity: "PUBLIC_ENDPOINT", # accepts PUBLIC_ENDPOINT, VPC_ENDPOINT_SERVICE
    #   })
    #
    # @example Response structure
    #
    #   resp.custom_key_store_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CreateCustomKeyStore AWS API Documentation
    #
    # @overload create_custom_key_store(params = {})
    # @param [Hash] params ({})
    def create_custom_key_store(params = {}, options = {})
      req = build_request(:create_custom_key_store, params)
      req.send_request(options)
    end

    # Adds a grant to a KMS key.
    #
    # A *grant* is a policy instrument that allows Amazon Web Services
    # principals to use KMS keys in cryptographic operations. It also can
    # allow them to view a KMS key (DescribeKey) and create and manage
    # grants. When authorizing access to a KMS key, grants are considered
    # along with key policies and IAM policies. Grants are often used for
    # temporary permissions because you can create one, use its permissions,
    # and delete it without changing your key policies or IAM policies.
    #
    # For detailed information about grants, including grant terminology,
    # see [Grants in KMS][1] in the <i> <i>Key Management Service Developer
    # Guide</i> </i>. For examples of creating grants in several programming
    # languages, see [Use CreateGrant with an Amazon Web Services SDK or
    # CLI][2].
    #
    # The `CreateGrant` operation returns a `GrantToken` and a `GrantId`.
    #
    # * When you create, retire, or revoke a grant, there might be a brief
    #   delay, usually less than five minutes, until the grant is available
    #   throughout KMS. This state is known as *eventual consistency*. Once
    #   the grant has achieved eventual consistency, the grantee principal
    #   can use the permissions in the grant without identifying the grant.
    #
    #   However, to use the permissions in the grant immediately, use the
    #   `GrantToken` that `CreateGrant` returns. For details, see [Using a
    #   grant token][3] in the <i> <i>Key Management Service Developer
    #   Guide</i> </i>.
    #
    # * The `CreateGrant` operation also returns a `GrantId`. You can use
    #   the `GrantId` and a key identifier to identify the grant in the
    #   RetireGrant and RevokeGrant operations. To find the grant ID, use
    #   the ListGrants or ListRetirableGrants operations.
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][4] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: Yes. To perform this operation on a KMS key in
    # a different Amazon Web Services account, specify the key ARN in the
    # value of the `KeyId` parameter.
    #
    # **Required permissions**: [kms:CreateGrant][5] (key policy)
    #
    # **Related operations:**
    #
    # * ListGrants
    #
    # * ListRetirableGrants
    #
    # * RetireGrant
    #
    # * RevokeGrant
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][6].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/example_kms_CreateGrant_section.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/using-grant-token.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [6]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Identifies the KMS key for the grant. The grant gives principals
    #   permission to use this KMS key.
    #
    #   Specify the key ID or key ARN of the KMS key. To specify a KMS key in
    #   a different Amazon Web Services account, you must use the key ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    # @option params [required, String] :grantee_principal
    #   The identity that gets the permissions specified in the grant.
    #
    #   To specify the grantee principal, use the Amazon Resource Name (ARN)
    #   of an Amazon Web Services principal. Valid principals include Amazon
    #   Web Services accounts, IAM users, IAM roles, federated users, and
    #   assumed role users. For help with the ARN syntax for a principal, see
    #   [IAM ARNs][1] in the <i> <i>Identity and Access Management User
    #   Guide</i> </i>.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html#identifiers-arns
    #
    # @option params [String] :retiring_principal
    #   The principal that has permission to use the RetireGrant operation to
    #   retire the grant.
    #
    #   To specify the principal, use the [Amazon Resource Name (ARN)][1] of
    #   an Amazon Web Services principal. Valid principals include Amazon Web
    #   Services accounts, IAM users, IAM roles, federated users, and assumed
    #   role users. For help with the ARN syntax for a principal, see [IAM
    #   ARNs][2] in the <i> <i>Identity and Access Management User Guide</i>
    #   </i>.
    #
    #   The grant determines the retiring principal. Other principals might
    #   have permission to retire the grant or revoke the grant. For details,
    #   see RevokeGrant and [Retiring and revoking grants][3] in the *Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html#identifiers-arns
    #   [3]: https://docs.aws.amazon.com/kms/latest/developerguide/grant-delete.html
    #
    # @option params [required, Array<String>] :operations
    #   A list of operations that the grant permits.
    #
    #   This list must include only operations that are permitted in a grant.
    #   Also, the operation must be supported on the KMS key. For example, you
    #   cannot create a grant for a symmetric encryption KMS key that allows
    #   the Sign operation, or a grant for an asymmetric KMS key that allows
    #   the GenerateDataKey operation. If you try, KMS returns a
    #   `ValidationError` exception. For details, see [Grant operations][1] in
    #   the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html#terms-grant-operations
    #
    # @option params [Types::GrantConstraints] :constraints
    #   Specifies a grant constraint.
    #
    #   Do not include confidential or sensitive information in this field.
    #   This field may be displayed in plaintext in CloudTrail logs and other
    #   output.
    #
    #   KMS supports the `EncryptionContextEquals` and
    #   `EncryptionContextSubset` grant constraints, which allow the
    #   permissions in the grant only when the encryption context in the
    #   request matches (`EncryptionContextEquals`) or includes
    #   (`EncryptionContextSubset`) the encryption context specified in the
    #   constraint.
    #
    #   The encryption context grant constraints are supported only on [grant
    #   operations][1] that include an `EncryptionContext` parameter, such as
    #   cryptographic operations on symmetric encryption KMS keys. Grants with
    #   grant constraints can include the DescribeKey and RetireGrant
    #   operations, but the constraint doesn't apply to these operations. If
    #   a grant with a grant constraint includes the `CreateGrant` operation,
    #   the constraint requires that any grants created with the `CreateGrant`
    #   permission have an equally strict or stricter encryption context
    #   constraint.
    #
    #   You cannot use an encryption context grant constraint for
    #   cryptographic operations with asymmetric KMS keys or HMAC KMS keys.
    #   Operations with these keys don't support an encryption context.
    #
    #   Each constraint value can include up to 8 encryption context pairs.
    #   The encryption context value in each constraint cannot exceed 384
    #   characters. For information about grant constraints, see [Using grant
    #   constraints][2] in the *Key Management Service Developer Guide*. For
    #   more information about encryption context, see [Encryption context][3]
    #   in the <i> <i>Key Management Service Developer Guide</i> </i>.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html#terms-grant-operations
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/create-grant-overview.html#grant-constraints
    #   [3]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#encrypt_context
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   Use a grant token when your permission to call this operation comes
    #   from a new grant that has not yet achieved *eventual consistency*. For
    #   more information, see [Grant token][1] and [Using a grant token][2] in
    #   the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html#grant_token
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/using-grant-token.html
    #
    # @option params [String] :name
    #   A friendly name for the grant. Use this value to prevent the
    #   unintended creation of duplicate grants when retrying this request.
    #
    #   Do not include confidential or sensitive information in this field.
    #   This field may be displayed in plaintext in CloudTrail logs and other
    #   output.
    #
    #   When this value is absent, all `CreateGrant` requests result in a new
    #   grant with a unique `GrantId` even if all the supplied parameters are
    #   identical. This can result in unintended duplicates when you retry the
    #   `CreateGrant` request.
    #
    #   When this value is present, you can retry a `CreateGrant` request with
    #   identical parameters; if the grant already exists, the original
    #   `GrantId` is returned without creating a new grant. Note that the
    #   returned grant token is unique with every `CreateGrant` request, even
    #   when a duplicate `GrantId` is returned. All grant tokens for the same
    #   grant ID can be used interchangeably.
    #
    # @option params [Boolean] :dry_run
    #   Checks if your request will succeed. `DryRun` is an optional
    #   parameter.
    #
    #   To learn more about how to use this parameter, see [Testing your
    #   permissions][1] in the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/testing-permissions.html
    #
    # @return [Types::CreateGrantResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::CreateGrantResponse#grant_token #grant_token} => String
    #   * {Types::CreateGrantResponse#grant_id #grant_id} => String
    #
    #
    # @example Example: To create a grant
    #
    #   # The following example creates a grant that allows the specified IAM role to encrypt data with the specified KMS key.
    #
    #   resp = client.create_grant({
    #     grantee_principal: "arn:aws:iam::111122223333:role/ExampleRole", # The identity that is given permission to perform the operations specified in the grant.
    #     key_id: "arn:aws:kms:us-east-2:444455556666:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key to which the grant applies. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #     operations: [
    #       "Encrypt", 
    #       "Decrypt", 
    #     ], # A list of operations that the grant allows.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     grant_id: "0c237476b39f8bc44e45212e08498fbe3151305030726c0590dd8d3e9f3d6a60", # The unique identifier of the grant.
    #     grant_token: "AQpAM2RhZTk1MGMyNTk2ZmZmMzEyYWVhOWViN2I1MWM4Mzc0MWFiYjc0ZDE1ODkyNGFlNTIzODZhMzgyZjBlNGY3NiKIAgEBAgB4Pa6VDCWW__MSrqnre1HIN0Grt00ViSSuUjhqOC8OT3YAAADfMIHcBgkqhkiG9w0BBwaggc4wgcsCAQAwgcUGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMmqLyBTAegIn9XlK5AgEQgIGXZQjkBcl1dykDdqZBUQ6L1OfUivQy7JVYO2-ZJP7m6f1g8GzV47HX5phdtONAP7K_HQIflcgpkoCqd_fUnE114mSmiagWkbQ5sqAVV3ov-VeqgrvMe5ZFEWLMSluvBAqdjHEdMIkHMlhlj4ENZbzBfo9Wxk8b8SnwP4kc4gGivedzFXo-dwN8fxjjq_ZZ9JFOj2ijIbj5FyogDCN0drOfi8RORSEuCEmPvjFRMFAwcmwFkN2NPp89amA", # The grant token.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.create_grant({
    #     key_id: "KeyIdType", # required
    #     grantee_principal: "PrincipalIdType", # required
    #     retiring_principal: "PrincipalIdType",
    #     operations: ["Decrypt"], # required, accepts Decrypt, Encrypt, GenerateDataKey, GenerateDataKeyWithoutPlaintext, ReEncryptFrom, ReEncryptTo, Sign, Verify, GetPublicKey, CreateGrant, RetireGrant, DescribeKey, GenerateDataKeyPair, GenerateDataKeyPairWithoutPlaintext, GenerateMac, VerifyMac, DeriveSharedSecret
    #     constraints: {
    #       encryption_context_subset: {
    #         "EncryptionContextKey" => "EncryptionContextValue",
    #       },
    #       encryption_context_equals: {
    #         "EncryptionContextKey" => "EncryptionContextValue",
    #       },
    #     },
    #     grant_tokens: ["GrantTokenType"],
    #     name: "GrantNameType",
    #     dry_run: false,
    #   })
    #
    # @example Response structure
    #
    #   resp.grant_token #=> String
    #   resp.grant_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CreateGrant AWS API Documentation
    #
    # @overload create_grant(params = {})
    # @param [Hash] params ({})
    def create_grant(params = {}, options = {})
      req = build_request(:create_grant, params)
      req.send_request(options)
    end

    # Creates a unique customer managed [KMS key][1] in your Amazon Web
    # Services account and Region. You can use a KMS key in cryptographic
    # operations, such as encryption and signing. Some Amazon Web Services
    # services let you use KMS keys that you create and manage to protect
    # your service resources.
    #
    # A KMS key is a logical representation of a cryptographic key. In
    # addition to the key material used in cryptographic operations, a KMS
    # key includes metadata, such as the key ID, key policy, creation date,
    # description, and key state.
    #
    # Use the parameters of `CreateKey` to specify the type of KMS key, the
    # source of its key material, its key policy, description, tags, and
    # other properties.
    #
    # <note markdown="1"> KMS has replaced the term *customer master key (CMK)* with *Key
    # Management Service key* and *KMS key*. The concept has not changed. To
    # prevent breaking changes, KMS is keeping some variations of this term.
    #
    #  </note>
    #
    # To create different types of KMS keys, use the following guidance:
    #
    # Symmetric encryption KMS key
    #
    # : By default, `CreateKey` creates a symmetric encryption KMS key with
    #   key material that KMS generates. This is the basic and most widely
    #   used type of KMS key, and provides the best performance.
    #
    #   To create a symmetric encryption KMS key, you don't need to specify
    #   any parameters. The default value for `KeySpec`,
    #   `SYMMETRIC_DEFAULT`, the default value for `KeyUsage`,
    #   `ENCRYPT_DECRYPT`, and the default value for `Origin`, `AWS_KMS`,
    #   create a symmetric encryption KMS key with KMS key material.
    #
    #   If you need a key for basic encryption and decryption or you are
    #   creating a KMS key to protect your resources in an Amazon Web
    #   Services service, create a symmetric encryption KMS key. The key
    #   material in a symmetric encryption key never leaves KMS unencrypted.
    #   You can use a symmetric encryption KMS key to encrypt and decrypt
    #   data up to 4,096 bytes, but they are typically used to generate data
    #   keys and data keys pairs. For details, see GenerateDataKey and
    #   GenerateDataKeyPair.
    #
    #
    #
    # Asymmetric KMS keys
    #
    # : To create an asymmetric KMS key, use the `KeySpec` parameter to
    #   specify the type of key material in the KMS key. Then, use the
    #   `KeyUsage` parameter to determine whether the KMS key will be used
    #   to encrypt and decrypt or sign and verify. You can't change these
    #   properties after the KMS key is created.
    #
    #   Asymmetric KMS keys contain an RSA key pair, Elliptic Curve (ECC)
    #   key pair, ML-DSA key pair or an SM2 key pair (China Regions only).
    #   The private key in an asymmetric KMS key never leaves KMS
    #   unencrypted. However, you can use the GetPublicKey operation to
    #   download the public key so it can be used outside of KMS. Each KMS
    #   key can have only one key usage. KMS keys with RSA key pairs can be
    #   used to encrypt and decrypt data or sign and verify messages (but
    #   not both). KMS keys with NIST-standard ECC key pairs can be used to
    #   sign and verify messages or derive shared secrets (but not both).
    #   KMS keys with `ECC_SECG_P256K1` can be used only to sign and verify
    #   messages. KMS keys with ML-DSA key pairs can be used to sign and
    #   verify messages. KMS keys with SM2 key pairs (China Regions only)
    #   can be used to either encrypt and decrypt data, sign and verify
    #   messages, or derive shared secrets (you must choose one key usage
    #   type). For information about asymmetric KMS keys, see [Asymmetric
    #   KMS keys][2] in the *Key Management Service Developer Guide*.
    #
    #
    #
    # HMAC KMS key
    #
    # : To create an HMAC KMS key, set the `KeySpec` parameter to a key spec
    #   value for HMAC KMS keys. Then set the `KeyUsage` parameter to
    #   `GENERATE_VERIFY_MAC`. You must set the key usage even though
    #   `GENERATE_VERIFY_MAC` is the only valid key usage value for HMAC KMS
    #   keys. You can't change these properties after the KMS key is
    #   created.
    #
    #   HMAC KMS keys are symmetric keys that never leave KMS unencrypted.
    #   You can use HMAC keys to generate (GenerateMac) and verify
    #   (VerifyMac) HMAC codes for messages up to 4096 bytes.
    #
    #
    #
    # Multi-Region primary keys
    #
    # : To create a multi-Region *primary key* in the local Amazon Web
    #   Services Region, use the `MultiRegion` parameter with a value of
    #   `True`. To create a multi-Region *replica key*, that is, a KMS key
    #   with the same key ID and key material as a primary key, but in a
    #   different Amazon Web Services Region, use the ReplicateKey
    #   operation. To change a replica key to a primary key, and its primary
    #   key to a replica key, use the UpdatePrimaryRegion operation.
    #
    #   You can create multi-Region KMS keys for all supported KMS key
    #   types: symmetric encryption KMS keys, HMAC KMS keys, asymmetric
    #   encryption KMS keys, and asymmetric signing KMS keys. You can also
    #   create multi-Region keys with imported key material. However, you
    #   can't create multi-Region keys in a custom key store.
    #
    #   This operation supports *multi-Region keys*, an KMS feature that
    #   lets you create multiple interoperable KMS keys in different Amazon
    #   Web Services Regions. Because these KMS keys have the same key ID,
    #   key material, and other metadata, you can use them interchangeably
    #   to encrypt data in one Amazon Web Services Region and decrypt it in
    #   a different Amazon Web Services Region without re-encrypting the
    #   data or making a cross-Region call. For more information about
    #   multi-Region keys, see [Multi-Region keys in KMS][3] in the *Key
    #   Management Service Developer Guide*.
    #
    #
    #
    # Imported key material
    #
    # : To import your own key material into a KMS key, begin by creating a
    #   KMS key with no key material. To do this, use the `Origin` parameter
    #   of `CreateKey` with a value of `EXTERNAL`. Next, use
    #   GetParametersForImport operation to get a public key and import
    #   token. Use the wrapping public key to encrypt your key material.
    #   Then, use ImportKeyMaterial with your import token to import the key
    #   material. For step-by-step instructions, see [Importing Key
    #   Material][4] in the <i> <i>Key Management Service Developer
    #   Guide</i> </i>.
    #
    #   You can import key material into KMS keys of all supported KMS key
    #   types: symmetric encryption KMS keys, HMAC KMS keys, asymmetric
    #   encryption KMS keys, and asymmetric signing KMS keys. You can also
    #   create multi-Region keys with imported key material. However, you
    #   can't import key material into a KMS key in a custom key store.
    #
    #   To create a multi-Region primary key with imported key material, use
    #   the `Origin` parameter of `CreateKey` with a value of `EXTERNAL` and
    #   the `MultiRegion` parameter with a value of `True`. To create
    #   replicas of the multi-Region primary key, use the ReplicateKey
    #   operation. For instructions, see [Importing key material step 1][5].
    #   For more information about multi-Region keys, see [Multi-Region keys
    #   in KMS][3] in the *Key Management Service Developer Guide*.
    #
    #
    #
    # Custom key store
    #
    # : A [custom key store][6] lets you protect your Amazon Web Services
    #   resources using keys in a backing key store that you own and manage.
    #   When you request a cryptographic operation with a KMS key in a
    #   custom key store, the operation is performed in the backing key
    #   store using its cryptographic keys.
    #
    #   KMS supports [CloudHSM key stores][7] backed by an CloudHSM cluster
    #   and [external key stores][8] backed by an external key manager
    #   outside of Amazon Web Services. When you create a KMS key in an
    #   CloudHSM key store, KMS generates an encryption key in the CloudHSM
    #   cluster and associates it with the KMS key. When you create a KMS
    #   key in an external key store, you specify an existing encryption key
    #   in the external key manager.
    #
    #   <note markdown="1"> Some external key managers provide a simpler method for creating a
    #   KMS key in an external key store. For details, see your external key
    #   manager documentation.
    #
    #    </note>
    #
    #   Before you create a KMS key in a custom key store, the
    #   `ConnectionState` of the key store must be `CONNECTED`. To connect
    #   the custom key store, use the ConnectCustomKeyStore operation. To
    #   find the `ConnectionState`, use the DescribeCustomKeyStores
    #   operation.
    #
    #   To create a KMS key in a custom key store, use the
    #   `CustomKeyStoreId`. Use the default `KeySpec` value,
    #   `SYMMETRIC_DEFAULT`, and the default `KeyUsage` value,
    #   `ENCRYPT_DECRYPT` to create a symmetric encryption key. No other key
    #   type is supported in a custom key store.
    #
    #   To create a KMS key in an [CloudHSM key store][9], use the `Origin`
    #   parameter with a value of `AWS_CLOUDHSM`. The CloudHSM cluster that
    #   is associated with the custom key store must have at least two
    #   active HSMs in different Availability Zones in the Amazon Web
    #   Services Region.
    #
    #   To create a KMS key in an [external key store][10], use the `Origin`
    #   parameter with a value of `EXTERNAL_KEY_STORE` and an `XksKeyId`
    #   parameter that identifies an existing external key.
    #
    #   <note markdown="1"> Some external key managers provide a simpler method for creating a
    #   KMS key in an external key store. For details, see your external key
    #   manager documentation.
    #
    #    </note>
    #
    # **Cross-account use**: No. You cannot use this operation to create a
    # KMS key in a different Amazon Web Services account.
    #
    # **Required permissions**: [kms:CreateKey][11] (IAM policy). To use the
    # `Tags` parameter, [kms:TagResource][11] (IAM policy). For examples and
    # information about related permissions, see [Allow a user to create KMS
    # keys][12] in the *Key Management Service Developer Guide*.
    #
    # **Related operations:**
    #
    # * DescribeKey
    #
    # * ListKeys
    #
    # * ScheduleKeyDeletion
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][13].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#kms-keys
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-overview.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys-create-cmk.html
    # [6]: https://docs.aws.amazon.com/kms/latest/developerguide/key-store-overview.html
    # [7]: https://docs.aws.amazon.com/kms/latest/developerguide/keystore-cloudhsm.html
    # [8]: https://docs.aws.amazon.com/kms/latest/developerguide/keystore-external.html
    # [9]: https://docs.aws.amazon.com/kms/latest/developerguide/create-cmk-keystore.html
    # [10]: https://docs.aws.amazon.com/kms/latest/developerguide/create-xks-keys.html
    # [11]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [12]: https://docs.aws.amazon.com/kms/latest/developerguide/customer-managed-policies.html#iam-policy-example-create-key
    # [13]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [String] :policy
    #   The key policy to attach to the KMS key.
    #
    #   If you provide a key policy, it must meet the following criteria:
    #
    #   * The key policy must allow the calling principal to make a subsequent
    #     `PutKeyPolicy` request on the KMS key. This reduces the risk that
    #     the KMS key becomes unmanageable. For more information, see [Default
    #     key policy][1] in the *Key Management Service Developer Guide*. (To
    #     omit this condition, set `BypassPolicyLockoutSafetyCheck` to true.)
    #
    #   * Each statement in the key policy must contain one or more
    #     principals. The principals in the key policy must exist and be
    #     visible to KMS. When you create a new Amazon Web Services principal,
    #     you might need to enforce a delay before including the new principal
    #     in a key policy because the new principal might not be immediately
    #     visible to KMS. For more information, see [Changes that I make are
    #     not always immediately visible][2] in the *Amazon Web Services
    #     Identity and Access Management User Guide*.
    #
    #   <note markdown="1"> If either of the required `Resource` or `Action` elements are missing
    #   from a key policy statement, the policy statement has no effect. When
    #   a key policy statement is missing one of these elements, the KMS
    #   console correctly reports an error, but the `CreateKey` and
    #   `PutKeyPolicy` API requests succeed, even though the policy statement
    #   is ineffective.
    #
    #    For more information on required key policy elements, see [Elements in
    #   a key policy][3] in the *Key Management Service Developer Guide*.
    #
    #    </note>
    #
    #   If you do not provide a key policy, KMS attaches a default key policy
    #   to the KMS key. For more information, see [Default key policy][4] in
    #   the *Key Management Service Developer Guide*.
    #
    #   <note markdown="1"> If the key policy exceeds the length constraint, KMS returns a
    #   `LimitExceededException`.
    #
    #    </note>
    #
    #   For help writing and formatting a JSON policy document, see the [IAM
    #   JSON Policy Reference][5] in the <i> <i>Identity and Access Management
    #   User Guide</i> </i>.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#prevent-unmanageable-key
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_eventual-consistency
    #   [3]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-overview.html#key-policy-elements
    #   [4]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html
    #   [5]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html
    #
    # @option params [String] :description
    #   A description of the KMS key. Use a description that helps you decide
    #   whether the KMS key is appropriate for a task. The default value is an
    #   empty string (no description).
    #
    #   Do not include confidential or sensitive information in this field.
    #   This field may be displayed in plaintext in CloudTrail logs and other
    #   output.
    #
    #   To set or change the description after the key is created, use
    #   UpdateKeyDescription.
    #
    # @option params [String] :key_usage
    #   Determines the [cryptographic operations][1] for which you can use the
    #   KMS key. The default value is `ENCRYPT_DECRYPT`. This parameter is
    #   optional when you are creating a symmetric encryption KMS key;
    #   otherwise, it is required. You can't change the [ `KeyUsage` ][2]
    #   value after the KMS key is created. Each KMS key can have only one key
    #   usage. This follows key usage best practices according to [NIST SP
    #   800-57 Recommendations for Key Management][3], section 5.2, Key usage.
    #
    #   Select only one valid value.
    #
    #   * For symmetric encryption KMS keys, omit the parameter or specify
    #     `ENCRYPT_DECRYPT`.
    #
    #   * For HMAC KMS keys (symmetric), specify `GENERATE_VERIFY_MAC`.
    #
    #   * For asymmetric KMS keys with RSA key pairs, specify
    #     `ENCRYPT_DECRYPT` or `SIGN_VERIFY`.
    #
    #   * For asymmetric KMS keys with NIST-standard elliptic curve key pairs,
    #     specify `SIGN_VERIFY` or `KEY_AGREEMENT`.
    #
    #   * For asymmetric KMS keys with `ECC_SECG_P256K1` key pairs, specify
    #     `SIGN_VERIFY`.
    #
    #   * For asymmetric KMS keys with ML-DSA key pairs, specify
    #     `SIGN_VERIFY`.
    #
    #   * For asymmetric KMS keys with SM2 key pairs (China Regions only),
    #     specify `ENCRYPT_DECRYPT`, `SIGN_VERIFY`, or `KEY_AGREEMENT`.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-cryptography.html#cryptographic-operations
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/create-keys.html#key-usage
    #   [3]: https://csrc.nist.gov/pubs/sp/800/57/pt1/r5/final
    #
    # @option params [String] :customer_master_key_spec
    #   Instead, use the `KeySpec` parameter.
    #
    #   The `KeySpec` and `CustomerMasterKeySpec` parameters work the same
    #   way. Only the names differ. We recommend that you use `KeySpec`
    #   parameter in your code. However, to avoid breaking changes, KMS
    #   supports both parameters.
    #
    # @option params [String] :key_spec
    #   Specifies the type of KMS key to create. The default value,
    #   `SYMMETRIC_DEFAULT`, creates a KMS key with a 256-bit AES-GCM key that
    #   is used for encryption and decryption, except in China Regions, where
    #   it creates a 128-bit symmetric key that uses SM4 encryption. For a
    #   detailed description of all supported key specs, see [Key spec
    #   reference][1] in the <i> <i>Key Management Service Developer Guide</i>
    #   </i>.
    #
    #   The `KeySpec` determines whether the KMS key contains a symmetric key
    #   or an asymmetric key pair. It also determines the algorithms that the
    #   KMS key supports. You can't change the `KeySpec` after the KMS key is
    #   created. To further restrict the algorithms that can be used with the
    #   KMS key, use a condition key in its key policy or IAM policy. For more
    #   information, see [kms:EncryptionAlgorithm][2], [kms:MacAlgorithm][3],
    #   [kms:KeyAgreementAlgorithm][4], or [kms:SigningAlgorithm][5] in the
    #   <i> <i>Key Management Service Developer Guide</i> </i>.
    #
    #   [Amazon Web Services services that are integrated with KMS][6] use
    #   symmetric encryption KMS keys to protect your data. These services do
    #   not support asymmetric KMS keys or HMAC KMS keys.
    #
    #   KMS supports the following key specs for KMS keys:
    #
    #   * Symmetric encryption key (default)
    #
    #     * `SYMMETRIC_DEFAULT`
    #
    #     ^
    #   * HMAC keys (symmetric)
    #
    #     * `HMAC_224`
    #
    #     * `HMAC_256`
    #
    #     * `HMAC_384`
    #
    #     * `HMAC_512`
    #   * Asymmetric RSA key pairs (encryption and decryption -or- signing and
    #     verification)
    #
    #     * `RSA_2048`
    #
    #     * `RSA_3072`
    #
    #     * `RSA_4096`
    #   * Asymmetric NIST-standard elliptic curve key pairs (signing and
    #     verification -or- deriving shared secrets)
    #
    #     * `ECC_NIST_P256` (secp256r1)
    #
    #     * `ECC_NIST_P384` (secp384r1)
    #
    #     * `ECC_NIST_P521` (secp521r1)
    #
    #     * `ECC_NIST_EDWARDS25519` (ed25519) - signing and verification only
    #
    #       * **Note:** For ECC\_NIST\_EDWARDS25519 KMS keys, the
    #         ED25519\_SHA\_512 signing algorithm requires [ `MessageType:RAW`
    #         ](kms/latest/APIReference/API_Sign.html#KMS-Sign-request-MessageType),
    #         while ED25519\_PH\_SHA\_512 requires [ `MessageType:DIGEST`
    #         ](kms/latest/APIReference/API_Sign.html#KMS-Sign-request-MessageType).
    #         These message types cannot be used interchangeably.
    #
    #       ^
    #   * Other asymmetric elliptic curve key pairs (signing and verification)
    #
    #     * `ECC_SECG_P256K1` (secp256k1), commonly used for cryptocurrencies.
    #
    #     ^
    #   * Asymmetric ML-DSA key pairs (signing and verification)
    #
    #     * `ML_DSA_44`
    #
    #     * `ML_DSA_65`
    #
    #     * `ML_DSA_87`
    #   * SM2 key pairs (encryption and decryption -or- signing and
    #     verification -or- deriving shared secrets)
    #
    #     * `SM2` (China Regions only)
    #
    #     ^
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/symm-asymm-choose-key-spec.html
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/conditions-kms.html#conditions-kms-encryption-algorithm
    #   [3]: https://docs.aws.amazon.com/kms/latest/developerguide/conditions-kms.html#conditions-kms-mac-algorithm
    #   [4]: https://docs.aws.amazon.com/kms/latest/developerguide/conditions-kms.html#conditions-kms-key-agreement-algorithm
    #   [5]: https://docs.aws.amazon.com/kms/latest/developerguide/conditions-kms.html#conditions-kms-signing-algorithm
    #   [6]: http://aws.amazon.com/kms/features/#AWS_Service_Integration
    #
    # @option params [String] :origin
    #   The source of the key material for the KMS key. You cannot change the
    #   origin after you create the KMS key. The default is `AWS_KMS`, which
    #   means that KMS creates the key material.
    #
    #   To [create a KMS key with no key material][1] (for imported key
    #   material), set this value to `EXTERNAL`. For more information about
    #   importing key material into KMS, see [Importing Key Material][2] in
    #   the *Key Management Service Developer Guide*. The `EXTERNAL` origin
    #   value is valid only for symmetric KMS keys.
    #
    #   To [create a KMS key in an CloudHSM key store][3] and create its key
    #   material in the associated CloudHSM cluster, set this value to
    #   `AWS_CLOUDHSM`. You must also use the `CustomKeyStoreId` parameter to
    #   identify the CloudHSM key store. The `KeySpec` value must be
    #   `SYMMETRIC_DEFAULT`.
    #
    #   To [create a KMS key in an external key store][4], set this value to
    #   `EXTERNAL_KEY_STORE`. You must also use the `CustomKeyStoreId`
    #   parameter to identify the external key store and the `XksKeyId`
    #   parameter to identify the associated external key. The `KeySpec` value
    #   must be `SYMMETRIC_DEFAULT`.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys-create-cmk.html
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html
    #   [3]: https://docs.aws.amazon.com/kms/latest/developerguide/create-cmk-keystore.html
    #   [4]: https://docs.aws.amazon.com/kms/latest/developerguide/create-xks-keys.html
    #
    # @option params [String] :custom_key_store_id
    #   Creates the KMS key in the specified [custom key store][1]. The
    #   `ConnectionState` of the custom key store must be `CONNECTED`. To find
    #   the CustomKeyStoreID and ConnectionState use the
    #   DescribeCustomKeyStores operation.
    #
    #   This parameter is valid only for symmetric encryption KMS keys in a
    #   single Region. You cannot create any other type of KMS key in a custom
    #   key store.
    #
    #   When you create a KMS key in an CloudHSM key store, KMS generates a
    #   non-exportable 256-bit symmetric key in its associated CloudHSM
    #   cluster and associates it with the KMS key. When you create a KMS key
    #   in an external key store, you must use the `XksKeyId` parameter to
    #   specify an external key that serves as key material for the KMS key.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-store-overview.html
    #
    # @option params [Boolean] :bypass_policy_lockout_safety_check
    #   Skips ("bypasses") the key policy lockout safety check. The default
    #   value is false.
    #
    #   Setting this value to true increases the risk that the KMS key becomes
    #   unmanageable. Do not set this value to true indiscriminately.
    #
    #    For more information, see [Default key policy][1] in the *Key
    #   Management Service Developer Guide*.
    #
    #   Use this parameter only when you intend to prevent the principal that
    #   is making the request from making a subsequent [PutKeyPolicy][2]
    #   request on the KMS key.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#prevent-unmanageable-key
    #   [2]: https://docs.aws.amazon.com/kms/latest/APIReference/API_PutKeyPolicy.html
    #
    # @option params [Array<Types::Tag>] :tags
    #   Assigns one or more tags to the KMS key. Use this parameter to tag the
    #   KMS key when it is created. To tag an existing KMS key, use the
    #   TagResource operation.
    #
    #   Do not include confidential or sensitive information in this field.
    #   This field may be displayed in plaintext in CloudTrail logs and other
    #   output.
    #
    #   <note markdown="1"> Tagging or untagging a KMS key can allow or deny permission to the KMS
    #   key. For details, see [ABAC for KMS][1] in the *Key Management Service
    #   Developer Guide*.
    #
    #    </note>
    #
    #   To use this parameter, you must have [kms:TagResource][2] permission
    #   in an IAM policy.
    #
    #   Each tag consists of a tag key and a tag value. Both the tag key and
    #   the tag value are required, but the tag value can be an empty (null)
    #   string. You cannot have more than one tag on a KMS key with the same
    #   tag key. If you specify an existing tag key with a different tag
    #   value, KMS replaces the current tag value with the specified one.
    #
    #   When you add tags to an Amazon Web Services resource, Amazon Web
    #   Services generates a cost allocation report with usage and costs
    #   aggregated by tags. Tags can also be used to control access to a KMS
    #   key. For details, see [Tags in KMS][3].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/abac.html
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    #   [3]: https://docs.aws.amazon.com/kms/latest/developerguide/tagging-keys.html
    #
    # @option params [Boolean] :multi_region
    #   Creates a multi-Region primary key that you can replicate into other
    #   Amazon Web Services Regions. You cannot change this value after you
    #   create the KMS key.
    #
    #   For a multi-Region key, set this parameter to `True`. For a
    #   single-Region KMS key, omit this parameter or set it to `False`. The
    #   default value is `False`.
    #
    #   This operation supports *multi-Region keys*, an KMS feature that lets
    #   you create multiple interoperable KMS keys in different Amazon Web
    #   Services Regions. Because these KMS keys have the same key ID, key
    #   material, and other metadata, you can use them interchangeably to
    #   encrypt data in one Amazon Web Services Region and decrypt it in a
    #   different Amazon Web Services Region without re-encrypting the data or
    #   making a cross-Region call. For more information about multi-Region
    #   keys, see [Multi-Region keys in KMS][1] in the *Key Management Service
    #   Developer Guide*.
    #
    #   This value creates a *primary key*, not a replica. To create a
    #   *replica key*, use the ReplicateKey operation.
    #
    #   You can create a symmetric or asymmetric multi-Region key, and you can
    #   create a multi-Region key with imported key material. However, you
    #   cannot create a multi-Region key in a custom key store.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-overview.html
    #
    # @option params [String] :xks_key_id
    #   Identifies the [external key][1] that serves as key material for the
    #   KMS key in an [external key store][2]. Specify the ID that the
    #   [external key store proxy][3] uses to refer to the external key. For
    #   help, see the documentation for your external key store proxy.
    #
    #   This parameter is required for a KMS key with an `Origin` value of
    #   `EXTERNAL_KEY_STORE`. It is not valid for KMS keys with any other
    #   `Origin` value.
    #
    #   The external key must be an existing 256-bit AES symmetric encryption
    #   key hosted outside of Amazon Web Services in an external key manager
    #   associated with the external key store specified by the
    #   `CustomKeyStoreId` parameter. This key must be enabled and configured
    #   to perform encryption and decryption. Each KMS key in an external key
    #   store must use a different external key. For details, see
    #   [Requirements for a KMS key in an external key store][4] in the *Key
    #   Management Service Developer Guide*.
    #
    #   Each KMS key in an external key store is associated two backing keys.
    #   One is key material that KMS generates. The other is the external key
    #   specified by this parameter. When you use the KMS key in an external
    #   key store to encrypt data, the encryption operation is performed first
    #   by KMS using the KMS key material, and then by the external key
    #   manager using the specified external key, a process known as *double
    #   encryption*. For details, see [Double encryption][5] in the *Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/keystore-external.html#concept-external-key
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/keystore-external.html
    #   [3]: https://docs.aws.amazon.com/kms/latest/developerguide/keystore-external.html#concept-xks-proxy
    #   [4]: https://docs.aws.amazon.com/kms/latest/developerguide/create-xks-keys.html#xks-key-requirements
    #   [5]: https://docs.aws.amazon.com/kms/latest/developerguide/keystore-external.html#concept-double-encryption
    #
    # @return [Types::CreateKeyResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::CreateKeyResponse#key_metadata #key_metadata} => Types::KeyMetadata
    #
    #
    # @example Example: To create a KMS key
    #
    #   # The following example creates a symmetric KMS key for encryption and decryption. No parameters are required for this
    #   # operation.
    #
    #   resp = client.create_key({
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_metadata: {
    #       aws_account_id: "111122223333", 
    #       arn: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       creation_date: Time.parse("2017-07-05T14:04:55-07:00"), 
    #       current_key_material_id: "0b7fd7ddbac6eef27907413567cad8c810e2883dc8a7534067a82ee1142fc1e6", 
    #       customer_master_key_spec: "SYMMETRIC_DEFAULT", 
    #       description: "", 
    #       enabled: true, 
    #       encryption_algorithms: [
    #         "SYMMETRIC_DEFAULT", 
    #       ], 
    #       key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       key_manager: "CUSTOMER", 
    #       key_spec: "SYMMETRIC_DEFAULT", 
    #       key_state: "Enabled", 
    #       key_usage: "ENCRYPT_DECRYPT", 
    #       multi_region: false, 
    #       origin: "AWS_KMS", 
    #     }, # Detailed information about the KMS key that this operation creates.
    #   }
    #
    # @example Example: To create an asymmetric RSA KMS key for encryption and decryption
    #
    #   # This example creates a KMS key that contains an asymmetric RSA key pair for encryption and decryption. The key spec and
    #   # key usage can't be changed after the key is created.
    #
    #   resp = client.create_key({
    #     key_spec: "RSA_4096", # Describes the type of key material in the KMS key.
    #     key_usage: "ENCRYPT_DECRYPT", # The cryptographic operations for which you can use the KMS key.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_metadata: {
    #       aws_account_id: "111122223333", 
    #       arn: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       creation_date: Time.parse("2021-04-05T14:04:55-07:00"), 
    #       customer_master_key_spec: "RSA_4096", 
    #       description: "", 
    #       enabled: true, 
    #       encryption_algorithms: [
    #         "RSAES_OAEP_SHA_1", 
    #         "RSAES_OAEP_SHA_256", 
    #       ], 
    #       key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       key_manager: "CUSTOMER", 
    #       key_spec: "RSA_4096", 
    #       key_state: "Enabled", 
    #       key_usage: "ENCRYPT_DECRYPT", 
    #       multi_region: false, 
    #       origin: "AWS_KMS", 
    #     }, # Detailed information about the KMS key that this operation creates.
    #   }
    #
    # @example Example: To create an asymmetric elliptic curve KMS key for signing and verification
    #
    #   # This example creates a KMS key that contains an asymmetric elliptic curve (ECC) key pair for signing and verification.
    #   # The key spec and key usage can't be changed after the key is created.
    #
    #   resp = client.create_key({
    #     key_spec: "ECC_NIST_P521", # Describes the type of key material in the KMS key.
    #     key_usage: "SIGN_VERIFY", # The cryptographic operations for which you can use the KMS key.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_metadata: {
    #       aws_account_id: "111122223333", 
    #       arn: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       creation_date: Time.parse("2019-12-02T07:48:55-07:00"), 
    #       customer_master_key_spec: "ECC_NIST_P521", 
    #       description: "", 
    #       enabled: true, 
    #       key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       key_manager: "CUSTOMER", 
    #       key_spec: "ECC_NIST_P521", 
    #       key_state: "Enabled", 
    #       key_usage: "SIGN_VERIFY", 
    #       multi_region: false, 
    #       origin: "AWS_KMS", 
    #       signing_algorithms: [
    #         "ECDSA_SHA_512", 
    #       ], 
    #     }, # Detailed information about the KMS key that this operation creates.
    #   }
    #
    # @example Example: To create an HMAC KMS key
    #
    #   # This example creates a 384-bit symmetric HMAC KMS key. The GENERATE_VERIFY_MAC key usage value is required even though
    #   # it's the only valid value for HMAC KMS keys. The key spec and key usage can't be changed after the key is created.
    #
    #   resp = client.create_key({
    #     key_spec: "HMAC_384", # Describes the type of key material in the KMS key.
    #     key_usage: "GENERATE_VERIFY_MAC", # The cryptographic operations for which you can use the KMS key.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_metadata: {
    #       aws_account_id: "111122223333", 
    #       arn: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       creation_date: Time.parse("2022-04-05T14:04:55-07:00"), 
    #       customer_master_key_spec: "HMAC_384", 
    #       description: "", 
    #       enabled: true, 
    #       key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       key_manager: "CUSTOMER", 
    #       key_spec: "HMAC_384", 
    #       key_state: "Enabled", 
    #       key_usage: "GENERATE_VERIFY_MAC", 
    #       mac_algorithms: [
    #         "HMAC_SHA_384", 
    #       ], 
    #       multi_region: false, 
    #       origin: "AWS_KMS", 
    #     }, # Detailed information about the KMS key that this operation creates.
    #   }
    #
    # @example Example: To create an asymmetric ML-DSA KMS key for signing and verification
    #
    #   # This example creates a module-lattice digital signature algorithm (ML-DSA) key for signing and verification. The
    #   # key-usage parameter is required even though SIGN_VERIFY is the only valid value for ML-DSA keys.
    #
    #   resp = client.create_key({
    #     key_spec: "ML_DSA_65", # Describes the type of key material in the KMS key.
    #     key_usage: "SIGN_VERIFY", # The cryptographic operations for which you can use the KMS key.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_metadata: {
    #       aws_account_id: "111122223333", 
    #       arn: "arn:aws:kms:us-east-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       creation_date: Time.parse(1748371316.734), 
    #       customer_master_key_spec: "ML_DSA_65", 
    #       description: "", 
    #       enabled: true, 
    #       key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       key_manager: "CUSTOMER", 
    #       key_spec: "ML_DSA_65", 
    #       key_state: "Enabled", 
    #       key_usage: "SIGN_VERIFY", 
    #       multi_region: false, 
    #       origin: "AWS_KMS", 
    #       signing_algorithms: [
    #         "ML_DSA_SHAKE_256", 
    #       ], 
    #     }, # Detailed information about the KMS key that this operation creates.
    #   }
    #
    # @example Example: To create a multi-Region primary KMS key
    #
    #   # This example creates a multi-Region primary symmetric encryption key. Because the default values for all parameters
    #   # create a symmetric encryption key, only the MultiRegion parameter is required for this KMS key.
    #
    #   resp = client.create_key({
    #     multi_region: true, # Indicates whether the KMS key is a multi-Region (True) or regional (False) key.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_metadata: {
    #       aws_account_id: "111122223333", 
    #       arn: "arn:aws:kms:us-west-2:111122223333:key/mrk-1234abcd12ab34cd56ef12345678990ab", 
    #       creation_date: Time.parse("2021-09-02T016:15:21-09:00"), 
    #       current_key_material_id: "0b7fd7ddbac6eef27907413567cad8c810e2883dc8a7534067a82ee1142fc1e6", 
    #       customer_master_key_spec: "SYMMETRIC_DEFAULT", 
    #       description: "", 
    #       enabled: true, 
    #       encryption_algorithms: [
    #         "SYMMETRIC_DEFAULT", 
    #       ], 
    #       key_id: "mrk-1234abcd12ab34cd56ef12345678990ab", 
    #       key_manager: "CUSTOMER", 
    #       key_spec: "SYMMETRIC_DEFAULT", 
    #       key_state: "Enabled", 
    #       key_usage: "ENCRYPT_DECRYPT", 
    #       multi_region: true, 
    #       multi_region_configuration: {
    #         multi_region_key_type: "PRIMARY", 
    #         primary_key: {
    #           arn: "arn:aws:kms:us-west-2:111122223333:key/mrk-1234abcd12ab34cd56ef12345678990ab", 
    #           region: "us-west-2", 
    #         }, 
    #         replica_keys: [
    #         ], 
    #       }, 
    #       origin: "AWS_KMS", 
    #     }, # Detailed information about the KMS key that this operation creates.
    #   }
    #
    # @example Example: To create a KMS key for imported key material
    #
    #   # This example creates a symmetric KMS key with no key material. When the operation is complete, you can import your own
    #   # key material into the KMS key. To create this KMS key, set the Origin parameter to EXTERNAL.
    #
    #   resp = client.create_key({
    #     origin: "EXTERNAL", # The source of the key material for the KMS key.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_metadata: {
    #       aws_account_id: "111122223333", 
    #       arn: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       creation_date: Time.parse("2019-12-02T07:48:55-07:00"), 
    #       customer_master_key_spec: "SYMMETRIC_DEFAULT", 
    #       description: "", 
    #       enabled: false, 
    #       encryption_algorithms: [
    #         "SYMMETRIC_DEFAULT", 
    #       ], 
    #       key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       key_manager: "CUSTOMER", 
    #       key_spec: "SYMMETRIC_DEFAULT", 
    #       key_state: "PendingImport", 
    #       key_usage: "ENCRYPT_DECRYPT", 
    #       multi_region: false, 
    #       origin: "EXTERNAL", 
    #     }, # Detailed information about the KMS key that this operation creates.
    #   }
    #
    # @example Example: To create a KMS key in an AWS CloudHSM key store
    #
    #   # This example creates a KMS key in the specified AWS CloudHSM key store. The operation creates the KMS key and its
    #   # metadata in AWS KMS and creates the key material in the AWS CloudHSM cluster associated with the custom key store. This
    #   # example requires the CustomKeyStoreId  and Origin parameters.
    #
    #   resp = client.create_key({
    #     custom_key_store_id: "cks-1234567890abcdef0", # Identifies the custom key store that hosts the KMS key.
    #     origin: "AWS_CLOUDHSM", # Indicates the source of the key material for the KMS key.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_metadata: {
    #       aws_account_id: "111122223333", 
    #       arn: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       cloud_hsm_cluster_id: "cluster-234abcdefABC", 
    #       creation_date: Time.parse("2019-12-02T07:48:55-07:00"), 
    #       custom_key_store_id: "cks-1234567890abcdef0", 
    #       customer_master_key_spec: "SYMMETRIC_DEFAULT", 
    #       description: "", 
    #       enabled: true, 
    #       encryption_algorithms: [
    #         "SYMMETRIC_DEFAULT", 
    #       ], 
    #       key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       key_manager: "CUSTOMER", 
    #       key_spec: "SYMMETRIC_DEFAULT", 
    #       key_state: "Enabled", 
    #       key_usage: "ENCRYPT_DECRYPT", 
    #       multi_region: false, 
    #       origin: "AWS_CLOUDHSM", 
    #     }, # Detailed information about the KMS key that this operation creates.
    #   }
    #
    # @example Example: To create a KMS key in an external key store
    #
    #   # This example creates a KMS key in the specified external key store. It uses the XksKeyId parameter to associate the KMS
    #   # key with an existing symmetric encryption key in your external key manager. This CustomKeyStoreId, Origin, and XksKeyId
    #   # parameters are required in this operation.
    #
    #   resp = client.create_key({
    #     custom_key_store_id: "cks-9876543210fedcba9", # Identifies the custom key store that hosts the KMS key.
    #     origin: "EXTERNAL_KEY_STORE", # Indicates the source of the key material for the KMS key.
    #     xks_key_id: "bb8562717f809024", # Identifies the encryption key in your external key manager that is associated with the KMS key
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_metadata: {
    #       aws_account_id: "111122223333", 
    #       arn: "arn:aws:kms:us-east-2:111122223333:key/0987dcba-09fe-87dc-65ba-ab0987654321", 
    #       creation_date: Time.parse("2022-02-02T07:48:55-07:00"), 
    #       custom_key_store_id: "cks-9876543210fedcba9", 
    #       customer_master_key_spec: "SYMMETRIC_DEFAULT", 
    #       description: "", 
    #       enabled: true, 
    #       encryption_algorithms: [
    #         "SYMMETRIC_DEFAULT", 
    #       ], 
    #       key_id: "0987dcba-09fe-87dc-65ba-ab0987654321", 
    #       key_manager: "CUSTOMER", 
    #       key_spec: "SYMMETRIC_DEFAULT", 
    #       key_state: "Enabled", 
    #       key_usage: "ENCRYPT_DECRYPT", 
    #       multi_region: false, 
    #       origin: "EXTERNAL_KEY_STORE", 
    #       xks_key_configuration: {
    #         id: "bb8562717f809024", 
    #       }, 
    #     }, # Detailed information about the KMS key that this operation creates.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.create_key({
    #     policy: "PolicyType",
    #     description: "DescriptionType",
    #     key_usage: "SIGN_VERIFY", # accepts SIGN_VERIFY, ENCRYPT_DECRYPT, GENERATE_VERIFY_MAC, KEY_AGREEMENT
    #     customer_master_key_spec: "RSA_2048", # accepts RSA_2048, RSA_3072, RSA_4096, ECC_NIST_P256, ECC_NIST_P384, ECC_NIST_P521, ECC_SECG_P256K1, SYMMETRIC_DEFAULT, HMAC_224, HMAC_256, HMAC_384, HMAC_512, SM2
    #     key_spec: "RSA_2048", # accepts RSA_2048, RSA_3072, RSA_4096, ECC_NIST_P256, ECC_NIST_P384, ECC_NIST_P521, ECC_SECG_P256K1, SYMMETRIC_DEFAULT, HMAC_224, HMAC_256, HMAC_384, HMAC_512, SM2, ML_DSA_44, ML_DSA_65, ML_DSA_87, ECC_NIST_EDWARDS25519
    #     origin: "AWS_KMS", # accepts AWS_KMS, EXTERNAL, AWS_CLOUDHSM, EXTERNAL_KEY_STORE
    #     custom_key_store_id: "CustomKeyStoreIdType",
    #     bypass_policy_lockout_safety_check: false,
    #     tags: [
    #       {
    #         tag_key: "TagKeyType", # required
    #         tag_value: "TagValueType", # required
    #       },
    #     ],
    #     multi_region: false,
    #     xks_key_id: "XksKeyIdType",
    #   })
    #
    # @example Response structure
    #
    #   resp.key_metadata.aws_account_id #=> String
    #   resp.key_metadata.key_id #=> String
    #   resp.key_metadata.arn #=> String
    #   resp.key_metadata.creation_date #=> Time
    #   resp.key_metadata.enabled #=> Boolean
    #   resp.key_metadata.description #=> String
    #   resp.key_metadata.key_usage #=> String, one of "SIGN_VERIFY", "ENCRYPT_DECRYPT", "GENERATE_VERIFY_MAC", "KEY_AGREEMENT"
    #   resp.key_metadata.key_state #=> String, one of "Creating", "Enabled", "Disabled", "PendingDeletion", "PendingImport", "PendingReplicaDeletion", "Unavailable", "Updating"
    #   resp.key_metadata.deletion_date #=> Time
    #   resp.key_metadata.valid_to #=> Time
    #   resp.key_metadata.origin #=> String, one of "AWS_KMS", "EXTERNAL", "AWS_CLOUDHSM", "EXTERNAL_KEY_STORE"
    #   resp.key_metadata.custom_key_store_id #=> String
    #   resp.key_metadata.cloud_hsm_cluster_id #=> String
    #   resp.key_metadata.expiration_model #=> String, one of "KEY_MATERIAL_EXPIRES", "KEY_MATERIAL_DOES_NOT_EXPIRE"
    #   resp.key_metadata.key_manager #=> String, one of "AWS", "CUSTOMER"
    #   resp.key_metadata.customer_master_key_spec #=> String, one of "RSA_2048", "RSA_3072", "RSA_4096", "ECC_NIST_P256", "ECC_NIST_P384", "ECC_NIST_P521", "ECC_SECG_P256K1", "SYMMETRIC_DEFAULT", "HMAC_224", "HMAC_256", "HMAC_384", "HMAC_512", "SM2"
    #   resp.key_metadata.key_spec #=> String, one of "RSA_2048", "RSA_3072", "RSA_4096", "ECC_NIST_P256", "ECC_NIST_P384", "ECC_NIST_P521", "ECC_SECG_P256K1", "SYMMETRIC_DEFAULT", "HMAC_224", "HMAC_256", "HMAC_384", "HMAC_512", "SM2", "ML_DSA_44", "ML_DSA_65", "ML_DSA_87", "ECC_NIST_EDWARDS25519"
    #   resp.key_metadata.encryption_algorithms #=> Array
    #   resp.key_metadata.encryption_algorithms[0] #=> String, one of "SYMMETRIC_DEFAULT", "RSAES_OAEP_SHA_1", "RSAES_OAEP_SHA_256", "SM2PKE"
    #   resp.key_metadata.signing_algorithms #=> Array
    #   resp.key_metadata.signing_algorithms[0] #=> String, one of "RSASSA_PSS_SHA_256", "RSASSA_PSS_SHA_384", "RSASSA_PSS_SHA_512", "RSASSA_PKCS1_V1_5_SHA_256", "RSASSA_PKCS1_V1_5_SHA_384", "RSASSA_PKCS1_V1_5_SHA_512", "ECDSA_SHA_256", "ECDSA_SHA_384", "ECDSA_SHA_512", "SM2DSA", "ML_DSA_SHAKE_256", "ED25519_SHA_512", "ED25519_PH_SHA_512"
    #   resp.key_metadata.key_agreement_algorithms #=> Array
    #   resp.key_metadata.key_agreement_algorithms[0] #=> String, one of "ECDH"
    #   resp.key_metadata.multi_region #=> Boolean
    #   resp.key_metadata.multi_region_configuration.multi_region_key_type #=> String, one of "PRIMARY", "REPLICA"
    #   resp.key_metadata.multi_region_configuration.primary_key.arn #=> String
    #   resp.key_metadata.multi_region_configuration.primary_key.region #=> String
    #   resp.key_metadata.multi_region_configuration.replica_keys #=> Array
    #   resp.key_metadata.multi_region_configuration.replica_keys[0].arn #=> String
    #   resp.key_metadata.multi_region_configuration.replica_keys[0].region #=> String
    #   resp.key_metadata.pending_deletion_window_in_days #=> Integer
    #   resp.key_metadata.mac_algorithms #=> Array
    #   resp.key_metadata.mac_algorithms[0] #=> String, one of "HMAC_SHA_224", "HMAC_SHA_256", "HMAC_SHA_384", "HMAC_SHA_512"
    #   resp.key_metadata.xks_key_configuration.id #=> String
    #   resp.key_metadata.current_key_material_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/CreateKey AWS API Documentation
    #
    # @overload create_key(params = {})
    # @param [Hash] params ({})
    def create_key(params = {}, options = {})
      req = build_request(:create_key, params)
      req.send_request(options)
    end

    # Decrypts ciphertext that was encrypted by a KMS key using any of the
    # following operations:
    #
    # * Encrypt
    #
    # * GenerateDataKey
    #
    # * GenerateDataKeyPair
    #
    # * GenerateDataKeyWithoutPlaintext
    #
    # * GenerateDataKeyPairWithoutPlaintext
    #
    # You can use this operation to decrypt ciphertext that was encrypted
    # under a symmetric encryption KMS key or an asymmetric encryption KMS
    # key. When the KMS key is asymmetric, you must specify the KMS key and
    # the encryption algorithm that was used to encrypt the ciphertext. For
    # information about asymmetric KMS keys, see [Asymmetric KMS keys][1] in
    # the *Key Management Service Developer Guide*.
    #
    # The `Decrypt` operation also decrypts ciphertext that was encrypted
    # outside of KMS by the public key in an KMS asymmetric KMS key.
    # However, it cannot decrypt symmetric ciphertext produced by other
    # libraries, such as the [Amazon Web Services Encryption SDK][2] or
    # [Amazon S3 client-side encryption][3]. These libraries return a
    # ciphertext format that is incompatible with KMS.
    #
    # If the ciphertext was encrypted under a symmetric encryption KMS key,
    # the `KeyId` parameter is optional. KMS can get this information from
    # metadata that it adds to the symmetric ciphertext blob. This feature
    # adds durability to your implementation by ensuring that authorized
    # users can decrypt ciphertext decades after it was encrypted, even if
    # they've lost track of the key ID. However, specifying the KMS key is
    # always recommended as a best practice. When you use the `KeyId`
    # parameter to specify a KMS key, KMS only uses the KMS key you specify.
    # If the ciphertext was encrypted under a different KMS key, the
    # `Decrypt` operation fails. This practice ensures that you use the KMS
    # key that you intend.
    #
    # Whenever possible, use key policies to give users permission to call
    # the `Decrypt` operation on a particular KMS key, instead of using IAM
    # policies. Otherwise, you might create an IAM policy that gives the
    # user `Decrypt` permission on all KMS keys. This user could decrypt
    # ciphertext that was encrypted by KMS keys in other accounts if the key
    # policy for the cross-account KMS key permits it. If you must use an
    # IAM policy for `Decrypt` permissions, limit the user to particular KMS
    # keys or particular trusted accounts. For details, see [Best practices
    # for IAM policies][4] in the *Key Management Service Developer Guide*.
    #
    # `Decrypt` also supports [Amazon Web Services Nitro Enclaves][5] and
    # NitroTPM, which provide attested environments in Amazon EC2. To call
    # `Decrypt` for a Nitro enclave or NitroTPM, use the [Amazon Web
    # Services Nitro Enclaves SDK][6] or any Amazon Web Services SDK. Use
    # the `Recipient` parameter to provide the attestation document for the
    # attested environment. Instead of the plaintext data, the response
    # includes the plaintext data encrypted with the public key from the
    # attestation document (`CiphertextForRecipient`). For information about
    # the interaction between KMS and Amazon Web Services Nitro Enclaves or
    # Amazon Web Services NitroTPM, see [Cryptographic attestation support
    # in KMS][7] in the *Key Management Service Developer Guide*.
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][8] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: Yes. If you use the `KeyId` parameter to
    # identify a KMS key in a different Amazon Web Services account, specify
    # the key ARN or the alias ARN of the KMS key.
    #
    # **Required permissions**: [kms:Decrypt][9] (key policy)
    #
    # **Related operations:**
    #
    # * Encrypt
    #
    # * GenerateDataKey
    #
    # * GenerateDataKeyPair
    #
    # * ReEncrypt
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][10].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html
    # [2]: https://docs.aws.amazon.com/encryption-sdk/latest/developer-guide/
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingClientSideEncryption.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/iam-policies.html#iam-policies-best-practices
    # [5]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/nitro-enclave.html
    # [6]: https://docs.aws.amazon.com/enclaves/latest/user/developing-applications.html#sdk
    # [7]: https://docs.aws.amazon.com/kms/latest/developerguide/cryptographic-attestation.html
    # [8]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [9]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [10]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [String, StringIO, File] :ciphertext_blob
    #   Ciphertext to be decrypted. The blob includes metadata.
    #
    #   This parameter is required in all cases except when `DryRun` is `true`
    #   and `DryRunModifiers` is set to `IGNORE_CIPHERTEXT`.
    #
    # @option params [Hash<String,String>] :encryption_context
    #   Specifies the encryption context to use when decrypting the data. An
    #   encryption context is valid only for [cryptographic operations][1]
    #   with a symmetric encryption KMS key. The standard asymmetric
    #   encryption algorithms and HMAC algorithms that KMS uses do not support
    #   an encryption context.
    #
    #   An *encryption context* is a collection of non-secret key-value pairs
    #   that represent additional authenticated data. When you use an
    #   encryption context to encrypt data, you must specify the same (an
    #   exact case-sensitive match) encryption context to decrypt the data. An
    #   encryption context is supported only on operations with symmetric
    #   encryption KMS keys. On operations with symmetric encryption KMS keys,
    #   an encryption context is optional, but it is strongly recommended.
    #
    #   For more information, see [Encryption context][2] in the *Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-cryptography.html#cryptographic-operations
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/encrypt_context.html
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   Use a grant token when your permission to call this operation comes
    #   from a new grant that has not yet achieved *eventual consistency*. For
    #   more information, see [Grant token][1] and [Using a grant token][2] in
    #   the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html#grant_token
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/using-grant-token.html
    #
    # @option params [String] :key_id
    #   Specifies the KMS key that KMS uses to decrypt the ciphertext.
    #
    #   Enter a key ID of the KMS key that was used to encrypt the ciphertext.
    #   If you identify a different KMS key, the `Decrypt` operation throws an
    #   `IncorrectKeyException`.
    #
    #   This parameter is required only when the ciphertext was encrypted
    #   under an asymmetric KMS key or when `DryRun` is `true` and
    #   `DryRunModifiers` is set to `IGNORE_CIPHERTEXT`. If you used a
    #   symmetric encryption KMS key, KMS can get the KMS key from metadata
    #   that it adds to the symmetric ciphertext blob. However, it is always
    #   recommended as a best practice. This practice ensures that you use the
    #   KMS key that you intend.
    #
    #   To specify a KMS key, use its key ID, key ARN, alias name, or alias
    #   ARN. When using an alias name, prefix it with `"alias/"`. To specify a
    #   KMS key in a different Amazon Web Services account, you must use the
    #   key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey. To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [String] :encryption_algorithm
    #   Specifies the encryption algorithm that will be used to decrypt the
    #   ciphertext. Specify the same algorithm that was used to encrypt the
    #   data. If you specify a different algorithm, the `Decrypt` operation
    #   fails.
    #
    #   This parameter is required only when the ciphertext was encrypted
    #   under an asymmetric KMS key. The default value, `SYMMETRIC_DEFAULT`,
    #   represents the only supported algorithm that is valid for symmetric
    #   encryption KMS keys.
    #
    # @option params [Types::RecipientInfo] :recipient
    #   A signed [attestation document][1] from an Amazon Web Services Nitro
    #   enclave or NitroTPM, and the encryption algorithm to use with the
    #   public key in the attestation document. The only valid encryption
    #   algorithm is `RSAES_OAEP_SHA_256`.
    #
    #   This parameter supports the [Amazon Web Services Nitro Enclaves
    #   SDK][2] or any Amazon Web Services SDK for Amazon Web Services Nitro
    #   Enclaves. It supports any Amazon Web Services SDK for Amazon Web
    #   Services NitroTPM.
    #
    #   When you use this parameter, instead of returning the plaintext data,
    #   KMS encrypts the plaintext data with the public key in the attestation
    #   document, and returns the resulting ciphertext in the
    #   `CiphertextForRecipient` field in the response. This ciphertext can be
    #   decrypted only with the private key in the attested environment. The
    #   `Plaintext` field in the response is null or empty.
    #
    #   For information about the interaction between KMS and Amazon Web
    #   Services Nitro Enclaves or Amazon Web Services NitroTPM, see
    #   [Cryptographic attestation support in KMS][3] in the *Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/enclaves/latest/user/nitro-enclave-concepts.html#term-attestdoc
    #   [2]: https://docs.aws.amazon.com/enclaves/latest/user/developing-applications.html#sdk
    #   [3]: https://docs.aws.amazon.com/kms/latest/developerguide/cryptographic-attestation.html
    #
    # @option params [Boolean] :dry_run
    #   Checks if your request will succeed. `DryRun` is an optional
    #   parameter.
    #
    #   To learn more about how to use this parameter, see [Testing your
    #   permissions][1] in the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/testing-permissions.html
    #
    # @option params [Array<String>] :dry_run_modifiers
    #   Specifies the modifiers to apply to the dry run operation.
    #   `DryRunModifiers` is an optional parameter that only applies when
    #   `DryRun` is set to `true`.
    #
    #   When set to `IGNORE_CIPHERTEXT`, KMS performs only authorization
    #   validation without ciphertext validation. This allows you to test
    #   permissions without requiring a valid ciphertext blob.
    #
    #   To learn more about how to use this parameter, see [Testing your
    #   permissions][1] in the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/testing-permissions.html
    #
    # @return [Types::DecryptResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::DecryptResponse#key_id #key_id} => String
    #   * {Types::DecryptResponse#plaintext #plaintext} => String
    #   * {Types::DecryptResponse#encryption_algorithm #encryption_algorithm} => String
    #   * {Types::DecryptResponse#ciphertext_for_recipient #ciphertext_for_recipient} => String
    #   * {Types::DecryptResponse#key_material_id #key_material_id} => String
    #
    #
    # @example Example: To decrypt data with a symmetric encryption KMS key
    #
    #   # The following example decrypts data that was encrypted with a symmetric encryption KMS key. The KeyId is not required
    #   # when decrypting with a symmetric encryption key, but it is a best practice.
    #
    #   resp = client.decrypt({
    #     ciphertext_blob: "<binary data>", # The encrypted data (ciphertext).
    #     key_id: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # A key identifier for the KMS key to use to decrypt the data.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     encryption_algorithm: "SYMMETRIC_DEFAULT", # The encryption algorithm that was used to decrypt the ciphertext. SYMMETRIC_DEFAULT is the only valid value for symmetric encryption in AWS KMS.
    #     key_id: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The Amazon Resource Name (ARN) of the KMS key that was used to decrypt the data.
    #     key_material_id: "0b7fd7ddbac6eef27907413567cad8c810e2883dc8a7534067a82ee1142fc1e6", # The identifier of the key material used to decrypt the ciphertext.
    #     plaintext: "<binary data>", # The decrypted (plaintext) data.
    #   }
    #
    # @example Example: To decrypt data with an asymmetric encryption KMS key
    #
    #   # The following example decrypts data that was encrypted with an asymmetric encryption KMS key. When the KMS encryption
    #   # key is asymmetric, you must specify the KMS key ID and the encryption algorithm that was used to encrypt the data.
    #
    #   resp = client.decrypt({
    #     ciphertext_blob: "<binary data>", # The encrypted data (ciphertext).
    #     encryption_algorithm: "RSAES_OAEP_SHA_256", # The encryption algorithm that was used to encrypt the data. This parameter is required to decrypt with an asymmetric KMS key.
    #     key_id: "0987dcba-09fe-87dc-65ba-ab0987654321", # A key identifier for the KMS key to use to decrypt the data. This parameter is required to decrypt with an asymmetric KMS key.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     encryption_algorithm: "RSAES_OAEP_SHA_256", # The encryption algorithm that was used to decrypt the ciphertext.
    #     key_id: "arn:aws:kms:us-west-2:111122223333:key/0987dcba-09fe-87dc-65ba-ab0987654321", # The Amazon Resource Name (ARN) of the KMS key that was used to decrypt the data.
    #     plaintext: "<binary data>", # The decrypted (plaintext) data.
    #   }
    #
    # @example Example: To decrypt data for a Nitro enclave or NitroTPM
    #
    #   # The following Decrypt example includes the Recipient parameter with a signed attestation document from an AWS Nitro
    #   # enclave or NitroTPM. Instead of returning the decrypted data in plaintext (Plaintext), the operation returns the
    #   # decrypted data encrypted by the public key from the attestation document (CiphertextForRecipient).
    #
    #   resp = client.decrypt({
    #     ciphertext_blob: "<binary data>", # The encrypted data. This ciphertext was encrypted with the KMS key
    #     key_id: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The KMS key to use to decrypt the ciphertext
    #     recipient: {
    #       attestation_document: "<attestation document>", 
    #       key_encryption_algorithm: "RSAES_OAEP_SHA_256", 
    #     }, # Specifies the attestation document from the Nitro enclave or NitroTPM and the encryption algorithm to use with the public key from the attestation document
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     ciphertext_for_recipient: "<binary data>", # The decrypted CiphertextBlob encrypted with the public key from the attestation document
    #     key_id: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The KMS key that was used to decrypt the encrypted data (CiphertextBlob)
    #     plaintext: "", # This field is null or empty
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.decrypt({
    #     ciphertext_blob: "data",
    #     encryption_context: {
    #       "EncryptionContextKey" => "EncryptionContextValue",
    #     },
    #     grant_tokens: ["GrantTokenType"],
    #     key_id: "KeyIdType",
    #     encryption_algorithm: "SYMMETRIC_DEFAULT", # accepts SYMMETRIC_DEFAULT, RSAES_OAEP_SHA_1, RSAES_OAEP_SHA_256, SM2PKE
    #     recipient: {
    #       key_encryption_algorithm: "RSAES_OAEP_SHA_256", # accepts RSAES_OAEP_SHA_256
    #       attestation_document: "data",
    #     },
    #     dry_run: false,
    #     dry_run_modifiers: ["IGNORE_CIPHERTEXT"], # accepts IGNORE_CIPHERTEXT
    #   })
    #
    # @example Response structure
    #
    #   resp.key_id #=> String
    #   resp.plaintext #=> String
    #   resp.encryption_algorithm #=> String, one of "SYMMETRIC_DEFAULT", "RSAES_OAEP_SHA_1", "RSAES_OAEP_SHA_256", "SM2PKE"
    #   resp.ciphertext_for_recipient #=> String
    #   resp.key_material_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/Decrypt AWS API Documentation
    #
    # @overload decrypt(params = {})
    # @param [Hash] params ({})
    def decrypt(params = {}, options = {})
      req = build_request(:decrypt, params)
      req.send_request(options)
    end

    # Deletes the specified alias.
    #
    # <note markdown="1"> Adding, deleting, or updating an alias can allow or deny permission to
    # the KMS key. For details, see [ABAC for KMS][1] in the *Key Management
    # Service Developer Guide*.
    #
    #  </note>
    #
    # Because an alias is not a property of a KMS key, you can delete and
    # change the aliases of a KMS key without affecting the KMS key. Also,
    # aliases do not appear in the response from the DescribeKey operation.
    # To get the aliases of all KMS keys, use the ListAliases operation.
    #
    # Each KMS key can have multiple aliases. To change the alias of a KMS
    # key, use DeleteAlias to delete the current alias and CreateAlias to
    # create a new alias. To associate an existing alias with a different
    # KMS key, call UpdateAlias.
    #
    # **Cross-account use**: No. You cannot perform this operation on an
    # alias in a different Amazon Web Services account.
    #
    # **Required permissions**
    #
    # * [kms:DeleteAlias][2] on the alias (IAM policy).
    #
    # * [kms:DeleteAlias][2] on the KMS key (key policy).
    #
    # For details, see [Controlling access to aliases][3] in the *Key
    # Management Service Developer Guide*.
    #
    # **Related operations:**
    #
    # * CreateAlias
    #
    # * ListAliases
    #
    # * UpdateAlias
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][4].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/abac.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-alias.html#alias-access
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :alias_name
    #   The alias to be deleted. The alias name must begin with `alias/`
    #   followed by the alias name, such as `alias/ExampleAlias`.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To delete an alias
    #
    #   # The following example deletes the specified alias.
    #
    #   resp = client.delete_alias({
    #     alias_name: "alias/ExampleAlias", # The alias to delete.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_alias({
    #     alias_name: "AliasNameType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DeleteAlias AWS API Documentation
    #
    # @overload delete_alias(params = {})
    # @param [Hash] params ({})
    def delete_alias(params = {}, options = {})
      req = build_request(:delete_alias, params)
      req.send_request(options)
    end

    # Deletes a [custom key store][1]. This operation does not affect any
    # backing elements of the custom key store. It does not delete the
    # CloudHSM cluster that is associated with an CloudHSM key store, or
    # affect any users or keys in the cluster. For an external key store, it
    # does not affect the external key store proxy, external key manager, or
    # any external keys.
    #
    # This operation is part of the custom key stores feature in KMS, which
    # combines the convenience and extensive integration of KMS with the
    # isolation and control of a key store that you own and manage.
    #
    # The custom key store that you delete cannot contain any [KMS keys][2].
    # Before deleting the key store, verify that you will never need to use
    # any of the KMS keys in the key store for any [cryptographic
    # operations][3]. Then, use ScheduleKeyDeletion to delete the KMS keys
    # from the key store. After the required waiting period expires and all
    # KMS keys are deleted from the custom key store, use
    # DisconnectCustomKeyStore to disconnect the key store from KMS. Then,
    # you can delete the custom key store.
    #
    # For keys in an CloudHSM key store, the `ScheduleKeyDeletion` operation
    # makes a best effort to delete the key material from the associated
    # cluster. However, you might need to manually [delete the orphaned key
    # material][4] from the cluster and its backups. KMS never creates,
    # manages, or deletes cryptographic keys in the external key manager
    # associated with an external key store. You must manage them using your
    # external key manager tools.
    #
    # Instead of deleting the custom key store, consider using the
    # DisconnectCustomKeyStore operation to disconnect the custom key store
    # from its backing key store. While the key store is disconnected, you
    # cannot create or use the KMS keys in the key store. But, you do not
    # need to delete KMS keys and you can reconnect a disconnected custom
    # key store at any time.
    #
    # If the operation succeeds, it returns a JSON object with no
    # properties.
    #
    # **Cross-account use**: No. You cannot perform this operation on a
    # custom key store in a different Amazon Web Services account.
    #
    # **Required permissions**: [kms:DeleteCustomKeyStore][5] (IAM policy)
    #
    # **Related operations:**
    #
    # * ConnectCustomKeyStore
    #
    # * CreateCustomKeyStore
    #
    # * DescribeCustomKeyStores
    #
    # * DisconnectCustomKeyStore
    #
    # * UpdateCustomKeyStore
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][6].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-store-overview.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#kms_keys
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-cryptography.html#cryptographic-operations
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [6]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :custom_key_store_id
    #   Enter the ID of the custom key store you want to delete. To find the
    #   ID of a custom key store, use the DescribeCustomKeyStores operation.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To delete a custom key store from AWS KMS
    #
    #   # This example deletes a custom key store from AWS KMS. This operation does not affect the backing key store, such as a
    #   # CloudHSM cluster, external key store proxy, or your external key manager. This operation doesn't return any data. To
    #   # verify that the operation was successful, use the DescribeCustomKeyStores operation.
    #
    #   resp = client.delete_custom_key_store({
    #     custom_key_store_id: "cks-1234567890abcdef0", # The ID of the custom key store to be deleted.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_custom_key_store({
    #     custom_key_store_id: "CustomKeyStoreIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DeleteCustomKeyStore AWS API Documentation
    #
    # @overload delete_custom_key_store(params = {})
    # @param [Hash] params ({})
    def delete_custom_key_store(params = {}, options = {})
      req = build_request(:delete_custom_key_store, params)
      req.send_request(options)
    end

    # Deletes key material that was previously imported. This operation
    # makes the specified KMS key temporarily unusable. To restore the
    # usability of the KMS key, reimport the same key material. For more
    # information about importing key material into KMS, see [Importing Key
    # Material][1] in the *Key Management Service Developer Guide*.
    #
    # When the specified KMS key is in the `PendingDeletion` state, this
    # operation does not change the KMS key's state. Otherwise, it changes
    # the KMS key's state to `PendingImport`.
    #
    # **Considerations for multi-Region symmetric encryption keys**
    #
    # * When you delete the key material of a primary Region key that is in
    #   `PENDING_ROTATION` or
    #   `PENDING_MULTI_REGION_IMPORT_AND_ROTATION`state, you'll also be
    #   deleting the key materials for the replica Region keys.
    #
    # * If you delete any key material of a replica Region key, the primary
    #   Region key and other replica Region keys remain unchanged.
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][2] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: No. You cannot perform this operation on a KMS
    # key in a different Amazon Web Services account.
    #
    # **Required permissions**: [kms:DeleteImportedKeyMaterial][3] (key
    # policy)
    #
    # **Related operations:**
    #
    # * GetParametersForImport
    #
    # * ListKeyRotations
    #
    # * ImportKeyMaterial
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][4].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Identifies the KMS key from which you are deleting imported key
    #   material. The `Origin` of the KMS key must be `EXTERNAL`.
    #
    #   Specify the key ID or key ARN of the KMS key.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    # @option params [String] :key_material_id
    #   Identifies the imported key material you are deleting.
    #
    #   If no KeyMaterialId is specified, KMS deletes the current key
    #   material.
    #
    #   To get the list of key material IDs associated with a KMS key, use
    #   ListKeyRotations.
    #
    # @return [Types::DeleteImportedKeyMaterialResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::DeleteImportedKeyMaterialResponse#key_id #key_id} => String
    #   * {Types::DeleteImportedKeyMaterialResponse#key_material_id #key_material_id} => String
    #
    #
    # @example Example: To delete imported key material
    #
    #   # The following example deletes the imported key material from the specified KMS key.
    #
    #   resp = client.delete_imported_key_material({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key whose imported key material you are deleting. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #     key_material_id: "0b7fd7ddbac6eef27907413567cad8c810e2883dc8a7534067a82ee1142fc1e6", # Identifies the deleted key material.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_imported_key_material({
    #     key_id: "KeyIdType", # required
    #     key_material_id: "BackingKeyIdType",
    #   })
    #
    # @example Response structure
    #
    #   resp.key_id #=> String
    #   resp.key_material_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DeleteImportedKeyMaterial AWS API Documentation
    #
    # @overload delete_imported_key_material(params = {})
    # @param [Hash] params ({})
    def delete_imported_key_material(params = {}, options = {})
      req = build_request(:delete_imported_key_material, params)
      req.send_request(options)
    end

    # Derives a shared secret using a key agreement algorithm.
    #
    # <note markdown="1"> You must use an asymmetric NIST-standard elliptic curve (ECC) or SM2
    # (China Regions only) KMS key pair with a `KeyUsage` value of
    # `KEY_AGREEMENT` to call DeriveSharedSecret.
    #
    #  </note>
    #
    # DeriveSharedSecret uses the [Elliptic Curve Cryptography Cofactor
    # Diffie-Hellman Primitive][1] (ECDH) to establish a key agreement
    # between two peers by deriving a shared secret from their elliptic
    # curve public-private key pairs. You can use the raw shared secret that
    # DeriveSharedSecret returns to derive a symmetric key that can encrypt
    # and decrypt data that is sent between the two peers, or that can
    # generate and verify HMACs. KMS recommends that you follow [NIST
    # recommendations for key derivation][2] when using the raw shared
    # secret to derive a symmetric key.
    #
    # The following workflow demonstrates how to establish key agreement
    # over an insecure communication channel using DeriveSharedSecret.
    #
    # 1.  **Alice** calls CreateKey to create an asymmetric KMS key pair
    #     with a `KeyUsage` value of `KEY_AGREEMENT`.
    #
    #     The asymmetric KMS key must use a NIST-standard elliptic curve
    #     (ECC) or SM2 (China Regions only) key spec.
    #
    # 2.  **Bob** creates an elliptic curve key pair.
    #
    #     Bob can call CreateKey to create an asymmetric KMS key pair or
    #     generate a key pair outside of KMS. Bob's key pair must use the
    #     same NIST-standard elliptic curve (ECC) or SM2 (China Regions ony)
    #     curve as Alice.
    #
    # 3.  Alice and Bob **exchange their public keys** through an insecure
    #     communication channel (like the internet).
    #
    #     Use GetPublicKey to download the public key of your asymmetric KMS
    #     key pair.
    #
    #     <note markdown="1"> KMS strongly recommends verifying that the public key you receive
    #     came from the expected party before using it to derive a shared
    #     secret.
    #
    #      </note>
    #
    # 4.  **Alice** calls DeriveSharedSecret.
    #
    #     KMS uses the private key from the KMS key pair generated in **Step
    #     1**, Bob's public key, and the Elliptic Curve Cryptography
    #     Cofactor Diffie-Hellman Primitive to derive the shared secret. The
    #     private key in your KMS key pair never leaves KMS unencrypted.
    #     DeriveSharedSecret returns the raw shared secret.
    #
    # 5.  **Bob** uses the Elliptic Curve Cryptography Cofactor
    #     Diffie-Hellman Primitive to calculate the same raw secret using
    #     his private key and Alice's public key.
    #
    # To derive a shared secret you must provide a key agreement algorithm,
    # the private key of the caller's asymmetric NIST-standard elliptic
    # curve or SM2 (China Regions only) KMS key pair, and the public key
    # from your peer's NIST-standard elliptic curve or SM2 (China Regions
    # only) key pair. The public key can be from another asymmetric KMS key
    # pair or from a key pair generated outside of KMS, but both key pairs
    # must be on the same elliptic curve.
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][3] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: Yes. To perform this operation with a KMS key
    # in a different Amazon Web Services account, specify the key ARN or
    # alias ARN in the value of the `KeyId` parameter.
    #
    # **Required permissions**: [kms:DeriveSharedSecret][4] (key policy)
    #
    # **Related operations:**
    #
    # * CreateKey
    #
    # * GetPublicKey
    #
    # * DescribeKey
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][5].
    #
    #
    #
    # [1]: https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-56Ar3.pdf#page=60
    # [2]: https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-56Cr2.pdf
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Identifies an asymmetric NIST-standard ECC or SM2 (China Regions only)
    #   KMS key. KMS uses the private key in the specified key pair to derive
    #   the shared secret. The key usage of the KMS key must be
    #   `KEY_AGREEMENT`. To find the `KeyUsage` of a KMS key, use the
    #   DescribeKey operation.
    #
    #   To specify a KMS key, use its key ID, key ARN, alias name, or alias
    #   ARN. When using an alias name, prefix it with `"alias/"`. To specify a
    #   KMS key in a different Amazon Web Services account, you must use the
    #   key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey. To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [required, String] :key_agreement_algorithm
    #   Specifies the key agreement algorithm used to derive the shared
    #   secret. The only valid value is `ECDH`.
    #
    # @option params [required, String, StringIO, File] :public_key
    #   Specifies the public key in your peer's NIST-standard elliptic curve
    #   (ECC) or SM2 (China Regions only) key pair.
    #
    #   The public key must be a DER-encoded X.509 public key, also known as
    #   `SubjectPublicKeyInfo` (SPKI), as defined in [RFC 5280][1].
    #
    #   GetPublicKey returns the public key of an asymmetric KMS key pair in
    #   the required DER-encoded format.
    #
    #   <note markdown="1"> If you use [Amazon Web Services CLI version 1][2], you must provide
    #   the DER-encoded X.509 public key in a file. Otherwise, the Amazon Web
    #   Services CLI Base64-encodes the public key a second time, resulting in
    #   a `ValidationException`.
    #
    #    </note>
    #
    #   You can specify the public key as binary data in a file using fileb
    #   (`fileb://<path-to-file>`) or in-line using a Base64 encoded string.
    #
    #
    #
    #   [1]: https://tools.ietf.org/html/rfc5280
    #   [2]: https://docs.aws.amazon.com/cli/v1/userguide/cli-chap-welcome.html
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   Use a grant token when your permission to call this operation comes
    #   from a new grant that has not yet achieved *eventual consistency*. For
    #   more information, see [Grant token][1] and [Using a grant token][2] in
    #   the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html#grant_token
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/using-grant-token.html
    #
    # @option params [Boolean] :dry_run
    #   Checks if your request will succeed. `DryRun` is an optional
    #   parameter.
    #
    #   To learn more about how to use this parameter, see [Testing your
    #   permissions][1] in the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/testing-permissions.html
    #
    # @option params [Types::RecipientInfo] :recipient
    #   A signed [attestation document][1] from an Amazon Web Services Nitro
    #   enclave or NitroTPM, and the encryption algorithm to use with the
    #   public key in the attestation document. The only valid encryption
    #   algorithm is `RSAES_OAEP_SHA_256`.
    #
    #   This parameter only supports attestation documents for Amazon Web
    #   Services Nitro Enclaves or Amazon Web Services NitroTPM. To call
    #   DeriveSharedSecret generate an attestation document use either [Amazon
    #   Web Services Nitro Enclaves SDK][2] for an Amazon Web Services Nitro
    #   Enclaves or [Amazon Web Services NitroTPM tools][3] for Amazon Web
    #   Services NitroTPM. Then use the Recipient parameter from any Amazon
    #   Web Services SDK to provide the attestation document for the attested
    #   environment.
    #
    #   When you use this parameter, instead of returning a plaintext copy of
    #   the shared secret, KMS encrypts the plaintext shared secret under the
    #   public key in the attestation document, and returns the resulting
    #   ciphertext in the `CiphertextForRecipient` field in the response. This
    #   ciphertext can be decrypted only with the private key in the attested
    #   environment. The `CiphertextBlob` field in the response contains the
    #   encrypted shared secret derived from the KMS key specified by the
    #   `KeyId` parameter and public key specified by the `PublicKey`
    #   parameter. The `SharedSecret` field in the response is null or empty.
    #
    #   For information about the interaction between KMS and Amazon Web
    #   Services Nitro Enclaves or Amazon Web Services NitroTPM, see
    #   [Cryptographic attestation support in KMS][4] in the *Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/nitro-enclave-how.html#term-attestdoc
    #   [2]: https://docs.aws.amazon.com/enclaves/latest/user/developing-applications.html#sdk
    #   [3]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/attestation-get-doc.html
    #   [4]: https://docs.aws.amazon.com/kms/latest/developerguide/cryptographic-attestation.html
    #
    # @return [Types::DeriveSharedSecretResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::DeriveSharedSecretResponse#key_id #key_id} => String
    #   * {Types::DeriveSharedSecretResponse#shared_secret #shared_secret} => String
    #   * {Types::DeriveSharedSecretResponse#ciphertext_for_recipient #ciphertext_for_recipient} => String
    #   * {Types::DeriveSharedSecretResponse#key_agreement_algorithm #key_agreement_algorithm} => String
    #   * {Types::DeriveSharedSecretResponse#key_origin #key_origin} => String
    #
    #
    # @example Example: To derive a shared secret
    #
    #   # The following example derives a shared secret using a key agreement algorithm.
    #
    #   resp = client.derive_shared_secret({
    #     key_agreement_algorithm: "ECDH", # The key agreement algorithm used to derive the shared secret. The only valid value is ECDH.
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The key identifier for an asymmetric KMS key pair. The private key in the specified key pair is used to derive the shared secret.
    #     public_key: "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvH3Yj0wbkLEpUl95Cv1cJVjsVNSjwGq3tCLnzXfhVwVvmzGN8pYj3U8nKwgouaHbBWNJYjP5VutbbkKS4Kv4GojwZBJyHN17kmxo8yTjRmjR15SKIQ8cqRA2uaERMLnpztIXdZp232PQPbWGxDyXYJ0aJ5EFSag", # The public key in your peer's asymmetric key pair.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_agreement_algorithm: "ECDH", # The key agreement algorithm used to derive the shared secret.
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The asymmetric KMS key pair used to derive the shared secret.
    #     key_origin: "AWS_KMS", # The source of the key material for the specified KMS key.
    #     shared_secret: "MEYCIQCKZLWyTk5runarx6XiAkU9gv3lbwPO/pHa+DXFehzdDwIhANwpsIV2g/9SPWLLsF6p/hiSskuIXMTRwqrMdVKWTMHG", # The raw secret derived from the specified key agreement algorithm, private key in the asymmetric KMS key, and your peer's public key.
    #   }
    #
    # @example Example: To derive a shared secret for a Nitro enclave or NitroTPM
    #
    #   # The following example includes the Recipient parameter with a signed attestation document from an AWS Nitro enclave or
    #   # NitroTPM. Instead of returning a plaintext shared secret, DeriveSharedSecret returns the shared secret encrypted by the
    #   # public key from the attestation document.
    #
    #   resp = client.derive_shared_secret({
    #     key_agreement_algorithm: "ECDH", # The key agreement algorithm used to derive the shared secret. The only valid value is ECDH.
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The key identifier for an asymmetric KMS key pair. The private key in the specified key pair is used to derive the shared secret.
    #     public_key: "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvH3Yj0wbkLEpUl95Cv1cJVjsVNSjwGq3tCLnzXfhVwVvmzGN8pYj3U8nKwgouaHbBWNJYjP5VutbbkKS4Kv4GojwZBJyHN17kmxo8yTjRmjR15SKIQ8cqRA2uaERMLnpztIXdZp232PQPbWGxDyXYJ0aJ5EFSag", # The public key in your peer's asymmetric key pair.
    #     recipient: {
    #       attestation_document: "<attestation document>", 
    #       key_encryption_algorithm: "RSAES_OAEP_SHA_256", 
    #     }, # Specifies the attestation document from the Nitro enclave or NitroTPM and the encryption algorithm to use with the public key from the attestation document
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     ciphertext_for_recipient: "<binary data>", # The shared secret encrypted by the public key from the attestation document
    #     key_agreement_algorithm: "ECDH", # The key agreement algorithm used to derive the shared secret.
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The asymmetric KMS key pair used to derive the shared secret.
    #     key_origin: "AWS_KMS", # The source of the key material for the specified KMS key.
    #     shared_secret: "", # This field is null or empty
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.derive_shared_secret({
    #     key_id: "KeyIdType", # required
    #     key_agreement_algorithm: "ECDH", # required, accepts ECDH
    #     public_key: "data", # required
    #     grant_tokens: ["GrantTokenType"],
    #     dry_run: false,
    #     recipient: {
    #       key_encryption_algorithm: "RSAES_OAEP_SHA_256", # accepts RSAES_OAEP_SHA_256
    #       attestation_document: "data",
    #     },
    #   })
    #
    # @example Response structure
    #
    #   resp.key_id #=> String
    #   resp.shared_secret #=> String
    #   resp.ciphertext_for_recipient #=> String
    #   resp.key_agreement_algorithm #=> String, one of "ECDH"
    #   resp.key_origin #=> String, one of "AWS_KMS", "EXTERNAL", "AWS_CLOUDHSM", "EXTERNAL_KEY_STORE"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DeriveSharedSecret AWS API Documentation
    #
    # @overload derive_shared_secret(params = {})
    # @param [Hash] params ({})
    def derive_shared_secret(params = {}, options = {})
      req = build_request(:derive_shared_secret, params)
      req.send_request(options)
    end

    # Gets information about [custom key stores][1] in the account and
    # Region.
    #
    # This operation is part of the custom key stores feature in KMS, which
    # combines the convenience and extensive integration of KMS with the
    # isolation and control of a key store that you own and manage.
    #
    # By default, this operation returns information about all custom key
    # stores in the account and Region. To get only information about a
    # particular custom key store, use either the `CustomKeyStoreName` or
    # `CustomKeyStoreId` parameter (but not both).
    #
    # To determine whether the custom key store is connected to its CloudHSM
    # cluster or external key store proxy, use the `ConnectionState` element
    # in the response. If an attempt to connect the custom key store failed,
    # the `ConnectionState` value is `FAILED` and the `ConnectionErrorCode`
    # element in the response indicates the cause of the failure. For help
    # interpreting the `ConnectionErrorCode`, see CustomKeyStoresListEntry.
    #
    # Custom key stores have a `DISCONNECTED` connection state if the key
    # store has never been connected or you used the
    # DisconnectCustomKeyStore operation to disconnect it. Otherwise, the
    # connection state is CONNECTED. If your custom key store connection
    # state is `CONNECTED` but you are having trouble using it, verify that
    # the backing store is active and available. For an CloudHSM key store,
    # verify that the associated CloudHSM cluster is active and contains the
    # minimum number of HSMs required for the operation, if any. For an
    # external key store, verify that the external key store proxy and its
    # associated external key manager are reachable and enabled.
    #
    # For help repairing your CloudHSM key store, see the [Troubleshooting
    # CloudHSM key stores][2]. For help repairing your external key store,
    # see the [Troubleshooting external key stores][3]. Both topics are in
    # the *Key Management Service Developer Guide*.
    #
    # **Cross-account use**: No. You cannot perform this operation on a
    # custom key store in a different Amazon Web Services account.
    #
    # **Required permissions**: [kms:DescribeCustomKeyStores][4] (IAM
    # policy)
    #
    # **Related operations:**
    #
    # * ConnectCustomKeyStore
    #
    # * CreateCustomKeyStore
    #
    # * DeleteCustomKeyStore
    #
    # * DisconnectCustomKeyStore
    #
    # * UpdateCustomKeyStore
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][5].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-store-overview.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/xks-troubleshooting.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [String] :custom_key_store_id
    #   Gets only information about the specified custom key store. Enter the
    #   key store ID.
    #
    #   By default, this operation gets information about all custom key
    #   stores in the account and Region. To limit the output to a particular
    #   custom key store, provide either the `CustomKeyStoreId` or
    #   `CustomKeyStoreName` parameter, but not both.
    #
    # @option params [String] :custom_key_store_name
    #   Gets only information about the specified custom key store. Enter the
    #   friendly name of the custom key store.
    #
    #   By default, this operation gets information about all custom key
    #   stores in the account and Region. To limit the output to a particular
    #   custom key store, provide either the `CustomKeyStoreId` or
    #   `CustomKeyStoreName` parameter, but not both.
    #
    # @option params [Integer] :limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    # @option params [String] :marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #
    # @return [Types::DescribeCustomKeyStoresResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::DescribeCustomKeyStoresResponse#custom_key_stores #custom_key_stores} => Array&lt;Types::CustomKeyStoresListEntry&gt;
    #   * {Types::DescribeCustomKeyStoresResponse#next_marker #next_marker} => String
    #   * {Types::DescribeCustomKeyStoresResponse#truncated #truncated} => Boolean
    #
    # The returned {Seahorse::Client::Response response} is a pageable response and is Enumerable. For details on usage see {Aws::PageableResponse PageableResponse}.
    #
    #
    # @example Example: To get detailed information about custom key stores in the account and Region
    #
    #   # This example gets detailed information about all AWS KMS custom key stores in an AWS account and Region. To get all key
    #   # stores, do not enter a custom key store name or ID.
    #
    #   resp = client.describe_custom_key_stores({
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     custom_key_stores: [
    #     ], # Details about each custom key store in the account and Region.
    #   }
    #
    # @example Example: To get detailed information about an AWS CloudHSM key store by specifying its friendly name
    #
    #   # This example gets detailed information about a particular AWS CloudHSM key store by specifying its friendly name. To
    #   # limit the output to a particular custom key store, provide either the custom key store name or ID.
    #
    #   resp = client.describe_custom_key_stores({
    #     custom_key_store_name: "ExampleKeyStore", # The friendly name of the custom key store.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     custom_key_stores: [
    #       {
    #         cloud_hsm_cluster_id: "cluster-234abcdefABC", 
    #         connection_state: "CONNECTED", 
    #         creation_date: Time.parse("1.499288695918E9"), 
    #         custom_key_store_id: "cks-1234567890abcdef0", 
    #         custom_key_store_name: "ExampleKeyStore", 
    #         custom_key_store_type: "AWS_CLOUDHSM", 
    #         trust_anchor_certificate: "<certificate appears here>", 
    #       }, 
    #     ], # Detailed information about the specified custom key store.
    #   }
    #
    # @example Example: To get detailed information about an external key store by specifying its ID
    #
    #   # This example gets detailed information about an external key store by specifying its ID.  The example external key store
    #   # proxy uses public endpoint connectivity.
    #
    #   resp = client.describe_custom_key_stores({
    #     custom_key_store_id: "cks-9876543210fedcba9", # The ID of the custom key store.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     custom_key_stores: [
    #       {
    #         connection_state: "CONNECTED", 
    #         creation_date: Time.parse("1.599288695918E9"), 
    #         custom_key_store_id: "cks-9876543210fedcba9", 
    #         custom_key_store_name: "ExampleExternalKeyStore", 
    #         custom_key_store_type: "EXTERNAL_KEY_STORE", 
    #         xks_proxy_configuration: {
    #           access_key_id: "ABCDE12345670EXAMPLE", 
    #           connectivity: "PUBLIC_ENDPOINT", 
    #           uri_endpoint: "https://myproxy.xks.example.com", 
    #           uri_path: "/kms/xks/v1", 
    #         }, 
    #       }, 
    #     ], # Detailed information about the specified custom key store.
    #   }
    #
    # @example Example: To get detailed information about an external key store VPC endpoint connectivity by specifying its friendly name
    #
    #   # This example gets detailed information about a particular external key store by specifying its friendly name. To limit
    #   # the output to a particular custom key store, provide either the custom key store name or ID. The proxy URI path for this
    #   # external key store includes an optional prefix. Also, because this example external key store uses VPC endpoint
    #   # connectivity, the response includes the associated VPC endpoint service name.
    #
    #   resp = client.describe_custom_key_stores({
    #     custom_key_store_name: "VPCExternalKeystore", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     custom_key_stores: [
    #       {
    #         connection_state: "CONNECTED", 
    #         creation_date: Time.parse("1.643057863.842"), 
    #         custom_key_store_id: "cks-876543210fedcba98", 
    #         custom_key_store_name: "ExampleVPCExternalKeyStore", 
    #         custom_key_store_type: "EXTERNAL_KEY_STORE", 
    #         xks_proxy_configuration: {
    #           access_key_id: "ABCDE12345670EXAMPLE", 
    #           connectivity: "VPC_ENDPOINT_SERVICE", 
    #           uri_endpoint: "https://myproxy-private.xks.example.com", 
    #           uri_path: "/example-prefix/kms/xks/v1", 
    #           vpc_endpoint_service_name: "com.amazonaws.vpce.us-east-1.vpce-svc-example1", 
    #         }, 
    #       }, 
    #     ], # Detailed information about the specified custom key store.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.describe_custom_key_stores({
    #     custom_key_store_id: "CustomKeyStoreIdType",
    #     custom_key_store_name: "CustomKeyStoreNameType",
    #     limit: 1,
    #     marker: "MarkerType",
    #   })
    #
    # @example Response structure
    #
    #   resp.custom_key_stores #=> Array
    #   resp.custom_key_stores[0].custom_key_store_id #=> String
    #   resp.custom_key_stores[0].custom_key_store_name #=> String
    #   resp.custom_key_stores[0].cloud_hsm_cluster_id #=> String
    #   resp.custom_key_stores[0].trust_anchor_certificate #=> String
    #   resp.custom_key_stores[0].connection_state #=> String, one of "CONNECTED", "CONNECTING", "FAILED", "DISCONNECTED", "DISCONNECTING"
    #   resp.custom_key_stores[0].connection_error_code #=> String, one of "INVALID_CREDENTIALS", "CLUSTER_NOT_FOUND", "NETWORK_ERRORS", "INTERNAL_ERROR", "INSUFFICIENT_CLOUDHSM_HSMS", "USER_LOCKED_OUT", "USER_NOT_FOUND", "USER_LOGGED_IN", "SUBNET_NOT_FOUND", "INSUFFICIENT_FREE_ADDRESSES_IN_SUBNET", "XKS_PROXY_ACCESS_DENIED", "XKS_PROXY_NOT_REACHABLE", "XKS_VPC_ENDPOINT_SERVICE_NOT_FOUND", "XKS_PROXY_INVALID_RESPONSE", "XKS_PROXY_INVALID_CONFIGURATION", "XKS_VPC_ENDPOINT_SERVICE_INVALID_CONFIGURATION", "XKS_PROXY_TIMED_OUT", "XKS_PROXY_INVALID_TLS_CONFIGURATION"
    #   resp.custom_key_stores[0].creation_date #=> Time
    #   resp.custom_key_stores[0].custom_key_store_type #=> String, one of "AWS_CLOUDHSM", "EXTERNAL_KEY_STORE"
    #   resp.custom_key_stores[0].xks_proxy_configuration.connectivity #=> String, one of "PUBLIC_ENDPOINT", "VPC_ENDPOINT_SERVICE"
    #   resp.custom_key_stores[0].xks_proxy_configuration.access_key_id #=> String
    #   resp.custom_key_stores[0].xks_proxy_configuration.uri_endpoint #=> String
    #   resp.custom_key_stores[0].xks_proxy_configuration.uri_path #=> String
    #   resp.custom_key_stores[0].xks_proxy_configuration.vpc_endpoint_service_name #=> String
    #   resp.custom_key_stores[0].xks_proxy_configuration.vpc_endpoint_service_owner #=> String
    #   resp.next_marker #=> String
    #   resp.truncated #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DescribeCustomKeyStores AWS API Documentation
    #
    # @overload describe_custom_key_stores(params = {})
    # @param [Hash] params ({})
    def describe_custom_key_stores(params = {}, options = {})
      req = build_request(:describe_custom_key_stores, params)
      req.send_request(options)
    end

    # Provides detailed information about a KMS key. You can run
    # `DescribeKey` on a [customer managed key][1] or an [Amazon Web
    # Services managed key][2].
    #
    # This detailed information includes the key ARN, creation date (and
    # deletion date, if applicable), the key state, and the origin and
    # expiration date (if any) of the key material. It includes fields, like
    # `KeySpec`, that help you distinguish different types of KMS keys. It
    # also displays the key usage (encryption, signing, or generating and
    # verifying MACs) and the algorithms that the KMS key supports.
    #
    # For [multi-Region keys][3], `DescribeKey` displays the primary key and
    # all related replica keys. For KMS keys in [CloudHSM key stores][4], it
    # includes information about the key store, such as the key store ID and
    # the CloudHSM cluster ID. For KMS keys in [external key stores][5], it
    # includes the custom key store ID and the ID of the external key.
    #
    # `DescribeKey` does not return the following information:
    #
    # * Aliases associated with the KMS key. To get this information, use
    #   ListAliases.
    #
    # * Whether automatic key rotation is enabled on the KMS key. To get
    #   this information, use GetKeyRotationStatus. Also, some key states
    #   prevent a KMS key from being automatically rotated. For details, see
    #   [How key rotation works][6] in the *Key Management Service Developer
    #   Guide*.
    #
    # * Tags on the KMS key. To get this information, use ListResourceTags.
    #
    # * Key policies and grants on the KMS key. To get this information, use
    #   GetKeyPolicy and ListGrants.
    #
    # In general, `DescribeKey` is a non-mutating operation. It returns data
    # about KMS keys, but doesn't change them. However, Amazon Web Services
    # services use `DescribeKey` to create [Amazon Web Services managed
    # keys][2] from a *predefined Amazon Web Services alias* with no key ID.
    #
    # **Cross-account use**: Yes. To perform this operation with a KMS key
    # in a different Amazon Web Services account, specify the key ARN or
    # alias ARN in the value of the `KeyId` parameter.
    #
    # **Required permissions**: [kms:DescribeKey][7] (key policy)
    #
    # **Related operations:**
    #
    # * GetKeyPolicy
    #
    # * GetKeyRotationStatus
    #
    # * ListAliases
    #
    # * ListGrants
    #
    # * ListKeys
    #
    # * ListResourceTags
    #
    # * ListRetirableGrants
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][8].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-mgn-key
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-key
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-overview.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/keystore-cloudhsm.html
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/keystore-external.html
    # [6]: https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html#rotate-keys-how-it-works
    # [7]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [8]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Describes the specified KMS key.
    #
    #   If you specify a predefined Amazon Web Services alias (an Amazon Web
    #   Services alias with no key ID), KMS associates the alias with an
    #   [Amazon Web Services managed key][1] and returns its `KeyId` and `Arn`
    #   in the response.
    #
    #   To specify a KMS key, use its key ID, key ARN, alias name, or alias
    #   ARN. When using an alias name, prefix it with `"alias/"`. To specify a
    #   KMS key in a different Amazon Web Services account, you must use the
    #   key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey. To get the alias name and alias ARN, use ListAliases.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-key
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   Use a grant token when your permission to call this operation comes
    #   from a new grant that has not yet achieved *eventual consistency*. For
    #   more information, see [Grant token][1] and [Using a grant token][2] in
    #   the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html#grant_token
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/using-grant-token.html
    #
    # @return [Types::DescribeKeyResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::DescribeKeyResponse#key_metadata #key_metadata} => Types::KeyMetadata
    #
    #
    # @example Example: To get details about a KMS key
    #
    #   # The following example gets metadata for a symmetric encryption KMS key.
    #
    #   resp = client.describe_key({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # An identifier for the KMS key. You can use the key ID, key ARN, alias name, alias ARN of the KMS key.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_metadata: {
    #       aws_account_id: "111122223333", 
    #       arn: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       creation_date: Time.parse("2017-07-05T14:04:55-07:00"), 
    #       current_key_material_id: "0b7fd7ddbac6eef27907413567cad8c810e2883dc8a7534067a82ee1142fc1e6", 
    #       customer_master_key_spec: "SYMMETRIC_DEFAULT", 
    #       description: "", 
    #       enabled: true, 
    #       encryption_algorithms: [
    #         "SYMMETRIC_DEFAULT", 
    #       ], 
    #       key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       key_manager: "CUSTOMER", 
    #       key_spec: "SYMMETRIC_DEFAULT", 
    #       key_state: "Enabled", 
    #       key_usage: "ENCRYPT_DECRYPT", 
    #       multi_region: false, 
    #       origin: "AWS_KMS", 
    #     }, # An object that contains information about the specified KMS key.
    #   }
    #
    # @example Example: To get details about an RSA asymmetric KMS key
    #
    #   # The following example gets metadata for an asymmetric RSA KMS key used for signing and verification.
    #
    #   resp = client.describe_key({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # An identifier for the KMS key. You can use the key ID, key ARN, alias name, alias ARN of the KMS key.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_metadata: {
    #       aws_account_id: "111122223333", 
    #       arn: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       creation_date: Time.parse(1571767572.317), 
    #       customer_master_key_spec: "RSA_2048", 
    #       description: "", 
    #       enabled: false, 
    #       key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       key_manager: "CUSTOMER", 
    #       key_spec: "RSA_2048", 
    #       key_state: "Disabled", 
    #       key_usage: "SIGN_VERIFY", 
    #       multi_region: false, 
    #       origin: "AWS_KMS", 
    #       signing_algorithms: [
    #         "RSASSA_PKCS1_V1_5_SHA_256", 
    #         "RSASSA_PKCS1_V1_5_SHA_384", 
    #         "RSASSA_PKCS1_V1_5_SHA_512", 
    #         "RSASSA_PSS_SHA_256", 
    #         "RSASSA_PSS_SHA_384", 
    #         "RSASSA_PSS_SHA_512", 
    #       ], 
    #     }, # An object that contains information about the specified KMS key.
    #   }
    #
    # @example Example: To get details about a multi-Region key
    #
    #   # The following example gets metadata for a multi-Region replica key. This multi-Region key is a symmetric encryption key.
    #   # DescribeKey returns information about the primary key and all of its replicas.
    #
    #   resp = client.describe_key({
    #     key_id: "arn:aws:kms:ap-northeast-1:111122223333:key/mrk-1234abcd12ab34cd56ef1234567890ab", # An identifier for the KMS key. You can use the key ID, key ARN, alias name, alias ARN of the KMS key.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_metadata: {
    #       aws_account_id: "111122223333", 
    #       arn: "arn:aws:kms:ap-northeast-1:111122223333:key/mrk-1234abcd12ab34cd56ef1234567890ab", 
    #       creation_date: Time.parse(1586329200.918), 
    #       current_key_material_id: "0b7fd7ddbac6eef27907413567cad8c810e2883dc8a7534067a82ee1142fc1e6", 
    #       customer_master_key_spec: "SYMMETRIC_DEFAULT", 
    #       description: "", 
    #       enabled: true, 
    #       encryption_algorithms: [
    #         "SYMMETRIC_DEFAULT", 
    #       ], 
    #       key_id: "mrk-1234abcd12ab34cd56ef1234567890ab", 
    #       key_manager: "CUSTOMER", 
    #       key_state: "Enabled", 
    #       key_usage: "ENCRYPT_DECRYPT", 
    #       multi_region: true, 
    #       multi_region_configuration: {
    #         multi_region_key_type: "PRIMARY", 
    #         primary_key: {
    #           arn: "arn:aws:kms:us-west-2:111122223333:key/mrk-1234abcd12ab34cd56ef1234567890ab", 
    #           region: "us-west-2", 
    #         }, 
    #         replica_keys: [
    #           {
    #             arn: "arn:aws:kms:eu-west-1:111122223333:key/mrk-1234abcd12ab34cd56ef1234567890ab", 
    #             region: "eu-west-1", 
    #           }, 
    #           {
    #             arn: "arn:aws:kms:ap-northeast-1:111122223333:key/mrk-1234abcd12ab34cd56ef1234567890ab", 
    #             region: "ap-northeast-1", 
    #           }, 
    #           {
    #             arn: "arn:aws:kms:sa-east-1:111122223333:key/mrk-1234abcd12ab34cd56ef1234567890ab", 
    #             region: "sa-east-1", 
    #           }, 
    #         ], 
    #       }, 
    #       origin: "AWS_KMS", 
    #     }, # An object that contains information about the specified KMS key.
    #   }
    #
    # @example Example: To get details about an HMAC KMS key
    #
    #   # The following example gets the metadata of an HMAC KMS key.
    #
    #   resp = client.describe_key({
    #     key_id: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # An identifier for the KMS key. You can use the key ID, key ARN, alias name, alias ARN of the KMS key.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_metadata: {
    #       aws_account_id: "123456789012", 
    #       arn: "arn:aws:kms:us-west-2:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       creation_date: Time.parse(1566160362.664), 
    #       customer_master_key_spec: "HMAC_256", 
    #       description: "Development test key", 
    #       enabled: true, 
    #       key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       key_manager: "CUSTOMER", 
    #       key_state: "Enabled", 
    #       key_usage: "GENERATE_VERIFY_MAC", 
    #       mac_algorithms: [
    #         "HMAC_SHA_256", 
    #       ], 
    #       multi_region: false, 
    #       origin: "AWS_KMS", 
    #     }, # An object that contains information about the specified KMS key.
    #   }
    #
    # @example Example: To get details about a KMS key in an AWS CloudHSM key store
    #
    #   # The following example gets the metadata of a KMS key in an AWS CloudHSM key store.
    #
    #   resp = client.describe_key({
    #     key_id: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # An identifier for the KMS key. You can use the key ID, key ARN, alias name, alias ARN of the KMS key.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_metadata: {
    #       aws_account_id: "123456789012", 
    #       arn: "arn:aws:kms:us-west-2:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       cloud_hsm_cluster_id: "cluster-234abcdefABC", 
    #       creation_date: Time.parse(1646160362.664), 
    #       custom_key_store_id: "cks-1234567890abcdef0", 
    #       customer_master_key_spec: "SYMMETRIC_DEFAULT", 
    #       description: "CloudHSM key store test key", 
    #       enabled: true, 
    #       encryption_algorithms: [
    #         "SYMMETRIC_DEFAULT", 
    #       ], 
    #       key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       key_manager: "CUSTOMER", 
    #       key_spec: "SYMMETRIC_DEFAULT", 
    #       key_state: "Enabled", 
    #       key_usage: "ENCRYPT_DECRYPT", 
    #       multi_region: false, 
    #       origin: "AWS_CLOUDHSM", 
    #     }, # An object that contains information about the specified KMS key.
    #   }
    #
    # @example Example: To get details about a KMS key in an external key store
    #
    #   # The following example gets the metadata of a KMS key in an external key store.
    #
    #   resp = client.describe_key({
    #     key_id: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # An identifier for the KMS key. You can use the key ID, key ARN, alias name, alias ARN of the KMS key.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_metadata: {
    #       aws_account_id: "123456789012", 
    #       arn: "arn:aws:kms:us-west-2:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       creation_date: Time.parse(1646160362.664), 
    #       custom_key_store_id: "cks-1234567890abcdef0", 
    #       customer_master_key_spec: "SYMMETRIC_DEFAULT", 
    #       description: "External key store test key", 
    #       enabled: true, 
    #       encryption_algorithms: [
    #         "SYMMETRIC_DEFAULT", 
    #       ], 
    #       key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", 
    #       key_manager: "CUSTOMER", 
    #       key_spec: "SYMMETRIC_DEFAULT", 
    #       key_state: "Enabled", 
    #       key_usage: "ENCRYPT_DECRYPT", 
    #       multi_region: false, 
    #       origin: "EXTERNAL_KEY_STORE", 
    #       xks_key_configuration: {
    #         id: "bb8562717f809024", 
    #       }, 
    #     }, # An object that contains information about the specified KMS key.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.describe_key({
    #     key_id: "KeyIdType", # required
    #     grant_tokens: ["GrantTokenType"],
    #   })
    #
    # @example Response structure
    #
    #   resp.key_metadata.aws_account_id #=> String
    #   resp.key_metadata.key_id #=> String
    #   resp.key_metadata.arn #=> String
    #   resp.key_metadata.creation_date #=> Time
    #   resp.key_metadata.enabled #=> Boolean
    #   resp.key_metadata.description #=> String
    #   resp.key_metadata.key_usage #=> String, one of "SIGN_VERIFY", "ENCRYPT_DECRYPT", "GENERATE_VERIFY_MAC", "KEY_AGREEMENT"
    #   resp.key_metadata.key_state #=> String, one of "Creating", "Enabled", "Disabled", "PendingDeletion", "PendingImport", "PendingReplicaDeletion", "Unavailable", "Updating"
    #   resp.key_metadata.deletion_date #=> Time
    #   resp.key_metadata.valid_to #=> Time
    #   resp.key_metadata.origin #=> String, one of "AWS_KMS", "EXTERNAL", "AWS_CLOUDHSM", "EXTERNAL_KEY_STORE"
    #   resp.key_metadata.custom_key_store_id #=> String
    #   resp.key_metadata.cloud_hsm_cluster_id #=> String
    #   resp.key_metadata.expiration_model #=> String, one of "KEY_MATERIAL_EXPIRES", "KEY_MATERIAL_DOES_NOT_EXPIRE"
    #   resp.key_metadata.key_manager #=> String, one of "AWS", "CUSTOMER"
    #   resp.key_metadata.customer_master_key_spec #=> String, one of "RSA_2048", "RSA_3072", "RSA_4096", "ECC_NIST_P256", "ECC_NIST_P384", "ECC_NIST_P521", "ECC_SECG_P256K1", "SYMMETRIC_DEFAULT", "HMAC_224", "HMAC_256", "HMAC_384", "HMAC_512", "SM2"
    #   resp.key_metadata.key_spec #=> String, one of "RSA_2048", "RSA_3072", "RSA_4096", "ECC_NIST_P256", "ECC_NIST_P384", "ECC_NIST_P521", "ECC_SECG_P256K1", "SYMMETRIC_DEFAULT", "HMAC_224", "HMAC_256", "HMAC_384", "HMAC_512", "SM2", "ML_DSA_44", "ML_DSA_65", "ML_DSA_87", "ECC_NIST_EDWARDS25519"
    #   resp.key_metadata.encryption_algorithms #=> Array
    #   resp.key_metadata.encryption_algorithms[0] #=> String, one of "SYMMETRIC_DEFAULT", "RSAES_OAEP_SHA_1", "RSAES_OAEP_SHA_256", "SM2PKE"
    #   resp.key_metadata.signing_algorithms #=> Array
    #   resp.key_metadata.signing_algorithms[0] #=> String, one of "RSASSA_PSS_SHA_256", "RSASSA_PSS_SHA_384", "RSASSA_PSS_SHA_512", "RSASSA_PKCS1_V1_5_SHA_256", "RSASSA_PKCS1_V1_5_SHA_384", "RSASSA_PKCS1_V1_5_SHA_512", "ECDSA_SHA_256", "ECDSA_SHA_384", "ECDSA_SHA_512", "SM2DSA", "ML_DSA_SHAKE_256", "ED25519_SHA_512", "ED25519_PH_SHA_512"
    #   resp.key_metadata.key_agreement_algorithms #=> Array
    #   resp.key_metadata.key_agreement_algorithms[0] #=> String, one of "ECDH"
    #   resp.key_metadata.multi_region #=> Boolean
    #   resp.key_metadata.multi_region_configuration.multi_region_key_type #=> String, one of "PRIMARY", "REPLICA"
    #   resp.key_metadata.multi_region_configuration.primary_key.arn #=> String
    #   resp.key_metadata.multi_region_configuration.primary_key.region #=> String
    #   resp.key_metadata.multi_region_configuration.replica_keys #=> Array
    #   resp.key_metadata.multi_region_configuration.replica_keys[0].arn #=> String
    #   resp.key_metadata.multi_region_configuration.replica_keys[0].region #=> String
    #   resp.key_metadata.pending_deletion_window_in_days #=> Integer
    #   resp.key_metadata.mac_algorithms #=> Array
    #   resp.key_metadata.mac_algorithms[0] #=> String, one of "HMAC_SHA_224", "HMAC_SHA_256", "HMAC_SHA_384", "HMAC_SHA_512"
    #   resp.key_metadata.xks_key_configuration.id #=> String
    #   resp.key_metadata.current_key_material_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DescribeKey AWS API Documentation
    #
    # @overload describe_key(params = {})
    # @param [Hash] params ({})
    def describe_key(params = {}, options = {})
      req = build_request(:describe_key, params)
      req.send_request(options)
    end

    # Sets the state of a KMS key to disabled. This change temporarily
    # prevents use of the KMS key for [cryptographic operations][1].
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For more information about how key state affects the use of
    # a KMS key, see [Key states of KMS keys][2] in the <i> <i>Key
    # Management Service Developer Guide</i> </i>.
    #
    # **Cross-account use**: No. You cannot perform this operation on a KMS
    # key in a different Amazon Web Services account.
    #
    # **Required permissions**: [kms:DisableKey][3] (key policy)
    #
    # **Related operations**: EnableKey
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][4].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-cryptography.html#cryptographic-operations
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Identifies the KMS key to disable.
    #
    #   Specify the key ID or key ARN of the KMS key.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To disable a KMS key
    #
    #   # The following example disables the specified KMS key.
    #
    #   resp = client.disable_key({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key to disable. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.disable_key({
    #     key_id: "KeyIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DisableKey AWS API Documentation
    #
    # @overload disable_key(params = {})
    # @param [Hash] params ({})
    def disable_key(params = {}, options = {})
      req = build_request(:disable_key, params)
      req.send_request(options)
    end

    # Disables [automatic rotation of the key material][1] of the specified
    # symmetric encryption KMS key.
    #
    # Automatic key rotation is supported only on symmetric encryption KMS
    # keys. You cannot enable automatic rotation of [asymmetric KMS
    # keys][2], [HMAC KMS keys][3], KMS keys with [imported key
    # material][4], or KMS keys in a [custom key store][5]. To enable or
    # disable automatic rotation of a set of related [multi-Region keys][6],
    # set the property on the primary key.
    #
    # You can enable (EnableKeyRotation) and disable automatic rotation of
    # the key material in [customer managed KMS keys][7]. Key material
    # rotation of [Amazon Web Services managed KMS keys][8] is not
    # configurable. KMS always rotates the key material for every year.
    # Rotation of [Amazon Web Services owned KMS keys][9] varies.
    #
    # <note markdown="1"> In May 2022, KMS changed the rotation schedule for Amazon Web Services
    # managed keys from every three years to every year. For details, see
    # EnableKeyRotation.
    #
    #  </note>
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][10] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: No. You cannot perform this operation on a KMS
    # key in a different Amazon Web Services account.
    #
    # **Required permissions**: [kms:DisableKeyRotation][11] (key policy)
    #
    # **Related operations:**
    #
    # * EnableKeyRotation
    #
    # * GetKeyRotationStatus
    #
    # * ListKeyRotations
    #
    # * RotateKeyOnDemand
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][12].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/rotating-keys-enable-disable.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/hmac.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/key-store-overview.html
    # [6]: https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html#multi-region-rotate
    # [7]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-mgn-key
    # [8]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-key
    # [9]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-owned-key
    # [10]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [11]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [12]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Identifies a symmetric encryption KMS key. You cannot enable or
    #   disable automatic rotation of [asymmetric KMS keys][1], [HMAC KMS
    #   keys][2], KMS keys with [imported key material][3], or KMS keys in a
    #   [custom key store][4].
    #
    #   Specify the key ID or key ARN of the KMS key.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html#asymmetric-cmks
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/hmac.html
    #   [3]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html
    #   [4]: https://docs.aws.amazon.com/kms/latest/developerguide/key-store-overview.html
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To disable automatic rotation of key material
    #
    #   # The following example disables automatic annual rotation of the key material for the specified KMS key.
    #
    #   resp = client.disable_key_rotation({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key whose key material will no longer be rotated. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.disable_key_rotation({
    #     key_id: "KeyIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DisableKeyRotation AWS API Documentation
    #
    # @overload disable_key_rotation(params = {})
    # @param [Hash] params ({})
    def disable_key_rotation(params = {}, options = {})
      req = build_request(:disable_key_rotation, params)
      req.send_request(options)
    end

    # Disconnects the [custom key store][1] from its backing key store. This
    # operation disconnects an CloudHSM key store from its associated
    # CloudHSM cluster or disconnects an external key store from the
    # external key store proxy that communicates with your external key
    # manager.
    #
    # This operation is part of the custom key stores feature in KMS, which
    # combines the convenience and extensive integration of KMS with the
    # isolation and control of a key store that you own and manage.
    #
    # While a custom key store is disconnected, you can manage the custom
    # key store and its KMS keys, but you cannot create or use its KMS keys.
    # You can reconnect the custom key store at any time.
    #
    # <note markdown="1"> While a custom key store is disconnected, all attempts to create KMS
    # keys in the custom key store or to use existing KMS keys in
    # [cryptographic operations][2] will fail. This action can prevent users
    # from storing and accessing sensitive data.
    #
    #  </note>
    #
    # When you disconnect a custom key store, its `ConnectionState` changes
    # to `Disconnected`. To find the connection state of a custom key store,
    # use the DescribeCustomKeyStores operation. To reconnect a custom key
    # store, use the ConnectCustomKeyStore operation.
    #
    # If the operation succeeds, it returns a JSON object with no
    # properties.
    #
    # **Cross-account use**: No. You cannot perform this operation on a
    # custom key store in a different Amazon Web Services account.
    #
    # **Required permissions**: [kms:DisconnectCustomKeyStore][3] (IAM
    # policy)
    #
    # **Related operations:**
    #
    # * ConnectCustomKeyStore
    #
    # * CreateCustomKeyStore
    #
    # * DeleteCustomKeyStore
    #
    # * DescribeCustomKeyStores
    #
    # * UpdateCustomKeyStore
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][4].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-store-overview.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-cryptography.html#cryptographic-operations
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :custom_key_store_id
    #   Enter the ID of the custom key store you want to disconnect. To find
    #   the ID of a custom key store, use the DescribeCustomKeyStores
    #   operation.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To disconnect a custom key store from its CloudHSM cluster
    #
    #   # This example disconnects an AWS KMS custom key store from its backing key store. For an AWS CloudHSM key store, it
    #   # disconnects the key store from its AWS CloudHSM cluster. For an external key store, it disconnects the key store from
    #   # the external key store proxy that communicates with your external key manager. This operation doesn't return any data.
    #   # To verify that the custom key store is disconnected, use the <code>DescribeCustomKeyStores</code> operation.
    #
    #   resp = client.disconnect_custom_key_store({
    #     custom_key_store_id: "cks-1234567890abcdef0", # The ID of the custom key store.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.disconnect_custom_key_store({
    #     custom_key_store_id: "CustomKeyStoreIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/DisconnectCustomKeyStore AWS API Documentation
    #
    # @overload disconnect_custom_key_store(params = {})
    # @param [Hash] params ({})
    def disconnect_custom_key_store(params = {}, options = {})
      req = build_request(:disconnect_custom_key_store, params)
      req.send_request(options)
    end

    # Sets the key state of a KMS key to enabled. This allows you to use the
    # KMS key for [cryptographic operations][1].
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][2] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: No. You cannot perform this operation on a KMS
    # key in a different Amazon Web Services account.
    #
    # **Required permissions**: [kms:EnableKey][3] (key policy)
    #
    # **Related operations**: DisableKey
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][4].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-cryptography.html#cryptographic-operations
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Identifies the KMS key to enable.
    #
    #   Specify the key ID or key ARN of the KMS key.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To enable a KMS key
    #
    #   # The following example enables the specified KMS key.
    #
    #   resp = client.enable_key({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key to enable. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.enable_key({
    #     key_id: "KeyIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/EnableKey AWS API Documentation
    #
    # @overload enable_key(params = {})
    # @param [Hash] params ({})
    def enable_key(params = {}, options = {})
      req = build_request(:enable_key, params)
      req.send_request(options)
    end

    # Enables [automatic rotation of the key material][1] of the specified
    # symmetric encryption KMS key.
    #
    # By default, when you enable automatic rotation of a [customer managed
    # KMS key][2], KMS rotates the key material of the KMS key one year
    # (approximately 365 days) from the enable date and every year
    # thereafter. You can use the optional `RotationPeriodInDays` parameter
    # to specify a custom rotation period when you enable key rotation, or
    # you can use `RotationPeriodInDays` to modify the rotation period of a
    # key that you previously enabled automatic key rotation on.
    #
    # You can monitor rotation of the key material for your KMS keys in
    # CloudTrail and Amazon CloudWatch. To disable rotation of the key
    # material in a customer managed KMS key, use the DisableKeyRotation
    # operation. You can use the GetKeyRotationStatus operation to identify
    # any in progress rotations. You can use the ListKeyRotations operation
    # to view the details of completed rotations.
    #
    # Automatic key rotation is supported only on symmetric encryption KMS
    # keys. You cannot enable automatic rotation of [asymmetric KMS
    # keys][3], [HMAC KMS keys][4], KMS keys with [imported key
    # material][5], or KMS keys in a [custom key store][6]. To enable or
    # disable automatic rotation of a set of related [multi-Region keys][7],
    # set the property on the primary key.
    #
    # You cannot enable or disable automatic rotation of [Amazon Web
    # Services managed KMS keys][8]. KMS always rotates the key material of
    # Amazon Web Services managed keys every year. Rotation of [Amazon Web
    # Services owned KMS keys][9] is managed by the Amazon Web Services
    # service that owns the key.
    #
    # <note markdown="1"> In May 2022, KMS changed the rotation schedule for Amazon Web Services
    # managed keys from every three years (approximately 1,095 days) to
    # every year (approximately 365 days).
    #
    #  New Amazon Web Services managed keys are automatically rotated one
    # year after they are created, and approximately every year thereafter.
    #
    #  Existing Amazon Web Services managed keys are automatically rotated
    # one year after their most recent rotation, and every year thereafter.
    #
    #  </note>
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][10] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: No. You cannot perform this operation on a KMS
    # key in a different Amazon Web Services account.
    #
    # **Required permissions**: [kms:EnableKeyRotation][11] (key policy)
    #
    # **Related operations:**
    #
    # * DisableKeyRotation
    #
    # * GetKeyRotationStatus
    #
    # * ListKeyRotations
    #
    # * RotateKeyOnDemand
    #
    #   <note markdown="1"> You can perform on-demand (RotateKeyOnDemand) rotation of the key
    #   material in customer managed KMS keys, regardless of whether or not
    #   automatic key rotation is enabled.
    #
    #    </note>
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][12].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/rotating-keys-enable-disable.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-mgn-key
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/hmac.html
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html
    # [6]: https://docs.aws.amazon.com/kms/latest/developerguide/key-store-overview.html
    # [7]: https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html#multi-region-rotate
    # [8]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-key
    # [9]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-owned-key
    # [10]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [11]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [12]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Identifies a symmetric encryption KMS key. You cannot enable automatic
    #   rotation of [asymmetric KMS keys][1], [HMAC KMS keys][2], KMS keys
    #   with [imported key material][3], or KMS keys in a [custom key
    #   store][4]. To enable or disable automatic rotation of a set of related
    #   [multi-Region keys][5], set the property on the primary key.
    #
    #   Specify the key ID or key ARN of the KMS key.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/hmac.html
    #   [3]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html
    #   [4]: https://docs.aws.amazon.com/kms/latest/developerguide/key-store-overview.html
    #   [5]: https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html#multi-region-rotate
    #
    # @option params [Integer] :rotation_period_in_days
    #   Use this parameter to specify a custom period of time between each
    #   rotation date. If no value is specified, the default value is 365
    #   days.
    #
    #   The rotation period defines the number of days after you enable
    #   automatic key rotation that KMS will rotate your key material, and the
    #   number of days between each automatic rotation thereafter.
    #
    #   You can use the [ `kms:RotationPeriodInDays` ][1] condition key to
    #   further constrain the values that principals can specify in the
    #   `RotationPeriodInDays` parameter.
    #
    #
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/conditions-kms.html#conditions-kms-rotation-period-in-days
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To enable automatic rotation of key material
    #
    #   # The following example enables automatic rotation with a rotation period of 365 days for the specified KMS key.
    #
    #   resp = client.enable_key_rotation({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key whose key material will be automatically rotated. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #     rotation_period_in_days: 365, # The number of days between each rotation date. Specify a value between 9 and 2560. If no value is specified, the default value is 365 days.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.enable_key_rotation({
    #     key_id: "KeyIdType", # required
    #     rotation_period_in_days: 1,
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/EnableKeyRotation AWS API Documentation
    #
    # @overload enable_key_rotation(params = {})
    # @param [Hash] params ({})
    def enable_key_rotation(params = {}, options = {})
      req = build_request(:enable_key_rotation, params)
      req.send_request(options)
    end

    # Encrypts plaintext of up to 4,096 bytes using a KMS key. You can use a
    # symmetric or asymmetric KMS key with a `KeyUsage` of
    # `ENCRYPT_DECRYPT`.
    #
    # You can use this operation to encrypt small amounts of arbitrary data,
    # such as a personal identifier or database password, or other sensitive
    # information. You don't need to use the `Encrypt` operation to encrypt
    # a data key. The GenerateDataKey and GenerateDataKeyPair operations
    # return a plaintext data key and an encrypted copy of that data key.
    #
    # If you use a symmetric encryption KMS key, you can use an encryption
    # context to add additional security to your encryption operation. If
    # you specify an `EncryptionContext` when encrypting data, you must
    # specify the same encryption context (a case-sensitive exact match)
    # when decrypting the data. Otherwise, the request to decrypt fails with
    # an `InvalidCiphertextException`. For more information, see [Encryption
    # Context][1] in the *Key Management Service Developer Guide*.
    #
    # If you specify an asymmetric KMS key, you must also specify the
    # encryption algorithm. The algorithm must be compatible with the KMS
    # key spec.
    #
    # When you use an asymmetric KMS key to encrypt or reencrypt data, be
    # sure to record the KMS key and encryption algorithm that you choose.
    # You will be required to provide the same KMS key and encryption
    # algorithm when you decrypt the data. If the KMS key and algorithm do
    # not match the values used to encrypt the data, the decrypt operation
    # fails.
    #
    #  You are not required to supply the key ID and encryption algorithm
    # when you decrypt with symmetric encryption KMS keys because KMS stores
    # this information in the ciphertext blob. KMS cannot store metadata in
    # ciphertext generated with asymmetric keys. The standard format for
    # asymmetric key ciphertext does not include configurable fields.
    #
    # The maximum size of the data that you can encrypt varies with the type
    # of KMS key and the encryption algorithm that you choose.
    #
    # * Symmetric encryption KMS keys
    #
    #   * `SYMMETRIC_DEFAULT`: 4096 bytes
    #
    #   ^
    # * `RSA_2048`
    #
    #   * `RSAES_OAEP_SHA_1`: 214 bytes
    #
    #   * `RSAES_OAEP_SHA_256`: 190 bytes
    # * `RSA_3072`
    #
    #   * `RSAES_OAEP_SHA_1`: 342 bytes
    #
    #   * `RSAES_OAEP_SHA_256`: 318 bytes
    # * `RSA_4096`
    #
    #   * `RSAES_OAEP_SHA_1`: 470 bytes
    #
    #   * `RSAES_OAEP_SHA_256`: 446 bytes
    # * `SM2PKE`: 1024 bytes (China Regions only)
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][2] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: Yes. To perform this operation with a KMS key
    # in a different Amazon Web Services account, specify the key ARN or
    # alias ARN in the value of the `KeyId` parameter.
    #
    # **Required permissions**: [kms:Encrypt][3] (key policy)
    #
    # **Related operations:**
    #
    # * Decrypt
    #
    # * GenerateDataKey
    #
    # * GenerateDataKeyPair
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][4].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/encrypt_context.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Identifies the KMS key to use in the encryption operation. The KMS key
    #   must have a `KeyUsage` of `ENCRYPT_DECRYPT`. To find the `KeyUsage` of
    #   a KMS key, use the DescribeKey operation.
    #
    #   To specify a KMS key, use its key ID, key ARN, alias name, or alias
    #   ARN. When using an alias name, prefix it with `"alias/"`. To specify a
    #   KMS key in a different Amazon Web Services account, you must use the
    #   key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey. To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [required, String, StringIO, File] :plaintext
    #   Data to be encrypted.
    #
    # @option params [Hash<String,String>] :encryption_context
    #   Specifies the encryption context that will be used to encrypt the
    #   data. An encryption context is valid only for [cryptographic
    #   operations][1] with a symmetric encryption KMS key. The standard
    #   asymmetric encryption algorithms and HMAC algorithms that KMS uses do
    #   not support an encryption context.
    #
    #   Do not include confidential or sensitive information in this field.
    #   This field may be displayed in plaintext in CloudTrail logs and other
    #   output.
    #
    #   An *encryption context* is a collection of non-secret key-value pairs
    #   that represent additional authenticated data. When you use an
    #   encryption context to encrypt data, you must specify the same (an
    #   exact case-sensitive match) encryption context to decrypt the data. An
    #   encryption context is supported only on operations with symmetric
    #   encryption KMS keys. On operations with symmetric encryption KMS keys,
    #   an encryption context is optional, but it is strongly recommended.
    #
    #   For more information, see [Encryption context][2] in the *Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-cryptography.html#cryptographic-operations
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/encrypt_context.html
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   Use a grant token when your permission to call this operation comes
    #   from a new grant that has not yet achieved *eventual consistency*. For
    #   more information, see [Grant token][1] and [Using a grant token][2] in
    #   the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html#grant_token
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/using-grant-token.html
    #
    # @option params [String] :encryption_algorithm
    #   Specifies the encryption algorithm that KMS will use to encrypt the
    #   plaintext message. The algorithm must be compatible with the KMS key
    #   that you specify.
    #
    #   This parameter is required only for asymmetric KMS keys. The default
    #   value, `SYMMETRIC_DEFAULT`, is the algorithm used for symmetric
    #   encryption KMS keys. If you are using an asymmetric KMS key, we
    #   recommend RSAES\_OAEP\_SHA\_256.
    #
    #   The SM2PKE algorithm is only available in China Regions.
    #
    # @option params [Boolean] :dry_run
    #   Checks if your request will succeed. `DryRun` is an optional
    #   parameter.
    #
    #   To learn more about how to use this parameter, see [Testing your
    #   permissions][1] in the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/testing-permissions.html
    #
    # @return [Types::EncryptResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::EncryptResponse#ciphertext_blob #ciphertext_blob} => String
    #   * {Types::EncryptResponse#key_id #key_id} => String
    #   * {Types::EncryptResponse#encryption_algorithm #encryption_algorithm} => String
    #
    #
    # @example Example: To encrypt data with a symmetric encryption KMS key
    #
    #   # The following example encrypts data with the specified symmetric encryption KMS key.
    #
    #   resp = client.encrypt({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key to use for encryption. You can use the key ID or Amazon Resource Name (ARN) of the KMS key, or the name or ARN of an alias that refers to the KMS key.
    #     plaintext: "<binary data>", # The data to encrypt.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     ciphertext_blob: "<binary data>", # The encrypted data (ciphertext).
    #     encryption_algorithm: "SYMMETRIC_DEFAULT", # The encryption algorithm that was used in the operation. For symmetric encryption keys, the encryption algorithm is always SYMMETRIC_DEFAULT.
    #     key_id: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The ARN of the KMS key that was used to encrypt the data.
    #   }
    #
    # @example Example: To encrypt data with an asymmetric encryption KMS key
    #
    #   # The following example encrypts data with the specified RSA asymmetric KMS key. When you encrypt with an asymmetric key,
    #   # you must specify the encryption algorithm.
    #
    #   resp = client.encrypt({
    #     encryption_algorithm: "RSAES_OAEP_SHA_256", # The encryption algorithm to use in the operation.
    #     key_id: "0987dcba-09fe-87dc-65ba-ab0987654321", # The identifier of the KMS key to use for encryption. You can use the key ID or Amazon Resource Name (ARN) of the KMS key, or the name or ARN of an alias that refers to the KMS key.
    #     plaintext: "<binary data>", # The data to encrypt.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     ciphertext_blob: "<binary data>", # The encrypted data (ciphertext).
    #     encryption_algorithm: "RSAES_OAEP_SHA_256", # The encryption algorithm that was used in the operation.
    #     key_id: "arn:aws:kms:us-west-2:111122223333:key/0987dcba-09fe-87dc-65ba-ab0987654321", # The ARN of the KMS key that was used to encrypt the data.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.encrypt({
    #     key_id: "KeyIdType", # required
    #     plaintext: "data", # required
    #     encryption_context: {
    #       "EncryptionContextKey" => "EncryptionContextValue",
    #     },
    #     grant_tokens: ["GrantTokenType"],
    #     encryption_algorithm: "SYMMETRIC_DEFAULT", # accepts SYMMETRIC_DEFAULT, RSAES_OAEP_SHA_1, RSAES_OAEP_SHA_256, SM2PKE
    #     dry_run: false,
    #   })
    #
    # @example Response structure
    #
    #   resp.ciphertext_blob #=> String
    #   resp.key_id #=> String
    #   resp.encryption_algorithm #=> String, one of "SYMMETRIC_DEFAULT", "RSAES_OAEP_SHA_1", "RSAES_OAEP_SHA_256", "SM2PKE"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/Encrypt AWS API Documentation
    #
    # @overload encrypt(params = {})
    # @param [Hash] params ({})
    def encrypt(params = {}, options = {})
      req = build_request(:encrypt, params)
      req.send_request(options)
    end

    # Returns a unique symmetric data key for use outside of KMS. This
    # operation returns a plaintext copy of the data key and a copy that is
    # encrypted under a symmetric encryption KMS key that you specify. The
    # bytes in the plaintext key are random; they are not related to the
    # caller or the KMS key. You can use the plaintext key to encrypt your
    # data outside of KMS and store the encrypted data key with the
    # encrypted data.
    #
    # To generate a data key, specify the symmetric encryption KMS key that
    # will be used to encrypt the data key. You cannot use an asymmetric KMS
    # key to encrypt data keys. To get the type of your KMS key, use the
    # DescribeKey operation.
    #
    # You must also specify the length of the data key. Use either the
    # `KeySpec` or `NumberOfBytes` parameters (but not both). For 128-bit
    # and 256-bit data keys, use the `KeySpec` parameter.
    #
    # To generate a 128-bit SM4 data key (China Regions only), specify a
    # `KeySpec` value of `AES_128` or a `NumberOfBytes` value of `16`. The
    # symmetric encryption key used in China Regions to encrypt your data
    # key is an SM4 encryption key.
    #
    # To get only an encrypted copy of the data key, use
    # GenerateDataKeyWithoutPlaintext. To generate an asymmetric data key
    # pair, use the GenerateDataKeyPair or
    # GenerateDataKeyPairWithoutPlaintext operation. To get a
    # cryptographically secure random byte string, use GenerateRandom.
    #
    # You can use an optional encryption context to add additional security
    # to the encryption operation. If you specify an `EncryptionContext`,
    # you must specify the same encryption context (a case-sensitive exact
    # match) when decrypting the encrypted data key. Otherwise, the request
    # to decrypt fails with an `InvalidCiphertextException`. For more
    # information, see [Encryption Context][1] in the *Key Management
    # Service Developer Guide*.
    #
    # `GenerateDataKey` also supports [Amazon Web Services Nitro
    # Enclaves][2], which provide an isolated compute environment in Amazon
    # EC2. To call `GenerateDataKey` for an Amazon Web Services Nitro
    # enclave or NitroTPM, use the [Amazon Web Services Nitro Enclaves
    # SDK][3] or any Amazon Web Services SDK. Use the `Recipient` parameter
    # to provide the attestation document for the attested environment.
    # `GenerateDataKey` returns a copy of the data key encrypted under the
    # specified KMS key, as usual. But instead of a plaintext copy of the
    # data key, the response includes a copy of the data key encrypted under
    # the public key from the attestation document
    # (`CiphertextForRecipient`). For information about the interaction
    # between KMS and Amazon Web Services Nitro Enclaves or Amazon Web
    # Services NitroTPM, see [Cryptographic attestation support in KMS][4]
    # in the *Key Management Service Developer Guide*.
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][5] in the *Key
    # Management Service Developer Guide*.
    #
    # **How to use your data key**
    #
    # We recommend that you use the following pattern to encrypt data
    # locally in your application. You can write your own code or use a
    # client-side encryption library, such as the [Amazon Web Services
    # Encryption SDK][6], the [Amazon DynamoDB Encryption Client][7], or
    # [Amazon S3 client-side encryption][8] to do these tasks for you.
    #
    # To encrypt data outside of KMS:
    #
    # 1.  Use the `GenerateDataKey` operation to get a data key.
    #
    # 2.  Use the plaintext data key (in the `Plaintext` field of the
    #     response) to encrypt your data outside of KMS. Then erase the
    #     plaintext data key from memory.
    #
    # 3.  Store the encrypted data key (in the `CiphertextBlob` field of the
    #     response) with the encrypted data.
    #
    # To decrypt data outside of KMS:
    #
    # 1.  Use the Decrypt operation to decrypt the encrypted data key. The
    #     operation returns a plaintext copy of the data key.
    #
    # 2.  Use the plaintext data key to decrypt data outside of KMS, then
    #     erase the plaintext data key from memory.
    #
    # **Cross-account use**: Yes. To perform this operation with a KMS key
    # in a different Amazon Web Services account, specify the key ARN or
    # alias ARN in the value of the `KeyId` parameter.
    #
    # **Required permissions**: [kms:GenerateDataKey][9] (key policy)
    #
    # **Related operations:**
    #
    # * Decrypt
    #
    # * Encrypt
    #
    # * GenerateDataKeyPair
    #
    # * GenerateDataKeyPairWithoutPlaintext
    #
    # * GenerateDataKeyWithoutPlaintext
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][10].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/encrypt_context.html
    # [2]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/nitro-enclave.html
    # [3]: https://docs.aws.amazon.com/enclaves/latest/user/developing-applications.html#sdk
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/cryptographic-attestation.html
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [6]: https://docs.aws.amazon.com/encryption-sdk/latest/developer-guide/
    # [7]: https://docs.aws.amazon.com/dynamodb-encryption-client/latest/devguide/
    # [8]: https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingClientSideEncryption.html
    # [9]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [10]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Specifies the symmetric encryption KMS key that encrypts the data key.
    #   You cannot specify an asymmetric KMS key or a KMS key in a custom key
    #   store. To get the type and origin of your KMS key, use the DescribeKey
    #   operation.
    #
    #   To specify a KMS key, use its key ID, key ARN, alias name, or alias
    #   ARN. When using an alias name, prefix it with `"alias/"`. To specify a
    #   KMS key in a different Amazon Web Services account, you must use the
    #   key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey. To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [Hash<String,String>] :encryption_context
    #   Specifies the encryption context that will be used when encrypting the
    #   data key.
    #
    #   Do not include confidential or sensitive information in this field.
    #   This field may be displayed in plaintext in CloudTrail logs and other
    #   output.
    #
    #   An *encryption context* is a collection of non-secret key-value pairs
    #   that represent additional authenticated data. When you use an
    #   encryption context to encrypt data, you must specify the same (an
    #   exact case-sensitive match) encryption context to decrypt the data. An
    #   encryption context is supported only on operations with symmetric
    #   encryption KMS keys. On operations with symmetric encryption KMS keys,
    #   an encryption context is optional, but it is strongly recommended.
    #
    #   For more information, see [Encryption context][1] in the *Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/encrypt_context.html
    #
    # @option params [Integer] :number_of_bytes
    #   Specifies the length of the data key in bytes. For example, use the
    #   value 64 to generate a 512-bit data key (64 bytes is 512 bits). For
    #   128-bit (16-byte) and 256-bit (32-byte) data keys, use the `KeySpec`
    #   parameter.
    #
    #   You must specify either the `KeySpec` or the `NumberOfBytes` parameter
    #   (but not both) in every `GenerateDataKey` request.
    #
    # @option params [String] :key_spec
    #   Specifies the length of the data key. Use `AES_128` to generate a
    #   128-bit symmetric key, or `AES_256` to generate a 256-bit symmetric
    #   key.
    #
    #   You must specify either the `KeySpec` or the `NumberOfBytes` parameter
    #   (but not both) in every `GenerateDataKey` request.
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   Use a grant token when your permission to call this operation comes
    #   from a new grant that has not yet achieved *eventual consistency*. For
    #   more information, see [Grant token][1] and [Using a grant token][2] in
    #   the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html#grant_token
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/using-grant-token.html
    #
    # @option params [Types::RecipientInfo] :recipient
    #   A signed [attestation document][1] from an Amazon Web Services Nitro
    #   enclave or NitroTPM, and the encryption algorithm to use with the
    #   public key in the attestation document. The only valid encryption
    #   algorithm is `RSAES_OAEP_SHA_256`.
    #
    #   This parameter supports the [Amazon Web Services Nitro Enclaves
    #   SDK][2] or any Amazon Web Services SDK for Amazon Web Services Nitro
    #   Enclaves. It supports any Amazon Web Services SDK for Amazon Web
    #   Services NitroTPM.
    #
    #   When you use this parameter, instead of returning the plaintext data
    #   key, KMS encrypts the plaintext data key under the public key in the
    #   attestation document, and returns the resulting ciphertext in the
    #   `CiphertextForRecipient` field in the response. This ciphertext can be
    #   decrypted only with the private key in the enclave. The
    #   `CiphertextBlob` field in the response contains a copy of the data key
    #   encrypted under the KMS key specified by the `KeyId` parameter. The
    #   `Plaintext` field in the response is null or empty.
    #
    #   For information about the interaction between KMS and Amazon Web
    #   Services Nitro Enclaves or Amazon Web Services NitroTPM, see
    #   [Cryptographic attestation support in KMS][3] in the *Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/nitro-enclave-how.html#term-attestdoc
    #   [2]: https://docs.aws.amazon.com/enclaves/latest/user/developing-applications.html#sdk
    #   [3]: https://docs.aws.amazon.com/kms/latest/developerguide/cryptographic-attestation.html
    #
    # @option params [Boolean] :dry_run
    #   Checks if your request will succeed. `DryRun` is an optional
    #   parameter.
    #
    #   To learn more about how to use this parameter, see [Testing your
    #   permissions][1] in the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/testing-permissions.html
    #
    # @return [Types::GenerateDataKeyResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GenerateDataKeyResponse#ciphertext_blob #ciphertext_blob} => String
    #   * {Types::GenerateDataKeyResponse#plaintext #plaintext} => String
    #   * {Types::GenerateDataKeyResponse#key_id #key_id} => String
    #   * {Types::GenerateDataKeyResponse#ciphertext_for_recipient #ciphertext_for_recipient} => String
    #   * {Types::GenerateDataKeyResponse#key_material_id #key_material_id} => String
    #
    #
    # @example Example: To generate a data key
    #
    #   # The following example generates a 256-bit symmetric data encryption key (data key) in two formats. One is the
    #   # unencrypted (plainext) data key, and the other is the data key encrypted with the specified KMS key.
    #
    #   resp = client.generate_data_key({
    #     key_id: "alias/ExampleAlias", # The identifier of the KMS key to use to encrypt the data key. You can use the key ID or Amazon Resource Name (ARN) of the KMS key, or the name or ARN of an alias that refers to the KMS key.
    #     key_spec: "AES_256", # Specifies the type of data key to return.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     ciphertext_blob: "<binary data>", # The encrypted data key.
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The ARN of the KMS key that was used to encrypt the data key.
    #     key_material_id: "0b7fd7ddbac6eef27907413567cad8c810e2883dc8a7534067a82ee1142fc1e6", # The identifier of the key material used to encrypt the data key.
    #     plaintext: "<binary data>", # The unencrypted (plaintext) data key.
    #   }
    #
    # @example Example: To generate a data key for a Nitro enclave or NitroTPM
    #
    #   # The following example includes the Recipient parameter with a signed attestation document from an AWS Nitro enclave or
    #   # NitroTPM. Instead of returning a copy of the data key encrypted by the KMS key and a plaintext copy of the data key,
    #   # GenerateDataKey returns one copy of the data key encrypted by the KMS key (CiphertextBlob) and one copy of the data key
    #   # encrypted by the public key from the attestation document (CiphertextForRecipient). The operation doesn't return a
    #   # plaintext data key. 
    #
    #   resp = client.generate_data_key({
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # Identifies the KMS key used to encrypt the encrypted data key (CiphertextBlob)
    #     key_spec: "AES_256", # Specifies the type of data key to return
    #     recipient: {
    #       attestation_document: "<attestation document>", 
    #       key_encryption_algorithm: "RSAES_OAEP_SHA_256", 
    #     }, # Specifies the attestation document from the Nitro enclave or NitroTPM and the encryption algorithm to use with the public key from the attestation document
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     ciphertext_blob: "<binary data>", # The data key encrypted by the specified KMS key
    #     ciphertext_for_recipient: "<binary data>", # The plaintext data key encrypted by the public key from the attestation document
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The KMS key used to encrypt the CiphertextBlob (encrypted data key)
    #     plaintext: "", # This field is null or empty
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.generate_data_key({
    #     key_id: "KeyIdType", # required
    #     encryption_context: {
    #       "EncryptionContextKey" => "EncryptionContextValue",
    #     },
    #     number_of_bytes: 1,
    #     key_spec: "AES_256", # accepts AES_256, AES_128
    #     grant_tokens: ["GrantTokenType"],
    #     recipient: {
    #       key_encryption_algorithm: "RSAES_OAEP_SHA_256", # accepts RSAES_OAEP_SHA_256
    #       attestation_document: "data",
    #     },
    #     dry_run: false,
    #   })
    #
    # @example Response structure
    #
    #   resp.ciphertext_blob #=> String
    #   resp.plaintext #=> String
    #   resp.key_id #=> String
    #   resp.ciphertext_for_recipient #=> String
    #   resp.key_material_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GenerateDataKey AWS API Documentation
    #
    # @overload generate_data_key(params = {})
    # @param [Hash] params ({})
    def generate_data_key(params = {}, options = {})
      req = build_request(:generate_data_key, params)
      req.send_request(options)
    end

    # Returns a unique asymmetric data key pair for use outside of KMS. This
    # operation returns a plaintext public key, a plaintext private key, and
    # a copy of the private key that is encrypted under the symmetric
    # encryption KMS key you specify. You can use the data key pair to
    # perform asymmetric cryptography and implement digital signatures
    # outside of KMS. The bytes in the keys are random; they are not related
    # to the caller or to the KMS key that is used to encrypt the private
    # key.
    #
    # You can use the public key that `GenerateDataKeyPair` returns to
    # encrypt data or verify a signature outside of KMS. Then, store the
    # encrypted private key with the data. When you are ready to decrypt
    # data or sign a message, you can use the Decrypt operation to decrypt
    # the encrypted private key.
    #
    # To generate a data key pair, you must specify a symmetric encryption
    # KMS key to encrypt the private key in a data key pair. You cannot use
    # an asymmetric KMS key or a KMS key in a custom key store. To get the
    # type and origin of your KMS key, use the DescribeKey operation.
    #
    # Use the `KeyPairSpec` parameter to choose an RSA or Elliptic Curve
    # (ECC) data key pair. In China Regions, you can also choose an SM2 data
    # key pair. KMS recommends that you use ECC key pairs for signing, and
    # use RSA and SM2 key pairs for either encryption or signing, but not
    # both. However, KMS cannot enforce any restrictions on the use of data
    # key pairs outside of KMS.
    #
    # If you are using the data key pair to encrypt data, or for any
    # operation where you don't immediately need a private key, consider
    # using the GenerateDataKeyPairWithoutPlaintext operation.
    # `GenerateDataKeyPairWithoutPlaintext` returns a plaintext public key
    # and an encrypted private key, but omits the plaintext private key that
    # you need only to decrypt ciphertext or sign a message. Later, when you
    # need to decrypt the data or sign a message, use the Decrypt operation
    # to decrypt the encrypted private key in the data key pair.
    #
    # `GenerateDataKeyPair` returns a unique data key pair for each request.
    # The bytes in the keys are random; they are not related to the caller
    # or the KMS key that is used to encrypt the private key. The public key
    # is a DER-encoded X.509 SubjectPublicKeyInfo, as specified in [RFC
    # 5280][1]. The private key is a DER-encoded PKCS8 PrivateKeyInfo, as
    # specified in [RFC 5958][2].
    #
    # `GenerateDataKeyPair` also supports [Amazon Web Services Nitro
    # Enclaves][3], which provide an isolated compute environment in Amazon
    # EC2. To call `GenerateDataKeyPair` for an Amazon Web Services Nitro
    # enclave or NitroTPM, use the [Amazon Web Services Nitro Enclaves
    # SDK][4] or any Amazon Web Services SDK. Use the `Recipient` parameter
    # to provide the attestation document for the attested environment.
    # `GenerateDataKeyPair` returns the public data key and a copy of the
    # private data key encrypted under the specified KMS key, as usual. But
    # instead of a plaintext copy of the private data key
    # (`PrivateKeyPlaintext`), the response includes a copy of the private
    # data key encrypted under the public key from the attestation document
    # (`CiphertextForRecipient`). For information about the interaction
    # between KMS and Amazon Web Services Nitro Enclaves or Amazon Web
    # Services NitroTPM, see [Cryptographic attestation support in KMS][5]
    # in the *Key Management Service Developer Guide*.
    #
    # You can use an optional encryption context to add additional security
    # to the encryption operation. If you specify an `EncryptionContext`,
    # you must specify the same encryption context (a case-sensitive exact
    # match) when decrypting the encrypted data key. Otherwise, the request
    # to decrypt fails with an `InvalidCiphertextException`. For more
    # information, see [Encryption Context][6] in the *Key Management
    # Service Developer Guide*.
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][7] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: Yes. To perform this operation with a KMS key
    # in a different Amazon Web Services account, specify the key ARN or
    # alias ARN in the value of the `KeyId` parameter.
    #
    # **Required permissions**: [kms:GenerateDataKeyPair][8] (key policy)
    #
    # **Related operations:**
    #
    # * Decrypt
    #
    # * Encrypt
    #
    # * GenerateDataKey
    #
    # * GenerateDataKeyPairWithoutPlaintext
    #
    # * GenerateDataKeyWithoutPlaintext
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][9].
    #
    #
    #
    # [1]: https://tools.ietf.org/html/rfc5280
    # [2]: https://tools.ietf.org/html/rfc5958
    # [3]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/nitro-enclave.html
    # [4]: https://docs.aws.amazon.com/enclaves/latest/user/developing-applications.html#sdk
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/cryptographic-attestation.html
    # [6]: https://docs.aws.amazon.com/kms/latest/developerguide/encrypt_context.html
    # [7]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [8]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [9]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [Hash<String,String>] :encryption_context
    #   Specifies the encryption context that will be used when encrypting the
    #   private key in the data key pair.
    #
    #   Do not include confidential or sensitive information in this field.
    #   This field may be displayed in plaintext in CloudTrail logs and other
    #   output.
    #
    #   An *encryption context* is a collection of non-secret key-value pairs
    #   that represent additional authenticated data. When you use an
    #   encryption context to encrypt data, you must specify the same (an
    #   exact case-sensitive match) encryption context to decrypt the data. An
    #   encryption context is supported only on operations with symmetric
    #   encryption KMS keys. On operations with symmetric encryption KMS keys,
    #   an encryption context is optional, but it is strongly recommended.
    #
    #   For more information, see [Encryption context][1] in the *Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/encrypt_context.html
    #
    # @option params [required, String] :key_id
    #   Specifies the symmetric encryption KMS key that encrypts the private
    #   key in the data key pair. You cannot specify an asymmetric KMS key or
    #   a KMS key in a custom key store. To get the type and origin of your
    #   KMS key, use the DescribeKey operation.
    #
    #   To specify a KMS key, use its key ID, key ARN, alias name, or alias
    #   ARN. When using an alias name, prefix it with `"alias/"`. To specify a
    #   KMS key in a different Amazon Web Services account, you must use the
    #   key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey. To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [required, String] :key_pair_spec
    #   Determines the type of data key pair that is generated.
    #
    #   The KMS rule that restricts the use of asymmetric RSA and SM2 KMS keys
    #   to encrypt and decrypt or to sign and verify (but not both), the rule
    #   that permits you to use ECC KMS keys only to sign and verify, and the
    #   rule that permits you to use ML-DSA key pairs to sign and verify only
    #   are not effective on data key pairs, which are used outside of KMS.
    #   The SM2 key spec is only available in China Regions.
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   Use a grant token when your permission to call this operation comes
    #   from a new grant that has not yet achieved *eventual consistency*. For
    #   more information, see [Grant token][1] and [Using a grant token][2] in
    #   the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html#grant_token
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/using-grant-token.html
    #
    # @option params [Types::RecipientInfo] :recipient
    #   A signed [attestation document][1] from an Amazon Web Services Nitro
    #   enclave or NitroTPM, and the encryption algorithm to use with the
    #   public key in the attestation document. The only valid encryption
    #   algorithm is `RSAES_OAEP_SHA_256`.
    #
    #   This parameter only supports attestation documents for Amazon Web
    #   Services Nitro Enclaves or Amazon Web Services NitroTPM. To call
    #   GenerateDataKeyPair generate an attestation document use either
    #   [Amazon Web Services Nitro Enclaves SDK][2] for an Amazon Web Services
    #   Nitro Enclaves or [Amazon Web Services NitroTPM tools][3] for Amazon
    #   Web Services NitroTPM. Then use the Recipient parameter from any
    #   Amazon Web Services SDK to provide the attestation document for the
    #   attested environment.
    #
    #   When you use this parameter, instead of returning a plaintext copy of
    #   the private data key, KMS encrypts the plaintext private data key
    #   under the public key in the attestation document, and returns the
    #   resulting ciphertext in the `CiphertextForRecipient` field in the
    #   response. This ciphertext can be decrypted only with the private key
    #   in the attested environment. The `CiphertextBlob` field in the
    #   response contains a copy of the private data key encrypted under the
    #   KMS key specified by the `KeyId` parameter. The `PrivateKeyPlaintext`
    #   field in the response is null or empty.
    #
    #   For information about the interaction between KMS and Amazon Web
    #   Services Nitro Enclaves or Amazon Web Services NitroTPM, see
    #   [Cryptographic attestation support in KMS][4] in the *Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/nitro-enclave-how.html#term-attestdoc
    #   [2]: https://docs.aws.amazon.com/enclaves/latest/user/developing-applications.html#sdk
    #   [3]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/attestation-get-doc.html
    #   [4]: https://docs.aws.amazon.com/kms/latest/developerguide/cryptographic-attestation.html
    #
    # @option params [Boolean] :dry_run
    #   Checks if your request will succeed. `DryRun` is an optional
    #   parameter.
    #
    #   To learn more about how to use this parameter, see [Testing your
    #   permissions][1] in the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/testing-permissions.html
    #
    # @return [Types::GenerateDataKeyPairResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GenerateDataKeyPairResponse#private_key_ciphertext_blob #private_key_ciphertext_blob} => String
    #   * {Types::GenerateDataKeyPairResponse#private_key_plaintext #private_key_plaintext} => String
    #   * {Types::GenerateDataKeyPairResponse#public_key #public_key} => String
    #   * {Types::GenerateDataKeyPairResponse#key_id #key_id} => String
    #   * {Types::GenerateDataKeyPairResponse#key_pair_spec #key_pair_spec} => String
    #   * {Types::GenerateDataKeyPairResponse#ciphertext_for_recipient #ciphertext_for_recipient} => String
    #   * {Types::GenerateDataKeyPairResponse#key_material_id #key_material_id} => String
    #
    #
    # @example Example: To generate an RSA key pair for encryption and decryption
    #
    #   # This example generates an RSA data key pair for encryption and decryption. The operation returns a plaintext public key
    #   # and private key, and a copy of the private key that is encrypted under a symmetric encryption KMS key that you specify.
    #
    #   resp = client.generate_data_key_pair({
    #     key_id: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The key ID of the symmetric encryption KMS key that encrypts the private RSA key in the data key pair.
    #     key_pair_spec: "RSA_3072", # The requested key spec of the RSA data key pair.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_id: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The key ARN of the symmetric encryption KMS key that was used to encrypt the private key.
    #     key_material_id: "0b7fd7ddbac6eef27907413567cad8c810e2883dc8a7534067a82ee1142fc1e6", # The identifier of the key material used to encrypt the private key.
    #     key_pair_spec: "RSA_3072", # The actual key spec of the RSA data key pair.
    #     private_key_ciphertext_blob: "<binary data>", # The encrypted private key of the RSA data key pair.
    #     private_key_plaintext: "<binary data>", # The plaintext private key of the RSA data key pair.
    #     public_key: "<binary data>", # The public key (plaintext) of the RSA data key pair.
    #   }
    #
    # @example Example: To generate a data key pair for a Nitro enclave or NitroTPM
    #
    #   # The following example includes the Recipient parameter with a signed attestation document from an AWS Nitro enclave or
    #   # NitroTPM. Instead of returning a plaintext copy of the private data key, GenerateDataKeyPair returns a copy of the
    #   # private data key encrypted by the public key from the attestation document (CiphertextForRecipient). It returns the
    #   # public data key (PublicKey) and a copy of private data key encrypted under the specified KMS key
    #   # (PrivateKeyCiphertextBlob), as usual, but plaintext private data key field (PrivateKeyPlaintext) is null or empty. 
    #
    #   resp = client.generate_data_key_pair({
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The key ID of the symmetric encryption KMS key that encrypts the private RSA key in the data key pair.
    #     key_pair_spec: "RSA_3072", # The requested key spec of the RSA data key pair.
    #     recipient: {
    #       attestation_document: "<attestation document>", 
    #       key_encryption_algorithm: "RSAES_OAEP_SHA_256", 
    #     }, # Specifies the attestation document from the Nitro enclave or NitroTPM and the encryption algorithm to use with the public key from the attestation document.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     ciphertext_for_recipient: "<binary data>", # The private key of the RSA data key pair encrypted by the public key from the attestation document
    #     key_id: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The key ARN of the symmetric encryption KMS key that was used to encrypt the PrivateKeyCiphertextBlob.
    #     key_material_id: "0b7fd7ddbac6eef27907413567cad8c810e2883dc8a7534067a82ee1142fc1e6", # The identifier of the key material used to encrypt the private key.
    #     key_pair_spec: "RSA_3072", # The actual key spec of the RSA data key pair.
    #     private_key_ciphertext_blob: "<binary data>", # The private key of the RSA data key pair encrypted by the KMS key.
    #     private_key_plaintext: "", # This field is null or empty
    #     public_key: "<binary data>", # The public key (plaintext) of the RSA data key pair.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.generate_data_key_pair({
    #     encryption_context: {
    #       "EncryptionContextKey" => "EncryptionContextValue",
    #     },
    #     key_id: "KeyIdType", # required
    #     key_pair_spec: "RSA_2048", # required, accepts RSA_2048, RSA_3072, RSA_4096, ECC_NIST_P256, ECC_NIST_P384, ECC_NIST_P521, ECC_SECG_P256K1, SM2, ECC_NIST_EDWARDS25519
    #     grant_tokens: ["GrantTokenType"],
    #     recipient: {
    #       key_encryption_algorithm: "RSAES_OAEP_SHA_256", # accepts RSAES_OAEP_SHA_256
    #       attestation_document: "data",
    #     },
    #     dry_run: false,
    #   })
    #
    # @example Response structure
    #
    #   resp.private_key_ciphertext_blob #=> String
    #   resp.private_key_plaintext #=> String
    #   resp.public_key #=> String
    #   resp.key_id #=> String
    #   resp.key_pair_spec #=> String, one of "RSA_2048", "RSA_3072", "RSA_4096", "ECC_NIST_P256", "ECC_NIST_P384", "ECC_NIST_P521", "ECC_SECG_P256K1", "SM2", "ECC_NIST_EDWARDS25519"
    #   resp.ciphertext_for_recipient #=> String
    #   resp.key_material_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GenerateDataKeyPair AWS API Documentation
    #
    # @overload generate_data_key_pair(params = {})
    # @param [Hash] params ({})
    def generate_data_key_pair(params = {}, options = {})
      req = build_request(:generate_data_key_pair, params)
      req.send_request(options)
    end

    # Returns a unique asymmetric data key pair for use outside of KMS. This
    # operation returns a plaintext public key and a copy of the private key
    # that is encrypted under the symmetric encryption KMS key you specify.
    # Unlike GenerateDataKeyPair, this operation does not return a plaintext
    # private key. The bytes in the keys are random; they are not related to
    # the caller or to the KMS key that is used to encrypt the private key.
    #
    # You can use the public key that `GenerateDataKeyPairWithoutPlaintext`
    # returns to encrypt data or verify a signature outside of KMS. Then,
    # store the encrypted private key with the data. When you are ready to
    # decrypt data or sign a message, you can use the Decrypt operation to
    # decrypt the encrypted private key.
    #
    # To generate a data key pair, you must specify a symmetric encryption
    # KMS key to encrypt the private key in a data key pair. You cannot use
    # an asymmetric KMS key or a KMS key in a custom key store. To get the
    # type and origin of your KMS key, use the DescribeKey operation.
    #
    # Use the `KeyPairSpec` parameter to choose an RSA or Elliptic Curve
    # (ECC) data key pair. In China Regions, you can also choose an SM2 data
    # key pair. KMS recommends that you use ECC key pairs for signing, and
    # use RSA and SM2 key pairs for either encryption or signing, but not
    # both. However, KMS cannot enforce any restrictions on the use of data
    # key pairs outside of KMS.
    #
    # `GenerateDataKeyPairWithoutPlaintext` returns a unique data key pair
    # for each request. The bytes in the key are not related to the caller
    # or KMS key that is used to encrypt the private key. The public key is
    # a DER-encoded X.509 SubjectPublicKeyInfo, as specified in [RFC
    # 5280][1].
    #
    # You can use an optional encryption context to add additional security
    # to the encryption operation. If you specify an `EncryptionContext`,
    # you must specify the same encryption context (a case-sensitive exact
    # match) when decrypting the encrypted data key. Otherwise, the request
    # to decrypt fails with an `InvalidCiphertextException`. For more
    # information, see [Encryption Context][2] in the *Key Management
    # Service Developer Guide*.
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][3] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: Yes. To perform this operation with a KMS key
    # in a different Amazon Web Services account, specify the key ARN or
    # alias ARN in the value of the `KeyId` parameter.
    #
    # **Required permissions**: [kms:GenerateDataKeyPairWithoutPlaintext][4]
    # (key policy)
    #
    # **Related operations:**
    #
    # * Decrypt
    #
    # * Encrypt
    #
    # * GenerateDataKey
    #
    # * GenerateDataKeyPair
    #
    # * GenerateDataKeyWithoutPlaintext
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][5].
    #
    #
    #
    # [1]: https://tools.ietf.org/html/rfc5280
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/encrypt_context.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [Hash<String,String>] :encryption_context
    #   Specifies the encryption context that will be used when encrypting the
    #   private key in the data key pair.
    #
    #   Do not include confidential or sensitive information in this field.
    #   This field may be displayed in plaintext in CloudTrail logs and other
    #   output.
    #
    #   An *encryption context* is a collection of non-secret key-value pairs
    #   that represent additional authenticated data. When you use an
    #   encryption context to encrypt data, you must specify the same (an
    #   exact case-sensitive match) encryption context to decrypt the data. An
    #   encryption context is supported only on operations with symmetric
    #   encryption KMS keys. On operations with symmetric encryption KMS keys,
    #   an encryption context is optional, but it is strongly recommended.
    #
    #   For more information, see [Encryption context][1] in the *Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/encrypt_context.html
    #
    # @option params [required, String] :key_id
    #   Specifies the symmetric encryption KMS key that encrypts the private
    #   key in the data key pair. You cannot specify an asymmetric KMS key or
    #   a KMS key in a custom key store. To get the type and origin of your
    #   KMS key, use the DescribeKey operation.
    #
    #   To specify a KMS key, use its key ID, key ARN, alias name, or alias
    #   ARN. When using an alias name, prefix it with `"alias/"`. To specify a
    #   KMS key in a different Amazon Web Services account, you must use the
    #   key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey. To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [required, String] :key_pair_spec
    #   Determines the type of data key pair that is generated.
    #
    #   The KMS rule that restricts the use of asymmetric RSA and SM2 KMS keys
    #   to encrypt and decrypt or to sign and verify (but not both), the rule
    #   that permits you to use ECC KMS keys only to sign and verify, and the
    #   rule that permits you to use ML-DSA key pairs to sign and verify only
    #   are not effective on data key pairs, which are used outside of KMS.
    #   The SM2 key spec is only available in China Regions.
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   Use a grant token when your permission to call this operation comes
    #   from a new grant that has not yet achieved *eventual consistency*. For
    #   more information, see [Grant token][1] and [Using a grant token][2] in
    #   the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html#grant_token
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/using-grant-token.html
    #
    # @option params [Boolean] :dry_run
    #   Checks if your request will succeed. `DryRun` is an optional
    #   parameter.
    #
    #   To learn more about how to use this parameter, see [Testing your
    #   permissions][1] in the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/testing-permissions.html
    #
    # @return [Types::GenerateDataKeyPairWithoutPlaintextResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GenerateDataKeyPairWithoutPlaintextResponse#private_key_ciphertext_blob #private_key_ciphertext_blob} => String
    #   * {Types::GenerateDataKeyPairWithoutPlaintextResponse#public_key #public_key} => String
    #   * {Types::GenerateDataKeyPairWithoutPlaintextResponse#key_id #key_id} => String
    #   * {Types::GenerateDataKeyPairWithoutPlaintextResponse#key_pair_spec #key_pair_spec} => String
    #   * {Types::GenerateDataKeyPairWithoutPlaintextResponse#key_material_id #key_material_id} => String
    #
    #
    # @example Example: To generate an asymmetric data key pair without a plaintext key
    #
    #   # This example returns an asymmetric elliptic curve (ECC) data key pair. The private key is encrypted under the symmetric
    #   # encryption KMS key that you specify. This operation doesn't return a plaintext (unencrypted) private key.
    #
    #   resp = client.generate_data_key_pair_without_plaintext({
    #     key_id: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The symmetric encryption KMS key that encrypts the private key of the ECC data key pair.
    #     key_pair_spec: "ECC_NIST_P521", # The requested key spec of the ECC asymmetric data key pair.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_id: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The key ARN of the symmetric encryption KMS key that encrypted the private key in the ECC asymmetric data key pair.
    #     key_material_id: "0b7fd7ddbac6eef27907413567cad8c810e2883dc8a7534067a82ee1142fc1e6", # The identifier of the key material used to encrypt the private key.
    #     key_pair_spec: "ECC_NIST_P521", # The actual key spec of the ECC asymmetric data key pair.
    #     private_key_ciphertext_blob: "<binary data>", # The encrypted private key of the asymmetric ECC data key pair.
    #     public_key: "<binary data>", # The public key (plaintext).
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.generate_data_key_pair_without_plaintext({
    #     encryption_context: {
    #       "EncryptionContextKey" => "EncryptionContextValue",
    #     },
    #     key_id: "KeyIdType", # required
    #     key_pair_spec: "RSA_2048", # required, accepts RSA_2048, RSA_3072, RSA_4096, ECC_NIST_P256, ECC_NIST_P384, ECC_NIST_P521, ECC_SECG_P256K1, SM2, ECC_NIST_EDWARDS25519
    #     grant_tokens: ["GrantTokenType"],
    #     dry_run: false,
    #   })
    #
    # @example Response structure
    #
    #   resp.private_key_ciphertext_blob #=> String
    #   resp.public_key #=> String
    #   resp.key_id #=> String
    #   resp.key_pair_spec #=> String, one of "RSA_2048", "RSA_3072", "RSA_4096", "ECC_NIST_P256", "ECC_NIST_P384", "ECC_NIST_P521", "ECC_SECG_P256K1", "SM2", "ECC_NIST_EDWARDS25519"
    #   resp.key_material_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GenerateDataKeyPairWithoutPlaintext AWS API Documentation
    #
    # @overload generate_data_key_pair_without_plaintext(params = {})
    # @param [Hash] params ({})
    def generate_data_key_pair_without_plaintext(params = {}, options = {})
      req = build_request(:generate_data_key_pair_without_plaintext, params)
      req.send_request(options)
    end

    # Returns a unique symmetric data key for use outside of KMS. This
    # operation returns a data key that is encrypted under a symmetric
    # encryption KMS key that you specify. The bytes in the key are random;
    # they are not related to the caller or to the KMS key.
    #
    # `GenerateDataKeyWithoutPlaintext` is identical to the GenerateDataKey
    # operation except that it does not return a plaintext copy of the data
    # key.
    #
    # This operation is useful for systems that need to encrypt data at some
    # point, but not immediately. When you need to encrypt the data, you
    # call the Decrypt operation on the encrypted copy of the key.
    #
    # It's also useful in distributed systems with different levels of
    # trust. For example, you might store encrypted data in containers. One
    # component of your system creates new containers and stores an
    # encrypted data key with each container. Then, a different component
    # puts the data into the containers. That component first decrypts the
    # data key, uses the plaintext data key to encrypt data, puts the
    # encrypted data into the container, and then destroys the plaintext
    # data key. In this system, the component that creates the containers
    # never sees the plaintext data key.
    #
    # To request an asymmetric data key pair, use the GenerateDataKeyPair or
    # GenerateDataKeyPairWithoutPlaintext operations.
    #
    # To generate a data key, you must specify the symmetric encryption KMS
    # key that is used to encrypt the data key. You cannot use an asymmetric
    # KMS key or a key in a custom key store to generate a data key. To get
    # the type of your KMS key, use the DescribeKey operation.
    #
    # You must also specify the length of the data key. Use either the
    # `KeySpec` or `NumberOfBytes` parameters (but not both). For 128-bit
    # and 256-bit data keys, use the `KeySpec` parameter.
    #
    # To generate an SM4 data key (China Regions only), specify a `KeySpec`
    # value of `AES_128` or `NumberOfBytes` value of `16`. The symmetric
    # encryption key used in China Regions to encrypt your data key is an
    # SM4 encryption key.
    #
    # If the operation succeeds, you will find the encrypted copy of the
    # data key in the `CiphertextBlob` field.
    #
    # You can use an optional encryption context to add additional security
    # to the encryption operation. If you specify an `EncryptionContext`,
    # you must specify the same encryption context (a case-sensitive exact
    # match) when decrypting the encrypted data key. Otherwise, the request
    # to decrypt fails with an `InvalidCiphertextException`. For more
    # information, see [Encryption Context][1] in the *Key Management
    # Service Developer Guide*.
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][2] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: Yes. To perform this operation with a KMS key
    # in a different Amazon Web Services account, specify the key ARN or
    # alias ARN in the value of the `KeyId` parameter.
    #
    # **Required permissions**: [kms:GenerateDataKeyWithoutPlaintext][3]
    # (key policy)
    #
    # **Related operations:**
    #
    # * Decrypt
    #
    # * Encrypt
    #
    # * GenerateDataKey
    #
    # * GenerateDataKeyPair
    #
    # * GenerateDataKeyPairWithoutPlaintext
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][4].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/encrypt_context.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Specifies the symmetric encryption KMS key that encrypts the data key.
    #   You cannot specify an asymmetric KMS key or a KMS key in a custom key
    #   store. To get the type and origin of your KMS key, use the DescribeKey
    #   operation.
    #
    #   To specify a KMS key, use its key ID, key ARN, alias name, or alias
    #   ARN. When using an alias name, prefix it with `"alias/"`. To specify a
    #   KMS key in a different Amazon Web Services account, you must use the
    #   key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey. To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [Hash<String,String>] :encryption_context
    #   Specifies the encryption context that will be used when encrypting the
    #   data key.
    #
    #   Do not include confidential or sensitive information in this field.
    #   This field may be displayed in plaintext in CloudTrail logs and other
    #   output.
    #
    #   An *encryption context* is a collection of non-secret key-value pairs
    #   that represent additional authenticated data. When you use an
    #   encryption context to encrypt data, you must specify the same (an
    #   exact case-sensitive match) encryption context to decrypt the data. An
    #   encryption context is supported only on operations with symmetric
    #   encryption KMS keys. On operations with symmetric encryption KMS keys,
    #   an encryption context is optional, but it is strongly recommended.
    #
    #   For more information, see [Encryption context][1] in the *Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/encrypt_context.html
    #
    # @option params [String] :key_spec
    #   The length of the data key. Use `AES_128` to generate a 128-bit
    #   symmetric key, or `AES_256` to generate a 256-bit symmetric key.
    #
    # @option params [Integer] :number_of_bytes
    #   The length of the data key in bytes. For example, use the value 64 to
    #   generate a 512-bit data key (64 bytes is 512 bits). For common key
    #   lengths (128-bit and 256-bit symmetric keys), we recommend that you
    #   use the `KeySpec` field instead of this one.
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   Use a grant token when your permission to call this operation comes
    #   from a new grant that has not yet achieved *eventual consistency*. For
    #   more information, see [Grant token][1] and [Using a grant token][2] in
    #   the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html#grant_token
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/using-grant-token.html
    #
    # @option params [Boolean] :dry_run
    #   Checks if your request will succeed. `DryRun` is an optional
    #   parameter.
    #
    #   To learn more about how to use this parameter, see [Testing your
    #   permissions][1] in the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/testing-permissions.html
    #
    # @return [Types::GenerateDataKeyWithoutPlaintextResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GenerateDataKeyWithoutPlaintextResponse#ciphertext_blob #ciphertext_blob} => String
    #   * {Types::GenerateDataKeyWithoutPlaintextResponse#key_id #key_id} => String
    #   * {Types::GenerateDataKeyWithoutPlaintextResponse#key_material_id #key_material_id} => String
    #
    #
    # @example Example: To generate an encrypted data key
    #
    #   # The following example generates an encrypted copy of a 256-bit symmetric data encryption key (data key). The data key is
    #   # encrypted with the specified KMS key.
    #
    #   resp = client.generate_data_key_without_plaintext({
    #     key_id: "alias/ExampleAlias", # The identifier of the KMS key to use to encrypt the data key. You can use the key ID or Amazon Resource Name (ARN) of the KMS key, or the name or ARN of an alias that refers to the KMS key.
    #     key_spec: "AES_256", # Specifies the type of data key to return.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     ciphertext_blob: "<binary data>", # The encrypted data key.
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The ARN of the KMS key that was used to encrypt the data key.
    #     key_material_id: "0b7fd7ddbac6eef27907413567cad8c810e2883dc8a7534067a82ee1142fc1e6", # The identifier of the key material used to encrypt the data key.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.generate_data_key_without_plaintext({
    #     key_id: "KeyIdType", # required
    #     encryption_context: {
    #       "EncryptionContextKey" => "EncryptionContextValue",
    #     },
    #     key_spec: "AES_256", # accepts AES_256, AES_128
    #     number_of_bytes: 1,
    #     grant_tokens: ["GrantTokenType"],
    #     dry_run: false,
    #   })
    #
    # @example Response structure
    #
    #   resp.ciphertext_blob #=> String
    #   resp.key_id #=> String
    #   resp.key_material_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GenerateDataKeyWithoutPlaintext AWS API Documentation
    #
    # @overload generate_data_key_without_plaintext(params = {})
    # @param [Hash] params ({})
    def generate_data_key_without_plaintext(params = {}, options = {})
      req = build_request(:generate_data_key_without_plaintext, params)
      req.send_request(options)
    end

    # Generates a hash-based message authentication code (HMAC) for a
    # message using an HMAC KMS key and a MAC algorithm that the key
    # supports. HMAC KMS keys and the HMAC algorithms that KMS uses conform
    # to industry standards defined in [RFC 2104][1].
    #
    # You can use value that GenerateMac returns in the VerifyMac operation
    # to demonstrate that the original message has not changed. Also,
    # because a secret key is used to create the hash, you can verify that
    # the party that generated the hash has the required secret key. You can
    # also use the raw result to implement HMAC-based algorithms such as key
    # derivation functions. This operation is part of KMS support for HMAC
    # KMS keys. For details, see [HMAC keys in KMS][2] in the <i> <i>Key
    # Management Service Developer Guide</i> </i>.
    #
    # <note markdown="1"> Best practices recommend that you limit the time during which any
    # signing mechanism, including an HMAC, is effective. This deters an
    # attack where the actor uses a signed message to establish validity
    # repeatedly or long after the message is superseded. HMAC tags do not
    # include a timestamp, but you can include a timestamp in the token or
    # message to help you detect when its time to refresh the HMAC.
    #
    #  </note>
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][3] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: Yes. To perform this operation with a KMS key
    # in a different Amazon Web Services account, specify the key ARN or
    # alias ARN in the value of the `KeyId` parameter.
    #
    # **Required permissions**: [kms:GenerateMac][4] (key policy)
    #
    # **Related operations**: VerifyMac
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][5].
    #
    #
    #
    # [1]: https://datatracker.ietf.org/doc/html/rfc2104
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/hmac.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String, StringIO, File] :message
    #   The message to be hashed. Specify a message of up to 4,096 bytes.
    #
    #   `GenerateMac` and VerifyMac do not provide special handling for
    #   message digests. If you generate an HMAC for a hash digest of a
    #   message, you must verify the HMAC of the same hash digest.
    #
    # @option params [required, String] :key_id
    #   The HMAC KMS key to use in the operation. The MAC algorithm computes
    #   the HMAC for the message and the key as described in [RFC 2104][1].
    #
    #   To identify an HMAC KMS key, use the DescribeKey operation and see the
    #   `KeySpec` field in the response.
    #
    #
    #
    #   [1]: https://datatracker.ietf.org/doc/html/rfc2104
    #
    # @option params [required, String] :mac_algorithm
    #   The MAC algorithm used in the operation.
    #
    #   The algorithm must be compatible with the HMAC KMS key that you
    #   specify. To find the MAC algorithms that your HMAC KMS key supports,
    #   use the DescribeKey operation and see the `MacAlgorithms` field in the
    #   `DescribeKey` response.
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   Use a grant token when your permission to call this operation comes
    #   from a new grant that has not yet achieved *eventual consistency*. For
    #   more information, see [Grant token][1] and [Using a grant token][2] in
    #   the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html#grant_token
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/using-grant-token.html
    #
    # @option params [Boolean] :dry_run
    #   Checks if your request will succeed. `DryRun` is an optional
    #   parameter.
    #
    #   To learn more about how to use this parameter, see [Testing your
    #   permissions][1] in the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/testing-permissions.html
    #
    # @return [Types::GenerateMacResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GenerateMacResponse#mac #mac} => String
    #   * {Types::GenerateMacResponse#mac_algorithm #mac_algorithm} => String
    #   * {Types::GenerateMacResponse#key_id #key_id} => String
    #
    #
    # @example Example: To generate an HMAC for a message
    #
    #   # This example generates an HMAC for a message, an HMAC KMS key, and a MAC algorithm. The algorithm must be supported by
    #   # the specified HMAC KMS key.
    #
    #   resp = client.generate_mac({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The HMAC KMS key input to the HMAC algorithm.
    #     mac_algorithm: "HMAC_SHA_384", # The HMAC algorithm requested for the operation.
    #     message: "Hello World", # The message input to the HMAC algorithm.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_id: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The key ARN of the HMAC KMS key used in the operation.
    #     mac: "<HMAC_TAG>", # The HMAC tag that results from this operation.
    #     mac_algorithm: "HMAC_SHA_384", # The HMAC algorithm used in the operation.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.generate_mac({
    #     message: "data", # required
    #     key_id: "KeyIdType", # required
    #     mac_algorithm: "HMAC_SHA_224", # required, accepts HMAC_SHA_224, HMAC_SHA_256, HMAC_SHA_384, HMAC_SHA_512
    #     grant_tokens: ["GrantTokenType"],
    #     dry_run: false,
    #   })
    #
    # @example Response structure
    #
    #   resp.mac #=> String
    #   resp.mac_algorithm #=> String, one of "HMAC_SHA_224", "HMAC_SHA_256", "HMAC_SHA_384", "HMAC_SHA_512"
    #   resp.key_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GenerateMac AWS API Documentation
    #
    # @overload generate_mac(params = {})
    # @param [Hash] params ({})
    def generate_mac(params = {}, options = {})
      req = build_request(:generate_mac, params)
      req.send_request(options)
    end

    # Returns a random byte string that is cryptographically secure.
    #
    # You must use the `NumberOfBytes` parameter to specify the length of
    # the random byte string. There is no default value for string length.
    #
    # By default, the random byte string is generated in KMS. To generate
    # the byte string in the CloudHSM cluster associated with an CloudHSM
    # key store, use the `CustomKeyStoreId` parameter.
    #
    # `GenerateRandom` also supports [Amazon Web Services Nitro
    # Enclaves][1], which provide an isolated compute environment in Amazon
    # EC2. To call `GenerateRandom` for a Nitro enclave or NitroTPM, use the
    # [Amazon Web Services Nitro Enclaves SDK][2] or any Amazon Web Services
    # SDK. Use the `Recipient` parameter to provide the attestation document
    # for the attested environment. Instead of plaintext bytes, the response
    # includes the plaintext bytes encrypted under the public key from the
    # attestation document (`CiphertextForRecipient`). For information about
    # the interaction between KMS and Amazon Web Services Nitro Enclaves or
    # Amazon Web Services NitroTPM, see [Cryptographic attestation support
    # in KMS][3] in the *Key Management Service Developer Guide*.
    #
    # For more information about entropy and random number generation, see
    # [Entropy and random number generation][4] in the *Key Management
    # Service Developer Guide*.
    #
    # **Cross-account use**: Not applicable. `GenerateRandom` does not use
    # any account-specific resources, such as KMS keys.
    #
    # **Required permissions**: [kms:GenerateRandom][5] (IAM policy)
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][6].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/nitro-enclave.html
    # [2]: https://docs.aws.amazon.com/enclaves/latest/user/developing-applications.html#sdk
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/cryptographic-attestation.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-cryptography.html#entropy-and-random-numbers
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [6]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [Integer] :number_of_bytes
    #   The length of the random byte string. This parameter is required.
    #
    # @option params [String] :custom_key_store_id
    #   Generates the random byte string in the CloudHSM cluster that is
    #   associated with the specified CloudHSM key store. To find the ID of a
    #   custom key store, use the DescribeCustomKeyStores operation.
    #
    #   External key store IDs are not valid for this parameter. If you
    #   specify the ID of an external key store, `GenerateRandom` throws an
    #   `UnsupportedOperationException`.
    #
    # @option params [Types::RecipientInfo] :recipient
    #   A signed [attestation document][1] from an Amazon Web Services Nitro
    #   enclave or NitroTPM, and the encryption algorithm to use with the
    #   public key in the attestation document. The only valid encryption
    #   algorithm is `RSAES_OAEP_SHA_256`.
    #
    #   This parameter supports the [Amazon Web Services Nitro Enclaves
    #   SDK][2] or any Amazon Web Services SDK for Amazon Web Services Nitro
    #   Enclaves. It supports any Amazon Web Services SDK for Amazon Web
    #   Services NitroTPM.
    #
    #   When you use this parameter, instead of returning plaintext bytes, KMS
    #   encrypts the plaintext bytes under the public key in the attestation
    #   document, and returns the resulting ciphertext in the
    #   `CiphertextForRecipient` field in the response. This ciphertext can be
    #   decrypted only with the private key in the attested environment. The
    #   `Plaintext` field in the response is null or empty.
    #
    #   For information about the interaction between KMS and Amazon Web
    #   Services Nitro Enclaves or Amazon Web Services NitroTPM, see
    #   [Cryptographic attestation support in KMS][3] in the *Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/nitro-enclave-how.html#term-attestdoc
    #   [2]: https://docs.aws.amazon.com/enclaves/latest/user/developing-applications.html#sdk
    #   [3]: https://docs.aws.amazon.com/kms/latest/developerguide/cryptographic-attestation.html
    #
    # @return [Types::GenerateRandomResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GenerateRandomResponse#plaintext #plaintext} => String
    #   * {Types::GenerateRandomResponse#ciphertext_for_recipient #ciphertext_for_recipient} => String
    #
    #
    # @example Example: To generate random data
    #
    #   # The following example generates 32 bytes of random data.
    #
    #   resp = client.generate_random({
    #     number_of_bytes: 32, # The length of the random data, specified in number of bytes.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     plaintext: "<binary data>", # The random data.
    #   }
    #
    # @example Example: To generate random data for a Nitro enclave or NitroTPM
    #
    #   # The following example includes the Recipient parameter with a signed attestation document from an AWS Nitro enclave or
    #   # NitroTPM. Instead of returning a plaintext (unencrypted) byte string, GenerateRandom returns the byte string encrypted
    #   # by the public key from the attestation document.
    #
    #   resp = client.generate_random({
    #     number_of_bytes: 1024, # The length of the random byte string
    #     recipient: {
    #       attestation_document: "<attestation document>", 
    #       key_encryption_algorithm: "RSAES_OAEP_SHA_256", 
    #     }, # Specifies the attestation document from the Nitro enclave or NitroTPM and the encryption algorithm to use with the public key from the attestation document
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     ciphertext_for_recipient: "<binary data>", # The random data encrypted under the public key from the attestation document
    #     plaintext: "", # This field is null or empty
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.generate_random({
    #     number_of_bytes: 1,
    #     custom_key_store_id: "CustomKeyStoreIdType",
    #     recipient: {
    #       key_encryption_algorithm: "RSAES_OAEP_SHA_256", # accepts RSAES_OAEP_SHA_256
    #       attestation_document: "data",
    #     },
    #   })
    #
    # @example Response structure
    #
    #   resp.plaintext #=> String
    #   resp.ciphertext_for_recipient #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GenerateRandom AWS API Documentation
    #
    # @overload generate_random(params = {})
    # @param [Hash] params ({})
    def generate_random(params = {}, options = {})
      req = build_request(:generate_random, params)
      req.send_request(options)
    end

    # Gets a key policy attached to the specified KMS key.
    #
    # **Cross-account use**: No. You cannot perform this operation on a KMS
    # key in a different Amazon Web Services account.
    #
    # **Required permissions**: [kms:GetKeyPolicy][1] (key policy)
    #
    # **Related operations**: [PutKeyPolicy][2]
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][3].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [2]: https://docs.aws.amazon.com/kms/latest/APIReference/API_PutKeyPolicy.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Gets the key policy for the specified KMS key.
    #
    #   Specify the key ID or key ARN of the KMS key.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    # @option params [String] :policy_name
    #   Specifies the name of the key policy. If no policy name is specified,
    #   the default value is `default`. The only valid name is `default`. To
    #   get the names of key policies, use ListKeyPolicies.
    #
    # @return [Types::GetKeyPolicyResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetKeyPolicyResponse#policy #policy} => String
    #   * {Types::GetKeyPolicyResponse#policy_name #policy_name} => String
    #
    #
    # @example Example: To retrieve a key policy
    #
    #   # The following example retrieves the key policy for the specified KMS key.
    #
    #   resp = client.get_key_policy({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key whose key policy you want to retrieve. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #     policy_name: "default", # The name of the key policy to retrieve.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     policy: "{\n  \"Version\" : \"2012-10-17\",\n  \"Id\" : \"key-default-1\",\n  \"Statement\" : [ {\n    \"Sid\" : \"Enable IAM User Permissions\",\n    \"Effect\" : \"Allow\",\n    \"Principal\" : {\n      \"AWS\" : \"arn:aws:iam::111122223333:root\"\n    },\n    \"Action\" : \"kms:*\",\n    \"Resource\" : \"*\"\n  } ]\n}", # The key policy document.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_key_policy({
    #     key_id: "KeyIdType", # required
    #     policy_name: "PolicyNameType",
    #   })
    #
    # @example Response structure
    #
    #   resp.policy #=> String
    #   resp.policy_name #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GetKeyPolicy AWS API Documentation
    #
    # @overload get_key_policy(params = {})
    # @param [Hash] params ({})
    def get_key_policy(params = {}, options = {})
      req = build_request(:get_key_policy, params)
      req.send_request(options)
    end

    # Provides detailed information about the rotation status for a KMS key,
    # including whether [automatic rotation of the key material][1] is
    # enabled for the specified KMS key, the [rotation period][2], and the
    # next scheduled rotation date.
    #
    # Automatic key rotation is supported only on symmetric encryption KMS
    # keys. You cannot enable automatic rotation of [asymmetric KMS
    # keys][3], [HMAC KMS keys][4], KMS keys with [imported key
    # material][5], or KMS keys in a [custom key store][6]. To enable or
    # disable automatic rotation of a set of related [multi-Region keys][7],
    # set the property on the primary key.
    #
    # You can enable (EnableKeyRotation) and disable automatic rotation
    # (DisableKeyRotation) of the key material in customer managed KMS keys.
    # Key material rotation of [Amazon Web Services managed KMS keys][8] is
    # not configurable. KMS always rotates the key material in Amazon Web
    # Services managed KMS keys every year. The key rotation status for
    # Amazon Web Services managed KMS keys is always `true`.
    #
    # You can perform on-demand (RotateKeyOnDemand) rotation of the key
    # material in customer managed KMS keys, regardless of whether or not
    # automatic key rotation is enabled. You can use GetKeyRotationStatus to
    # identify the date and time that an in progress on-demand rotation was
    # initiated. You can use ListKeyRotations to view the details of
    # completed rotations.
    #
    # <note markdown="1"> In May 2022, KMS changed the rotation schedule for Amazon Web Services
    # managed keys from every three years to every year. For details, see
    # EnableKeyRotation.
    #
    #  </note>
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][9] in the *Key
    # Management Service Developer Guide*.
    #
    # * Disabled: The key rotation status does not change when you disable a
    #   KMS key. However, while the KMS key is disabled, KMS does not rotate
    #   the key material. When you re-enable the KMS key, rotation resumes.
    #   If the key material in the re-enabled KMS key hasn't been rotated
    #   in one year, KMS rotates it immediately, and every year thereafter.
    #   If it's been less than a year since the key material in the
    #   re-enabled KMS key was rotated, the KMS key resumes its prior
    #   rotation schedule.
    #
    # * Pending deletion: While a KMS key is pending deletion, its key
    #   rotation status is `false` and KMS does not rotate the key material.
    #   If you cancel the deletion, the original key rotation status returns
    #   to `true`.
    #
    # **Cross-account use**: Yes. To perform this operation on a KMS key in
    # a different Amazon Web Services account, specify the key ARN in the
    # value of the `KeyId` parameter.
    #
    # **Required permissions**: [kms:GetKeyRotationStatus][10] (key policy)
    #
    # **Related operations:**
    #
    # * DisableKeyRotation
    #
    # * EnableKeyRotation
    #
    # * ListKeyRotations
    #
    # * RotateKeyOnDemand
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][11].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/rotating-keys-enable-disable.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html#rotation-period
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/hmac.html
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html
    # [6]: https://docs.aws.amazon.com/kms/latest/developerguide/key-store-overview.html
    # [7]: https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html#multi-region-rotate
    # [8]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-key
    # [9]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [10]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [11]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Gets the rotation status for the specified KMS key.
    #
    #   Specify the key ID or key ARN of the KMS key. To specify a KMS key in
    #   a different Amazon Web Services account, you must use the key ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    # @return [Types::GetKeyRotationStatusResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetKeyRotationStatusResponse#key_rotation_enabled #key_rotation_enabled} => Boolean
    #   * {Types::GetKeyRotationStatusResponse#key_id #key_id} => String
    #   * {Types::GetKeyRotationStatusResponse#rotation_period_in_days #rotation_period_in_days} => Integer
    #   * {Types::GetKeyRotationStatusResponse#next_rotation_date #next_rotation_date} => Time
    #   * {Types::GetKeyRotationStatusResponse#on_demand_rotation_start_date #on_demand_rotation_start_date} => Time
    #
    #
    # @example Example: To retrieve the rotation status for a KMS key
    #
    #   # The following example retrieves detailed information about the rotation status for a KMS key, including whether
    #   # automatic key rotation is enabled for the specified KMS key, the rotation period, and the next scheduled rotation date.
    #
    #   resp = client.get_key_rotation_status({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key whose key material rotation status you want to retrieve. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # Identifies the specified symmetric encryption KMS key.
    #     key_rotation_enabled: true, # A boolean that indicates the key material rotation status. Returns true when automatic rotation of the key material is enabled, or false when it is not.
    #     next_rotation_date: Time.parse("2024-04-05T15:14:47.757000+00:00"), # The next date that the key material will be automatically rotated.
    #     on_demand_rotation_start_date: Time.parse("2024-03-02T10:11:36.564000+00:00"), # Identifies the date and time that an in progress on-demand rotation was initiated.
    #     rotation_period_in_days: 365, # The number of days between each automatic rotation. The default value is 365 days.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_key_rotation_status({
    #     key_id: "KeyIdType", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.key_rotation_enabled #=> Boolean
    #   resp.key_id #=> String
    #   resp.rotation_period_in_days #=> Integer
    #   resp.next_rotation_date #=> Time
    #   resp.on_demand_rotation_start_date #=> Time
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GetKeyRotationStatus AWS API Documentation
    #
    # @overload get_key_rotation_status(params = {})
    # @param [Hash] params ({})
    def get_key_rotation_status(params = {}, options = {})
      req = build_request(:get_key_rotation_status, params)
      req.send_request(options)
    end

    # Returns the public key and an import token you need to import or
    # reimport key material for a KMS key.
    #
    # By default, KMS keys are created with key material that KMS generates.
    # This operation supports [Importing key material][1], an advanced
    # feature that lets you generate and import the cryptographic key
    # material for a KMS key.
    #
    # Before calling `GetParametersForImport`, use the CreateKey operation
    # with an `Origin` value of `EXTERNAL` to create a KMS key with no key
    # material. You can import key material for a symmetric encryption KMS
    # key, HMAC KMS key, asymmetric encryption KMS key, or asymmetric
    # signing KMS key. You can also import key material into a [multi-Region
    # key][2] of any supported type. However, you can't import key material
    # into a KMS key in a [custom key store][3]. You can also use
    # `GetParametersForImport` to get a public key and import token to
    # [reimport the original key material][4] into a KMS key whose key
    # material expired or was deleted.
    #
    # `GetParametersForImport` returns the items that you need to import
    # your key material.
    #
    # * The public key (or "wrapping key") of an RSA key pair that KMS
    #   generates.
    #
    #   You will use this public key to encrypt ("wrap") your key material
    #   while it's in transit to KMS.
    #
    # * A import token that ensures that KMS can decrypt your key material
    #   and associate it with the correct KMS key.
    #
    # The public key and its import token are permanently linked and must be
    # used together. Each public key and import token set is valid for 24
    # hours. The expiration date and time appear in the `ParametersValidTo`
    # field in the `GetParametersForImport` response. You cannot use an
    # expired public key or import token in an ImportKeyMaterial request. If
    # your key and token expire, send another `GetParametersForImport`
    # request.
    #
    # `GetParametersForImport` requires the following information:
    #
    # * The key ID of the KMS key for which you are importing the key
    #   material.
    #
    # * The key spec of the public key ("wrapping key") that you will use
    #   to encrypt your key material during import.
    #
    # * The wrapping algorithm that you will use with the public key to
    #   encrypt your key material.
    #
    # You can use the same or a different public key spec and wrapping
    # algorithm each time you import or reimport the same key material.
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][5] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: No. You cannot perform this operation on a KMS
    # key in a different Amazon Web Services account.
    #
    # **Required permissions**: [kms:GetParametersForImport][6] (key policy)
    #
    # **Related operations:**
    #
    # * ImportKeyMaterial
    #
    # * DeleteImportedKeyMaterial
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][7].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-overview.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/key-store-overview.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys-import-key-material.html#reimport-key-material
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [6]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [7]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   The identifier of the KMS key that will be associated with the
    #   imported key material. The `Origin` of the KMS key must be `EXTERNAL`.
    #
    #   All KMS key types are supported, including multi-Region keys. However,
    #   you cannot import key material into a KMS key in a custom key store.
    #
    #   Specify the key ID or key ARN of the KMS key.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    # @option params [required, String] :wrapping_algorithm
    #   The algorithm you will use with the RSA public key (`PublicKey`) in
    #   the response to protect your key material during import. For more
    #   information, see [Select a wrapping algorithm][1] in the *Key
    #   Management Service Developer Guide*.
    #
    #   For RSA\_AES wrapping algorithms, you encrypt your key material with
    #   an AES key that you generate, then encrypt your AES key with the RSA
    #   public key from KMS. For RSAES wrapping algorithms, you encrypt your
    #   key material directly with the RSA public key from KMS.
    #
    #   The wrapping algorithms that you can use depend on the type of key
    #   material that you are importing. To import an RSA private key, you
    #   must use an RSA\_AES wrapping algorithm.
    #
    #   * **RSA\_AES\_KEY\_WRAP\_SHA\_256** — Supported for wrapping RSA and
    #     ECC key material.
    #
    #   * **RSA\_AES\_KEY\_WRAP\_SHA\_1** — Supported for wrapping RSA and ECC
    #     key material.
    #
    #   * **RSAES\_OAEP\_SHA\_256** — Supported for all types of key material,
    #     except RSA key material (private key).
    #
    #     You cannot use the RSAES\_OAEP\_SHA\_256 wrapping algorithm with the
    #     RSA\_2048 wrapping key spec to wrap ECC\_NIST\_P521 key material.
    #
    #   * **RSAES\_OAEP\_SHA\_1** — Supported for all types of key material,
    #     except RSA key material (private key).
    #
    #     You cannot use the RSAES\_OAEP\_SHA\_1 wrapping algorithm with the
    #     RSA\_2048 wrapping key spec to wrap ECC\_NIST\_P521 key material.
    #
    #   * **RSAES\_PKCS1\_V1\_5** (Deprecated) — As of October 10, 2023, KMS
    #     does not support the RSAES\_PKCS1\_V1\_5 wrapping algorithm.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys-get-public-key-and-token.html#select-wrapping-algorithm
    #
    # @option params [required, String] :wrapping_key_spec
    #   The type of RSA public key to return in the response. You will use
    #   this wrapping key with the specified wrapping algorithm to protect
    #   your key material during import.
    #
    #   Use the longest RSA wrapping key that is practical.
    #
    #   You cannot use an RSA\_2048 public key to directly wrap an
    #   ECC\_NIST\_P521 private key. Instead, use an RSA\_AES wrapping
    #   algorithm or choose a longer RSA public key.
    #
    # @return [Types::GetParametersForImportResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetParametersForImportResponse#key_id #key_id} => String
    #   * {Types::GetParametersForImportResponse#import_token #import_token} => String
    #   * {Types::GetParametersForImportResponse#public_key #public_key} => String
    #   * {Types::GetParametersForImportResponse#parameters_valid_to #parameters_valid_to} => Time
    #
    #
    # @example Example: To download the public key and import token for a symmetric encryption KMS key
    #
    #   # The following example downloads a public key and import token to import symmetric encryption key material. It uses the
    #   # default wrapping key spec and the RSAES_OAEP_SHA_256 wrapping algorithm.
    #
    #   resp = client.get_parameters_for_import({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key that will be associated with the imported key material. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #     wrapping_algorithm: "RSAES_OAEP_SHA_1", # The algorithm that you will use to encrypt the key material before importing it.
    #     wrapping_key_spec: "RSA_2048", # The type of wrapping key (public key) to return in the response.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     import_token: "<binary data>", # The import token to send with a subsequent ImportKeyMaterial request.
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The ARN of the KMS key that will be associated with the imported key material.
    #     parameters_valid_to: Time.parse("2023-02-01T14:52:17-08:00"), # The date and time when the import token and public key expire. After this time, call GetParametersForImport again.
    #     public_key: "<binary data>", # The public key to use to encrypt the key material before importing it.
    #   }
    #
    # @example Example: To download the public key and import token for an RSA asymmetric KMS key
    #
    #   # The following example downloads a public key and import token to import an RSA private key. It uses a required RSA_AES
    #   # wrapping algorithm and the largest supported private key.
    #
    #   resp = client.get_parameters_for_import({
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/8888abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key that will be associated with the imported key material. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #     wrapping_algorithm: "RSA_AES_KEY_WRAP_SHA_256", # The algorithm that you will use to encrypt the key material before importing it.
    #     wrapping_key_spec: "RSA_4096", # The type of wrapping key (public key) to return in the response.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     import_token: "<binary data>", # The import token to send with a subsequent ImportKeyMaterial request.
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/8888abcd-12ab-34cd-56ef-1234567890ab", # The ARN of the KMS key that will be associated with the imported key material.
    #     parameters_valid_to: Time.parse("2023-03-08T13:02:02-07:00"), # The date and time when the import token and public key expire. After this time, call GetParametersForImport again.
    #     public_key: "<binary data>", # The public key to use to encrypt the key material before importing it.
    #   }
    #
    # @example Example: To download the public key and import token for an elliptic curve (ECC) asymmetric KMS key
    #
    #   # The following example downloads a public key and import token to import an ECC_NIST_P521 (secp521r1) private key. You
    #   # cannot directly wrap this ECC key under an RSA_2048 public key, although you can use an RSA_2048 public key with an
    #   # RSA_AES wrapping algorithm to wrap any supported key material. This example requests an RSA_3072 public key for use with
    #   # the RSAES_OAEP_SHA_256.
    #
    #   resp = client.get_parameters_for_import({
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/9876abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key that will be associated with the imported key material. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #     wrapping_algorithm: "RSAES_OAEP_SHA_256", # The algorithm that you will use to encrypt the key material before importing it.
    #     wrapping_key_spec: "RSA_3072", # The type of wrapping key (public key) to return in the response.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     import_token: "<binary data>", # The import token to send with a subsequent ImportKeyMaterial request.
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/9876abcd-12ab-34cd-56ef-1234567890ab", # The ARN of the KMS key that will be associated with the imported key material.
    #     parameters_valid_to: Time.parse("2023-09-12T03:15:01-20:00"), # The date and time when the import token and public key expire. After this time, call GetParametersForImport again.
    #     public_key: "<binary data>", # The public key to use to encrypt the key material before importing it.
    #   }
    #
    # @example Example: To download the public key and import token for an HMAC KMS key
    #
    #   # The following example downloads a public key and import token to import an HMAC key. It uses the RSAES_OAEP_SHA_256
    #   # wrapping algorithm and an RSA_4096 private key.
    #
    #   resp = client.get_parameters_for_import({
    #     key_id: "2468abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key that will be associated with the imported key material. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #     wrapping_algorithm: "RSAES_OAEP_SHA_256", # The algorithm that you will use to encrypt the key material before importing it.
    #     wrapping_key_spec: "RSA_4096", # The type of wrapping key (public key) to return in the response.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     import_token: "<binary data>", # The import token to send with a subsequent ImportKeyMaterial request.
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/2468abcd-12ab-34cd-56ef-1234567890ab", # The ARN of the KMS key that will be associated with the imported key material.
    #     parameters_valid_to: Time.parse("2023-04-02T13:02:02-07:00"), # The date and time when the import token and public key expire. After this time, call GetParametersForImport again.
    #     public_key: "<binary data>", # The public key to use to encrypt the key material before importing it.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_parameters_for_import({
    #     key_id: "KeyIdType", # required
    #     wrapping_algorithm: "RSAES_PKCS1_V1_5", # required, accepts RSAES_PKCS1_V1_5, RSAES_OAEP_SHA_1, RSAES_OAEP_SHA_256, RSA_AES_KEY_WRAP_SHA_1, RSA_AES_KEY_WRAP_SHA_256, SM2PKE
    #     wrapping_key_spec: "RSA_2048", # required, accepts RSA_2048, RSA_3072, RSA_4096, SM2
    #   })
    #
    # @example Response structure
    #
    #   resp.key_id #=> String
    #   resp.import_token #=> String
    #   resp.public_key #=> String
    #   resp.parameters_valid_to #=> Time
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GetParametersForImport AWS API Documentation
    #
    # @overload get_parameters_for_import(params = {})
    # @param [Hash] params ({})
    def get_parameters_for_import(params = {}, options = {})
      req = build_request(:get_parameters_for_import, params)
      req.send_request(options)
    end

    # Returns the public key of an asymmetric KMS key. Unlike the private
    # key of a asymmetric KMS key, which never leaves KMS unencrypted,
    # callers with `kms:GetPublicKey` permission can download the public key
    # of an asymmetric KMS key. You can share the public key to allow others
    # to encrypt messages and verify signatures outside of KMS. For
    # information about asymmetric KMS keys, see [Asymmetric KMS keys][1] in
    # the *Key Management Service Developer Guide*.
    #
    # You do not need to download the public key. Instead, you can use the
    # public key within KMS by calling the Encrypt, ReEncrypt, or Verify
    # operations with the identifier of an asymmetric KMS key. When you use
    # the public key within KMS, you benefit from the authentication,
    # authorization, and logging that are part of every KMS operation. You
    # also reduce of risk of encrypting data that cannot be decrypted. These
    # features are not effective outside of KMS.
    #
    # To help you use the public key safely outside of KMS, `GetPublicKey`
    # returns important information about the public key in the response,
    # including:
    #
    # * [KeySpec][2]: The type of key material in the public key, such as
    #   `RSA_4096` or `ECC_NIST_P521`.
    #
    # * [KeyUsage][3]: Whether the key is used for encryption, signing, or
    #   deriving a shared secret.
    #
    # * [EncryptionAlgorithms][4], [KeyAgreementAlgorithms][5], or
    #   [SigningAlgorithms][6]: A list of the encryption algorithms, key
    #   agreement algorithms, or signing algorithms for the key.
    #
    # Although KMS cannot enforce these restrictions on external operations,
    # it is crucial that you use this information to prevent the public key
    # from being used improperly. For example, you can prevent a public
    # signing key from being used encrypt data, or prevent a public key from
    # being used with an encryption algorithm that is not supported by KMS.
    # You can also avoid errors, such as using the wrong signing algorithm
    # in a verification operation.
    #
    # To verify a signature outside of KMS with an SM2 public key (China
    # Regions only), you must specify the distinguishing ID. By default, KMS
    # uses `1234567812345678` as the distinguishing ID. For more
    # information, see [Offline verification with SM2 key pairs][7].
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][8] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: Yes. To perform this operation with a KMS key
    # in a different Amazon Web Services account, specify the key ARN or
    # alias ARN in the value of the `KeyId` parameter.
    #
    # **Required permissions**: [kms:GetPublicKey][9] (key policy)
    #
    # **Related operations**: CreateKey
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][10].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html
    # [2]: https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-KeySpec
    # [3]: https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-KeyUsage
    # [4]: https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-EncryptionAlgorithms
    # [5]: https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-KeyAgreementAlgorithms
    # [6]: https://docs.aws.amazon.com/kms/latest/APIReference/API_GetPublicKey.html#KMS-GetPublicKey-response-SigningAlgorithms
    # [7]: https://docs.aws.amazon.com/kms/latest/developerguide/offline-operations.html#key-spec-sm-offline-verification
    # [8]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [9]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [10]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Identifies the asymmetric KMS key that includes the public key.
    #
    #   To specify a KMS key, use its key ID, key ARN, alias name, or alias
    #   ARN. When using an alias name, prefix it with `"alias/"`. To specify a
    #   KMS key in a different Amazon Web Services account, you must use the
    #   key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey. To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   Use a grant token when your permission to call this operation comes
    #   from a new grant that has not yet achieved *eventual consistency*. For
    #   more information, see [Grant token][1] and [Using a grant token][2] in
    #   the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html#grant_token
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/using-grant-token.html
    #
    # @return [Types::GetPublicKeyResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetPublicKeyResponse#key_id #key_id} => String
    #   * {Types::GetPublicKeyResponse#public_key #public_key} => String
    #   * {Types::GetPublicKeyResponse#customer_master_key_spec #customer_master_key_spec} => String
    #   * {Types::GetPublicKeyResponse#key_spec #key_spec} => String
    #   * {Types::GetPublicKeyResponse#key_usage #key_usage} => String
    #   * {Types::GetPublicKeyResponse#encryption_algorithms #encryption_algorithms} => Array&lt;String&gt;
    #   * {Types::GetPublicKeyResponse#signing_algorithms #signing_algorithms} => Array&lt;String&gt;
    #   * {Types::GetPublicKeyResponse#key_agreement_algorithms #key_agreement_algorithms} => Array&lt;String&gt;
    #
    #
    # @example Example: To download the public key of an asymmetric KMS key
    #
    #   # This example gets the public key of an asymmetric RSA KMS key used for encryption and decryption. The operation returns
    #   # the key spec, key usage, and encryption or signing algorithms to help you use the public key correctly outside of AWS
    #   # KMS.
    #
    #   resp = client.get_public_key({
    #     key_id: "arn:aws:kms:us-west-2:111122223333:key/0987dcba-09fe-87dc-65ba-ab0987654321", # The key ARN of the asymmetric KMS key.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     customer_master_key_spec: "RSA_4096", # The key spec of the asymmetric KMS key from which the public key was downloaded.
    #     encryption_algorithms: [
    #       "RSAES_OAEP_SHA_1", 
    #       "RSAES_OAEP_SHA_256", 
    #     ], # The encryption algorithms supported by the asymmetric KMS key that was downloaded.
    #     key_id: "arn:aws:kms:us-west-2:111122223333:key/0987dcba-09fe-87dc-65ba-ab0987654321", # The key ARN of the asymmetric KMS key from which the public key was downloaded.
    #     key_usage: "ENCRYPT_DECRYPT", # The key usage of the asymmetric KMS key from which the public key was downloaded.
    #     public_key: "<binary data>", # The public key (plaintext) of the asymmetric KMS key.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_public_key({
    #     key_id: "KeyIdType", # required
    #     grant_tokens: ["GrantTokenType"],
    #   })
    #
    # @example Response structure
    #
    #   resp.key_id #=> String
    #   resp.public_key #=> String
    #   resp.customer_master_key_spec #=> String, one of "RSA_2048", "RSA_3072", "RSA_4096", "ECC_NIST_P256", "ECC_NIST_P384", "ECC_NIST_P521", "ECC_SECG_P256K1", "SYMMETRIC_DEFAULT", "HMAC_224", "HMAC_256", "HMAC_384", "HMAC_512", "SM2"
    #   resp.key_spec #=> String, one of "RSA_2048", "RSA_3072", "RSA_4096", "ECC_NIST_P256", "ECC_NIST_P384", "ECC_NIST_P521", "ECC_SECG_P256K1", "SYMMETRIC_DEFAULT", "HMAC_224", "HMAC_256", "HMAC_384", "HMAC_512", "SM2", "ML_DSA_44", "ML_DSA_65", "ML_DSA_87", "ECC_NIST_EDWARDS25519"
    #   resp.key_usage #=> String, one of "SIGN_VERIFY", "ENCRYPT_DECRYPT", "GENERATE_VERIFY_MAC", "KEY_AGREEMENT"
    #   resp.encryption_algorithms #=> Array
    #   resp.encryption_algorithms[0] #=> String, one of "SYMMETRIC_DEFAULT", "RSAES_OAEP_SHA_1", "RSAES_OAEP_SHA_256", "SM2PKE"
    #   resp.signing_algorithms #=> Array
    #   resp.signing_algorithms[0] #=> String, one of "RSASSA_PSS_SHA_256", "RSASSA_PSS_SHA_384", "RSASSA_PSS_SHA_512", "RSASSA_PKCS1_V1_5_SHA_256", "RSASSA_PKCS1_V1_5_SHA_384", "RSASSA_PKCS1_V1_5_SHA_512", "ECDSA_SHA_256", "ECDSA_SHA_384", "ECDSA_SHA_512", "SM2DSA", "ML_DSA_SHAKE_256", "ED25519_SHA_512", "ED25519_PH_SHA_512"
    #   resp.key_agreement_algorithms #=> Array
    #   resp.key_agreement_algorithms[0] #=> String, one of "ECDH"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/GetPublicKey AWS API Documentation
    #
    # @overload get_public_key(params = {})
    # @param [Hash] params ({})
    def get_public_key(params = {}, options = {})
      req = build_request(:get_public_key, params)
      req.send_request(options)
    end

    # Imports or reimports key material into an existing KMS key that was
    # created without key material. You can also use this operation to set
    # or update the expiration model and expiration date of the imported key
    # material.
    #
    # By default, KMS creates KMS keys with key material that it generates.
    # You can also generate and import your own key material. For more
    # information about importing key material, see [Importing key
    # material][1].
    #
    # For asymmetric and HMAC keys, you cannot change the key material after
    # the initial import. You can import multiple key materials into
    # symmetric encryption keys and rotate the key material on demand using
    # `RotateKeyOnDemand`.
    #
    # You can import new key materials into multi-Region symmetric
    # encryption keys. To do so, you must import the new key material into
    # the primary Region key. Then you can import the same key materials
    # into the replica Region keys. You cannot directly import new key
    # material into the replica Region keys.
    #
    # To import new key material for a multi-Region symmetric key, you’ll
    # need to complete the following:
    #
    # 1.  Call `ImportKeyMaterial` on the primary Region key with the
    #     `ImportType`set to `NEW_KEY_MATERIAL`.
    #
    # 2.  Call `ImportKeyMaterial` on the replica Region key with the
    #     `ImportType` set to `EXISTING_KEY_MATERIAL` using the same key
    #     material imported to the primary Region key. You must do this for
    #     every replica Region key before you can perform the
    #     RotateKeyOnDemand operation on the primary Region key.
    #
    # After you import key material, you can [reimport the same key
    # material][2] into that KMS key or, if the key supports on-demand
    # rotation, import new key material. You can use the `ImportType`
    # parameter to indicate whether you are importing new key material or
    # re-importing previously imported key material. You might reimport key
    # material to replace key material that expired or key material that you
    # deleted. You might also reimport key material to change the expiration
    # model or expiration date of the key material.
    #
    # Each time you import key material into KMS, you can determine whether
    # (`ExpirationModel`) and when (`ValidTo`) the key material expires. To
    # change the expiration of your key material, you must import it again,
    # either by calling `ImportKeyMaterial` or using the [import
    # features][3] of the KMS console.
    #
    # Before you call `ImportKeyMaterial`, complete these steps:
    #
    # * Create or identify a KMS key with `EXTERNAL` origin, which indicates
    #   that the KMS key is designed for imported key material.
    #
    #   To create a new KMS key for imported key material, call the
    #   CreateKey operation with an `Origin` value of `EXTERNAL`. You can
    #   create a symmetric encryption KMS key, HMAC KMS key, asymmetric
    #   encryption KMS key, asymmetric key agreement key, or asymmetric
    #   signing KMS key. You can also import key material into a
    #   [multi-Region key][4] of any supported type. However, you can't
    #   import key material into a KMS key in a [custom key store][5].
    #
    # * Call the GetParametersForImport operation to get a public key and
    #   import token set for importing key material.
    #
    # * Use the public key in the GetParametersForImport response to encrypt
    #   your key material.
    #
    # Then, in an `ImportKeyMaterial` request, you submit your encrypted key
    # material and import token. When calling this operation, you must
    # specify the following values:
    #
    # * The key ID or key ARN of the KMS key to associate with the imported
    #   key material. Its `Origin` must be `EXTERNAL` and its `KeyState`
    #   must be `PendingImport` or `Enabled`. You cannot perform this
    #   operation on a KMS key in a [custom key store][5], or on a KMS key
    #   in a different Amazon Web Services account. To get the `Origin` and
    #   `KeyState` of a KMS key, call DescribeKey.
    #
    # * The encrypted key material.
    #
    # * The import token that GetParametersForImport returned. You must use
    #   a public key and token from the same `GetParametersForImport`
    #   response.
    #
    # * Whether the key material expires (`ExpirationModel`) and, if so,
    #   when (`ValidTo`). For help with this choice, see [Setting an
    #   expiration time][6] in the *Key Management Service Developer Guide*.
    #
    #   If you set an expiration date, KMS deletes the key material from the
    #   KMS key on the specified date, making the KMS key unusable. To use
    #   the KMS key in cryptographic operations again, you must reimport the
    #   same key material. However, you can delete and reimport the key
    #   material at any time, including before the key material expires.
    #   Each time you reimport, you can eliminate or reset the expiration
    #   time.
    #
    # When this operation is successful, the state of the KMS key changes to
    # `Enabled`, and you can use the KMS key in cryptographic operations.
    # For symmetric encryption keys, you will need to import all of the key
    # materials associated with the KMS key to change its state to
    # `Enabled`. Use the `ListKeyRotations` operation to list the ID and
    # import state of each key material associated with a KMS key.
    #
    # If this operation fails, use the exception to help determine the
    # problem. If the error is related to the key material, the import
    # token, or wrapping key, use GetParametersForImport to get a new public
    # key and import token for the KMS key and repeat the import procedure.
    # For help, see [Create a KMS key with imported key material][7] in the
    # *Key Management Service Developer Guide*.
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][8] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: No. You cannot perform this operation on a KMS
    # key in a different Amazon Web Services account.
    #
    # **Required permissions**: [kms:ImportKeyMaterial][9] (key policy)
    #
    # **Related operations:**
    #
    # * DeleteImportedKeyMaterial
    #
    # * GetParametersForImport
    #
    # * ListKeyRotations
    #
    # * RotateKeyOnDemand
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][10].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys-import-key-material.html#reimport-key-material
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys-import-key-material.html#importing-keys-import-key-material-console
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-overview.html
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/key-store-overview.html
    # [6]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys-import-key-material.html#importing-keys-expiration
    # [7]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys-conceptual.html
    # [8]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [9]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [10]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   The identifier of the KMS key that will be associated with the
    #   imported key material. This must be the same KMS key specified in the
    #   `KeyID` parameter of the corresponding GetParametersForImport request.
    #   The `Origin` of the KMS key must be `EXTERNAL` and its `KeyState` must
    #   be `PendingImport`.
    #
    #   The KMS key can be a symmetric encryption KMS key, HMAC KMS key,
    #   asymmetric encryption KMS key, or asymmetric signing KMS key,
    #   including a [multi-Region key][1] of any supported type. You cannot
    #   perform this operation on a KMS key in a custom key store, or on a KMS
    #   key in a different Amazon Web Services account.
    #
    #   Specify the key ID or key ARN of the KMS key.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-overview.html
    #
    # @option params [required, String, StringIO, File] :import_token
    #   The import token that you received in the response to a previous
    #   GetParametersForImport request. It must be from the same response that
    #   contained the public key that you used to encrypt the key material.
    #
    # @option params [required, String, StringIO, File] :encrypted_key_material
    #   The encrypted key material to import. The key material must be
    #   encrypted under the public wrapping key that GetParametersForImport
    #   returned, using the wrapping algorithm that you specified in the same
    #   `GetParametersForImport` request.
    #
    # @option params [Time,DateTime,Date,Integer,String] :valid_to
    #   The date and time when the imported key material expires. This
    #   parameter is required when the value of the `ExpirationModel`
    #   parameter is `KEY_MATERIAL_EXPIRES`. Otherwise it is not valid.
    #
    #   The value of this parameter must be a future date and time. The
    #   maximum value is 365 days from the request date.
    #
    #   When the key material expires, KMS deletes the key material from the
    #   KMS key. Without its key material, the KMS key is unusable. To use the
    #   KMS key in cryptographic operations, you must reimport the same key
    #   material.
    #
    #   You cannot change the `ExpirationModel` or `ValidTo` values for the
    #   current import after the request completes. To change either value,
    #   you must delete (DeleteImportedKeyMaterial) and reimport the key
    #   material.
    #
    # @option params [String] :expiration_model
    #   Specifies whether the key material expires. The default is
    #   `KEY_MATERIAL_EXPIRES`. For help with this choice, see [Setting an
    #   expiration time][1] in the *Key Management Service Developer Guide*.
    #
    #   When the value of `ExpirationModel` is `KEY_MATERIAL_EXPIRES`, you
    #   must specify a value for the `ValidTo` parameter. When value is
    #   `KEY_MATERIAL_DOES_NOT_EXPIRE`, you must omit the `ValidTo` parameter.
    #
    #   You cannot change the `ExpirationModel` or `ValidTo` values for the
    #   current import after the request completes. To change either value,
    #   you must reimport the key material.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys-import-key-material.html#importing-keys-expiration
    #
    # @option params [String] :import_type
    #   Indicates whether the key material being imported is previously
    #   associated with this KMS key or not. This parameter is optional and
    #   only usable with symmetric encryption keys. If no key material has
    #   ever been imported into the KMS key, and this parameter is omitted,
    #   the parameter defaults to `NEW_KEY_MATERIAL`. After the first key
    #   material is imported, if this parameter is omitted then the parameter
    #   defaults to `EXISTING_KEY_MATERIAL`.
    #
    #   For multi-Region keys, you must first import new key material into the
    #   primary Region key. You should use the `NEW_KEY_MATERIAL` import type
    #   when importing key material into the primary Region key. Then, you can
    #   import the same key material into the replica Region key. The import
    #   type for the replica Region key should be `EXISTING_KEY_MATERIAL`.
    #
    # @option params [String] :key_material_description
    #   Description for the key material being imported. This parameter is
    #   optional and only usable with symmetric encryption keys. If you do not
    #   specify a key material description, KMS retains the value you
    #   specified when you last imported the same key material into this KMS
    #   key.
    #
    # @option params [String] :key_material_id
    #   Identifies the key material being imported. This parameter is optional
    #   and only usable with symmetric encryption keys. You cannot specify a
    #   key material ID with `ImportType` set to `NEW_KEY_MATERIAL`. Whenever
    #   you import key material into a symmetric encryption key, KMS assigns a
    #   unique identifier to the key material based on the KMS key ID and the
    #   imported key material. When you re-import key material with a
    #   specified key material ID, KMS:
    #
    #   * Computes the identifier for the key material
    #
    #   * Matches the computed identifier against the specified key material
    #     ID
    #
    #   * Verifies that the key material ID is already associated with the KMS
    #     key
    #
    #   To get the list of key material IDs associated with a KMS key, use
    #   ListKeyRotations.
    #
    # @return [Types::ImportKeyMaterialResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ImportKeyMaterialResponse#key_id #key_id} => String
    #   * {Types::ImportKeyMaterialResponse#key_material_id #key_material_id} => String
    #
    #
    # @example Example: To import key material into a KMS key
    #
    #   # The following example imports key material into the specified KMS key.
    #
    #   resp = client.import_key_material({
    #     encrypted_key_material: "<binary data>", # The encrypted key material to import.
    #     expiration_model: "KEY_MATERIAL_DOES_NOT_EXPIRE", # A value that specifies whether the key material expires.
    #     import_token: "<binary data>", # The import token that you received in the response to a previous GetParametersForImport request.
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key to import the key material into. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The Amazon Resource Name (ARN) of the KMS key into which key material was imported.
    #     key_material_id: "0b7fd7ddbac6eef27907413567cad8c810e2883dc8a7534067a82ee1142fc1e6", # Identifies the imported key material.
    #   }
    #
    # @example Example: To import key material into a KMS key
    #
    #   # The following example imports key material that expires in 3 days. It might be part of an application that frequently
    #   # reimports the same key material to comply with business rules or regulations.
    #
    #   resp = client.import_key_material({
    #     encrypted_key_material: "<binary data>", # The encrypted key material to import.
    #     expiration_model: "KEY_MATERIAL_EXPIRES", # A value that specifies whether the key material expires.
    #     import_token: "<binary data>", # The import token that you received in the response to a previous GetParametersForImport request.
    #     key_id: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key to import the key material into. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #     valid_to: Time.parse("2023-09-30T00:00:00-00:00"), # Specifies the date and time when the imported key material expires.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The Amazon Resource Name (ARN) of the KMS key into which key material was imported.
    #     key_material_id: "0b7fd7ddbac6eef27907413567cad8c810e2883dc8a7534067a82ee1142fc1e6", # Identifies the imported key material.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.import_key_material({
    #     key_id: "KeyIdType", # required
    #     import_token: "data", # required
    #     encrypted_key_material: "data", # required
    #     valid_to: Time.now,
    #     expiration_model: "KEY_MATERIAL_EXPIRES", # accepts KEY_MATERIAL_EXPIRES, KEY_MATERIAL_DOES_NOT_EXPIRE
    #     import_type: "NEW_KEY_MATERIAL", # accepts NEW_KEY_MATERIAL, EXISTING_KEY_MATERIAL
    #     key_material_description: "KeyMaterialDescriptionType",
    #     key_material_id: "BackingKeyIdType",
    #   })
    #
    # @example Response structure
    #
    #   resp.key_id #=> String
    #   resp.key_material_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ImportKeyMaterial AWS API Documentation
    #
    # @overload import_key_material(params = {})
    # @param [Hash] params ({})
    def import_key_material(params = {}, options = {})
      req = build_request(:import_key_material, params)
      req.send_request(options)
    end

    # Gets a list of aliases in the caller's Amazon Web Services account
    # and region. For more information about aliases, see CreateAlias.
    #
    # By default, the `ListAliases` operation returns all aliases in the
    # account and region. To get only the aliases associated with a
    # particular KMS key, use the `KeyId` parameter.
    #
    # The `ListAliases` response can include aliases that you created and
    # associated with your customer managed keys, and aliases that Amazon
    # Web Services created and associated with Amazon Web Services managed
    # keys in your account. You can recognize Amazon Web Services aliases
    # because their names have the format `aws/<service-name>`, such as
    # `aws/dynamodb`.
    #
    # The response might also include aliases that have no `TargetKeyId`
    # field. These are predefined aliases that Amazon Web Services has
    # created but has not yet associated with a KMS key. Aliases that Amazon
    # Web Services creates in your account, including predefined aliases, do
    # not count against your [KMS aliases quota][1].
    #
    # **Cross-account use**: No. `ListAliases` does not return aliases in
    # other Amazon Web Services accounts.
    #
    # **Required permissions**: [kms:ListAliases][2] (IAM policy)
    #
    # For details, see [Controlling access to aliases][3] in the *Key
    # Management Service Developer Guide*.
    #
    # **Related operations:**
    #
    # * CreateAlias
    #
    # * DeleteAlias
    #
    # * UpdateAlias
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][4].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/resource-limits.html#aliases-per-key
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/alias-access.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [String] :key_id
    #   Lists only aliases that are associated with the specified KMS key.
    #   Enter a KMS key in your Amazon Web Services account.
    #
    #   This parameter is optional. If you omit it, `ListAliases` returns all
    #   aliases in the account and Region.
    #
    #   Specify the key ID or key ARN of the KMS key.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    # @option params [Integer] :limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    #   This value is optional. If you include a value, it must be between 1
    #   and 100, inclusive. If you do not include a value, it defaults to 50.
    #
    # @option params [String] :marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #
    # @return [Types::ListAliasesResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListAliasesResponse#aliases #aliases} => Array&lt;Types::AliasListEntry&gt;
    #   * {Types::ListAliasesResponse#next_marker #next_marker} => String
    #   * {Types::ListAliasesResponse#truncated #truncated} => Boolean
    #
    # The returned {Seahorse::Client::Response response} is a pageable response and is Enumerable. For details on usage see {Aws::PageableResponse PageableResponse}.
    #
    #
    # @example Example: To list aliases
    #
    #   # The following example lists aliases.
    #
    #   resp = client.list_aliases({
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     aliases: [
    #       {
    #         alias_arn: "arn:aws:kms:us-east-2:111122223333:alias/aws/acm", 
    #         alias_name: "alias/aws/acm", 
    #         target_key_id: "da03f6f7-d279-427a-9cae-de48d07e5b66", 
    #       }, 
    #       {
    #         alias_arn: "arn:aws:kms:us-east-2:111122223333:alias/aws/ebs", 
    #         alias_name: "alias/aws/ebs", 
    #         target_key_id: "25a217e7-7170-4b8c-8bf6-045ea5f70e5b", 
    #       }, 
    #       {
    #         alias_arn: "arn:aws:kms:us-east-2:111122223333:alias/aws/rds", 
    #         alias_name: "alias/aws/rds", 
    #         target_key_id: "7ec3104e-c3f2-4b5c-bf42-bfc4772c6685", 
    #       }, 
    #       {
    #         alias_arn: "arn:aws:kms:us-east-2:111122223333:alias/aws/redshift", 
    #         alias_name: "alias/aws/redshift", 
    #         target_key_id: "08f7a25a-69e2-4fb5-8f10-393db27326fa", 
    #       }, 
    #       {
    #         alias_arn: "arn:aws:kms:us-east-2:111122223333:alias/aws/s3", 
    #         alias_name: "alias/aws/s3", 
    #         target_key_id: "d2b0f1a3-580d-4f79-b836-bc983be8cfa5", 
    #       }, 
    #       {
    #         alias_arn: "arn:aws:kms:us-east-2:111122223333:alias/example1", 
    #         alias_name: "alias/example1", 
    #         target_key_id: "4da1e216-62d0-46c5-a7c0-5f3a3d2f8046", 
    #       }, 
    #       {
    #         alias_arn: "arn:aws:kms:us-east-2:111122223333:alias/example2", 
    #         alias_name: "alias/example2", 
    #         target_key_id: "f32fef59-2cc2-445b-8573-2d73328acbee", 
    #       }, 
    #       {
    #         alias_arn: "arn:aws:kms:us-east-2:111122223333:alias/example3", 
    #         alias_name: "alias/example3", 
    #         target_key_id: "1374ef38-d34e-4d5f-b2c9-4e0daee38855", 
    #       }, 
    #     ], # A list of aliases, including the key ID of the KMS key that each alias refers to.
    #     truncated: false, # A boolean that indicates whether there are more items in the list. Returns true when there are more items, or false when there are not.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_aliases({
    #     key_id: "KeyIdType",
    #     limit: 1,
    #     marker: "MarkerType",
    #   })
    #
    # @example Response structure
    #
    #   resp.aliases #=> Array
    #   resp.aliases[0].alias_name #=> String
    #   resp.aliases[0].alias_arn #=> String
    #   resp.aliases[0].target_key_id #=> String
    #   resp.aliases[0].creation_date #=> Time
    #   resp.aliases[0].last_updated_date #=> Time
    #   resp.next_marker #=> String
    #   resp.truncated #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListAliases AWS API Documentation
    #
    # @overload list_aliases(params = {})
    # @param [Hash] params ({})
    def list_aliases(params = {}, options = {})
      req = build_request(:list_aliases, params)
      req.send_request(options)
    end

    # Gets a list of all grants for the specified KMS key.
    #
    # You must specify the KMS key in all requests. You can filter the grant
    # list by grant ID or grantee principal.
    #
    # For detailed information about grants, including grant terminology,
    # see [Grants in KMS][1] in the <i> <i>Key Management Service Developer
    # Guide</i> </i>. For examples of creating grants in several programming
    # languages, see [Use CreateGrant with an Amazon Web Services SDK or
    # CLI][2].
    #
    # <note markdown="1"> The `GranteePrincipal` field in the `ListGrants` response usually
    # contains the user or role designated as the grantee principal in the
    # grant. However, when the grantee principal in the grant is an Amazon
    # Web Services service, the `GranteePrincipal` field contains the
    # [service principal][3], which might represent several different
    # grantee principals.
    #
    #  </note>
    #
    # **Cross-account use**: Yes. To perform this operation on a KMS key in
    # a different Amazon Web Services account, specify the key ARN in the
    # value of the `KeyId` parameter.
    #
    # **Required permissions**: [kms:ListGrants][4] (key policy)
    #
    # **Related operations:**
    #
    # * CreateGrant
    #
    # * ListRetirableGrants
    #
    # * RetireGrant
    #
    # * RevokeGrant
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][5].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/example_kms_CreateGrant_section.html
    # [3]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html#principal-services
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [Integer] :limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    #   This value is optional. If you include a value, it must be between 1
    #   and 100, inclusive. If you do not include a value, it defaults to 50.
    #
    # @option params [String] :marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #
    # @option params [required, String] :key_id
    #   Returns only grants for the specified KMS key. This parameter is
    #   required.
    #
    #   Specify the key ID or key ARN of the KMS key. To specify a KMS key in
    #   a different Amazon Web Services account, you must use the key ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    # @option params [String] :grant_id
    #   Returns only the grant with the specified grant ID. The grant ID
    #   uniquely identifies the grant.
    #
    # @option params [String] :grantee_principal
    #   Returns only grants where the specified principal is the grantee
    #   principal for the grant.
    #
    # @return [Types::ListGrantsResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListGrantsResponse#grants #grants} => Array&lt;Types::GrantListEntry&gt;
    #   * {Types::ListGrantsResponse#next_marker #next_marker} => String
    #   * {Types::ListGrantsResponse#truncated #truncated} => Boolean
    #
    # The returned {Seahorse::Client::Response response} is a pageable response and is Enumerable. For details on usage see {Aws::PageableResponse PageableResponse}.
    #
    #
    # @example Example: To list grants for a KMS key
    #
    #   # The following example lists grants for the specified KMS key.
    #
    #   resp = client.list_grants({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key whose grants you want to list. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     grants: [
    #       {
    #         creation_date: Time.parse("2016-10-25T14:37:41-07:00"), 
    #         grant_id: "91ad875e49b04a9d1f3bdeb84d821f9db6ea95e1098813f6d47f0c65fbe2a172", 
    #         grantee_principal: "acm.us-east-2.amazonaws.com", 
    #         issuing_account: "arn:aws:iam::111122223333:root", 
    #         key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #         operations: [
    #           "Encrypt", 
    #           "ReEncryptFrom", 
    #           "ReEncryptTo", 
    #         ], 
    #         retiring_principal: "acm.us-east-2.amazonaws.com", 
    #       }, 
    #       {
    #         creation_date: Time.parse("2016-10-25T14:37:41-07:00"), 
    #         grant_id: "a5d67d3e207a8fc1f4928749ee3e52eb0440493a8b9cf05bbfad91655b056200", 
    #         grantee_principal: "acm.us-east-2.amazonaws.com", 
    #         issuing_account: "arn:aws:iam::111122223333:root", 
    #         key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #         operations: [
    #           "ReEncryptFrom", 
    #           "ReEncryptTo", 
    #         ], 
    #         retiring_principal: "acm.us-east-2.amazonaws.com", 
    #       }, 
    #       {
    #         creation_date: Time.parse("2016-10-25T14:37:41-07:00"), 
    #         grant_id: "c541aaf05d90cb78846a73b346fc43e65be28b7163129488c738e0c9e0628f4f", 
    #         grantee_principal: "acm.us-east-2.amazonaws.com", 
    #         issuing_account: "arn:aws:iam::111122223333:root", 
    #         key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #         operations: [
    #           "Encrypt", 
    #           "ReEncryptFrom", 
    #           "ReEncryptTo", 
    #         ], 
    #         retiring_principal: "acm.us-east-2.amazonaws.com", 
    #       }, 
    #       {
    #         creation_date: Time.parse("2016-10-25T14:37:41-07:00"), 
    #         grant_id: "dd2052c67b4c76ee45caf1dc6a1e2d24e8dc744a51b36ae2f067dc540ce0105c", 
    #         grantee_principal: "acm.us-east-2.amazonaws.com", 
    #         issuing_account: "arn:aws:iam::111122223333:root", 
    #         key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #         operations: [
    #           "Encrypt", 
    #           "ReEncryptFrom", 
    #           "ReEncryptTo", 
    #         ], 
    #         retiring_principal: "acm.us-east-2.amazonaws.com", 
    #       }, 
    #     ], # A list of grants.
    #     truncated: true, # A boolean that indicates whether there are more items in the list. Returns true when there are more items, or false when there are not.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_grants({
    #     limit: 1,
    #     marker: "MarkerType",
    #     key_id: "KeyIdType", # required
    #     grant_id: "GrantIdType",
    #     grantee_principal: "PrincipalIdType",
    #   })
    #
    # @example Response structure
    #
    #   resp.grants #=> Array
    #   resp.grants[0].key_id #=> String
    #   resp.grants[0].grant_id #=> String
    #   resp.grants[0].name #=> String
    #   resp.grants[0].creation_date #=> Time
    #   resp.grants[0].grantee_principal #=> String
    #   resp.grants[0].retiring_principal #=> String
    #   resp.grants[0].issuing_account #=> String
    #   resp.grants[0].operations #=> Array
    #   resp.grants[0].operations[0] #=> String, one of "Decrypt", "Encrypt", "GenerateDataKey", "GenerateDataKeyWithoutPlaintext", "ReEncryptFrom", "ReEncryptTo", "Sign", "Verify", "GetPublicKey", "CreateGrant", "RetireGrant", "DescribeKey", "GenerateDataKeyPair", "GenerateDataKeyPairWithoutPlaintext", "GenerateMac", "VerifyMac", "DeriveSharedSecret"
    #   resp.grants[0].constraints.encryption_context_subset #=> Hash
    #   resp.grants[0].constraints.encryption_context_subset["EncryptionContextKey"] #=> String
    #   resp.grants[0].constraints.encryption_context_equals #=> Hash
    #   resp.grants[0].constraints.encryption_context_equals["EncryptionContextKey"] #=> String
    #   resp.next_marker #=> String
    #   resp.truncated #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListGrants AWS API Documentation
    #
    # @overload list_grants(params = {})
    # @param [Hash] params ({})
    def list_grants(params = {}, options = {})
      req = build_request(:list_grants, params)
      req.send_request(options)
    end

    # Gets the names of the key policies that are attached to a KMS key.
    # This operation is designed to get policy names that you can use in a
    # GetKeyPolicy operation. However, the only valid policy name is
    # `default`.
    #
    # **Cross-account use**: No. You cannot perform this operation on a KMS
    # key in a different Amazon Web Services account.
    #
    # **Required permissions**: [kms:ListKeyPolicies][1] (key policy)
    #
    # **Related operations:**
    #
    # * GetKeyPolicy
    #
    # * [PutKeyPolicy][2]
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][3].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [2]: https://docs.aws.amazon.com/kms/latest/APIReference/API_PutKeyPolicy.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Gets the names of key policies for the specified KMS key.
    #
    #   Specify the key ID or key ARN of the KMS key.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    # @option params [Integer] :limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    #   This value is optional. If you include a value, it must be between 1
    #   and 1000, inclusive. If you do not include a value, it defaults to
    #   100.
    #
    #   Only one policy can be attached to a key.
    #
    # @option params [String] :marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #
    # @return [Types::ListKeyPoliciesResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListKeyPoliciesResponse#policy_names #policy_names} => Array&lt;String&gt;
    #   * {Types::ListKeyPoliciesResponse#next_marker #next_marker} => String
    #   * {Types::ListKeyPoliciesResponse#truncated #truncated} => Boolean
    #
    # The returned {Seahorse::Client::Response response} is a pageable response and is Enumerable. For details on usage see {Aws::PageableResponse PageableResponse}.
    #
    #
    # @example Example: To list key policies for a KMS key
    #
    #   # The following example lists key policies for the specified KMS key.
    #
    #   resp = client.list_key_policies({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key whose key policies you want to list. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     policy_names: [
    #       "default", 
    #     ], # A list of key policy names.
    #     truncated: false, # A boolean that indicates whether there are more items in the list. Returns true when there are more items, or false when there are not.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_key_policies({
    #     key_id: "KeyIdType", # required
    #     limit: 1,
    #     marker: "MarkerType",
    #   })
    #
    # @example Response structure
    #
    #   resp.policy_names #=> Array
    #   resp.policy_names[0] #=> String
    #   resp.next_marker #=> String
    #   resp.truncated #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListKeyPolicies AWS API Documentation
    #
    # @overload list_key_policies(params = {})
    # @param [Hash] params ({})
    def list_key_policies(params = {}, options = {})
      req = build_request(:list_key_policies, params)
      req.send_request(options)
    end

    # Returns information about the key materials associated with the
    # specified KMS key. You can use the optional `IncludeKeyMaterial`
    # parameter to control which key materials are included in the response.
    #
    # You must specify the KMS key in all requests. You can refine the key
    # rotations list by limiting the number of rotations returned.
    #
    # For detailed information about automatic and on-demand key rotations,
    # see [Rotate KMS keys][1] in the *Key Management Service Developer
    # Guide*.
    #
    # **Cross-account use**: No. You cannot perform this operation on a KMS
    # key in a different Amazon Web Services account.
    #
    # **Required permissions**: [kms:ListKeyRotations][2] (key policy)
    #
    # **Related operations:**
    #
    # * EnableKeyRotation
    #
    # * DeleteImportedKeyMaterial
    #
    # * DisableKeyRotation
    #
    # * GetKeyRotationStatus
    #
    # * ImportKeyMaterial
    #
    # * RotateKeyOnDemand
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][3].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Gets the key rotations for the specified KMS key.
    #
    #   Specify the key ID or key ARN of the KMS key.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    # @option params [String] :include_key_material
    #   Use this optional parameter to control which key materials associated
    #   with this key are listed in the response. The default value of this
    #   parameter is `ROTATIONS_ONLY`. If you omit this parameter, KMS returns
    #   information on the key materials created by automatic or on-demand key
    #   rotation. When you specify a value of `ALL_KEY_MATERIAL`, KMS adds the
    #   first key material and any imported key material pending rotation to
    #   the response. This parameter can only be used with KMS keys that
    #   support automatic or on-demand key rotation.
    #
    # @option params [Integer] :limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    #   This value is optional. If you include a value, it must be between 1
    #   and 1000, inclusive. If you do not include a value, it defaults to
    #   100.
    #
    # @option params [String] :marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #
    # @return [Types::ListKeyRotationsResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListKeyRotationsResponse#rotations #rotations} => Array&lt;Types::RotationsListEntry&gt;
    #   * {Types::ListKeyRotationsResponse#next_marker #next_marker} => String
    #   * {Types::ListKeyRotationsResponse#truncated #truncated} => Boolean
    #
    # The returned {Seahorse::Client::Response response} is a pageable response and is Enumerable. For details on usage see {Aws::PageableResponse PageableResponse}.
    #
    #
    # @example Example: To retrieve information about all completed key material rotations
    #
    #   # The following example returns information about all completed key material rotations for the specified KMS key.
    #
    #   resp = client.list_key_rotations({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     rotations: [
    #       {
    #         key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", 
    #         rotation_date: Time.parse("2024-03-02T10:11:36.564000+00:00"), 
    #         rotation_type: "AUTOMATIC", 
    #       }, 
    #       {
    #         key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", 
    #         rotation_date: Time.parse("2024-04-05T15:14:47.757000+00:00"), 
    #         rotation_type: "ON_DEMAND", 
    #       }, 
    #     ], # A list of key rotations.
    #     truncated: false, # A flag that indicates whether there are more items in the list. When the value is true, the list in this response is truncated. To get more items, pass the value of the NextMarker element in this response to the Marker parameter in a subsequent request.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_key_rotations({
    #     key_id: "KeyIdType", # required
    #     include_key_material: "ALL_KEY_MATERIAL", # accepts ALL_KEY_MATERIAL, ROTATIONS_ONLY
    #     limit: 1,
    #     marker: "MarkerType",
    #   })
    #
    # @example Response structure
    #
    #   resp.rotations #=> Array
    #   resp.rotations[0].key_id #=> String
    #   resp.rotations[0].key_material_id #=> String
    #   resp.rotations[0].key_material_description #=> String
    #   resp.rotations[0].import_state #=> String, one of "IMPORTED", "PENDING_IMPORT"
    #   resp.rotations[0].key_material_state #=> String, one of "NON_CURRENT", "CURRENT", "PENDING_ROTATION", "PENDING_MULTI_REGION_IMPORT_AND_ROTATION"
    #   resp.rotations[0].expiration_model #=> String, one of "KEY_MATERIAL_EXPIRES", "KEY_MATERIAL_DOES_NOT_EXPIRE"
    #   resp.rotations[0].valid_to #=> Time
    #   resp.rotations[0].rotation_date #=> Time
    #   resp.rotations[0].rotation_type #=> String, one of "AUTOMATIC", "ON_DEMAND"
    #   resp.next_marker #=> String
    #   resp.truncated #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListKeyRotations AWS API Documentation
    #
    # @overload list_key_rotations(params = {})
    # @param [Hash] params ({})
    def list_key_rotations(params = {}, options = {})
      req = build_request(:list_key_rotations, params)
      req.send_request(options)
    end

    # Gets a list of all KMS keys in the caller's Amazon Web Services
    # account and Region.
    #
    # **Cross-account use**: No. You cannot perform this operation on a KMS
    # key in a different Amazon Web Services account.
    #
    # **Required permissions**: [kms:ListKeys][1] (IAM policy)
    #
    # **Related operations:**
    #
    # * CreateKey
    #
    # * DescribeKey
    #
    # * ListAliases
    #
    # * ListResourceTags
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][2].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [Integer] :limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    #   This value is optional. If you include a value, it must be between 1
    #   and 1000, inclusive. If you do not include a value, it defaults to
    #   100.
    #
    # @option params [String] :marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #
    # @return [Types::ListKeysResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListKeysResponse#keys #keys} => Array&lt;Types::KeyListEntry&gt;
    #   * {Types::ListKeysResponse#next_marker #next_marker} => String
    #   * {Types::ListKeysResponse#truncated #truncated} => Boolean
    #
    # The returned {Seahorse::Client::Response response} is a pageable response and is Enumerable. For details on usage see {Aws::PageableResponse PageableResponse}.
    #
    #
    # @example Example: To list KMS keys
    #
    #   # The following example lists KMS keys.
    #
    #   resp = client.list_keys({
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     keys: [
    #       {
    #         key_arn: "arn:aws:kms:us-east-2:111122223333:key/0d990263-018e-4e65-a703-eff731de951e", 
    #         key_id: "0d990263-018e-4e65-a703-eff731de951e", 
    #       }, 
    #       {
    #         key_arn: "arn:aws:kms:us-east-2:111122223333:key/144be297-0ae1-44ac-9c8f-93cd8c82f841", 
    #         key_id: "144be297-0ae1-44ac-9c8f-93cd8c82f841", 
    #       }, 
    #       {
    #         key_arn: "arn:aws:kms:us-east-2:111122223333:key/21184251-b765-428e-b852-2c7353e72571", 
    #         key_id: "21184251-b765-428e-b852-2c7353e72571", 
    #       }, 
    #       {
    #         key_arn: "arn:aws:kms:us-east-2:111122223333:key/214fe92f-5b03-4ae1-b350-db2a45dbe10c", 
    #         key_id: "214fe92f-5b03-4ae1-b350-db2a45dbe10c", 
    #       }, 
    #       {
    #         key_arn: "arn:aws:kms:us-east-2:111122223333:key/339963f2-e523-49d3-af24-a0fe752aa458", 
    #         key_id: "339963f2-e523-49d3-af24-a0fe752aa458", 
    #       }, 
    #       {
    #         key_arn: "arn:aws:kms:us-east-2:111122223333:key/b776a44b-df37-4438-9be4-a27494e4271a", 
    #         key_id: "b776a44b-df37-4438-9be4-a27494e4271a", 
    #       }, 
    #       {
    #         key_arn: "arn:aws:kms:us-east-2:111122223333:key/deaf6c9e-cf2c-46a6-bf6d-0b6d487cffbb", 
    #         key_id: "deaf6c9e-cf2c-46a6-bf6d-0b6d487cffbb", 
    #       }, 
    #     ], # A list of KMS keys, including the key ID and Amazon Resource Name (ARN) of each one.
    #     truncated: false, # A boolean that indicates whether there are more items in the list. Returns true when there are more items, or false when there are not.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_keys({
    #     limit: 1,
    #     marker: "MarkerType",
    #   })
    #
    # @example Response structure
    #
    #   resp.keys #=> Array
    #   resp.keys[0].key_id #=> String
    #   resp.keys[0].key_arn #=> String
    #   resp.next_marker #=> String
    #   resp.truncated #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListKeys AWS API Documentation
    #
    # @overload list_keys(params = {})
    # @param [Hash] params ({})
    def list_keys(params = {}, options = {})
      req = build_request(:list_keys, params)
      req.send_request(options)
    end

    # Returns all tags on the specified KMS key.
    #
    # For general information about tags, including the format and syntax,
    # see [Tagging Amazon Web Services resources][1] in the *Amazon Web
    # Services General Reference*. For information about using tags in KMS,
    # see [Tags in KMS][2].
    #
    # **Cross-account use**: No. You cannot perform this operation on a KMS
    # key in a different Amazon Web Services account.
    #
    # **Required permissions**: [kms:ListResourceTags][3] (key policy)
    #
    # **Related operations:**
    #
    # * CreateKey
    #
    # * ReplicateKey
    #
    # * TagResource
    #
    # * UntagResource
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][4].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/tagging-keys.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Gets tags on the specified KMS key.
    #
    #   Specify the key ID or key ARN of the KMS key.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    # @option params [Integer] :limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    #   This value is optional. If you include a value, it must be between 1
    #   and 50, inclusive. If you do not include a value, it defaults to 50.
    #
    # @option params [String] :marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #
    #   Do not attempt to construct this value. Use only the value of
    #   `NextMarker` from the truncated response you just received.
    #
    # @return [Types::ListResourceTagsResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListResourceTagsResponse#tags #tags} => Array&lt;Types::Tag&gt;
    #   * {Types::ListResourceTagsResponse#next_marker #next_marker} => String
    #   * {Types::ListResourceTagsResponse#truncated #truncated} => Boolean
    #
    # The returned {Seahorse::Client::Response response} is a pageable response and is Enumerable. For details on usage see {Aws::PageableResponse PageableResponse}.
    #
    #
    # @example Example: To list tags for a KMS key
    #
    #   # The following example lists tags for a KMS key.
    #
    #   resp = client.list_resource_tags({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key whose tags you are listing. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     tags: [
    #       {
    #         tag_key: "CostCenter", 
    #         tag_value: "87654", 
    #       }, 
    #       {
    #         tag_key: "CreatedBy", 
    #         tag_value: "ExampleUser", 
    #       }, 
    #       {
    #         tag_key: "Purpose", 
    #         tag_value: "Test", 
    #       }, 
    #     ], # A list of tags.
    #     truncated: false, # A boolean that indicates whether there are more items in the list. Returns true when there are more items, or false when there are not.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_resource_tags({
    #     key_id: "KeyIdType", # required
    #     limit: 1,
    #     marker: "MarkerType",
    #   })
    #
    # @example Response structure
    #
    #   resp.tags #=> Array
    #   resp.tags[0].tag_key #=> String
    #   resp.tags[0].tag_value #=> String
    #   resp.next_marker #=> String
    #   resp.truncated #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListResourceTags AWS API Documentation
    #
    # @overload list_resource_tags(params = {})
    # @param [Hash] params ({})
    def list_resource_tags(params = {}, options = {})
      req = build_request(:list_resource_tags, params)
      req.send_request(options)
    end

    # Returns information about all grants in the Amazon Web Services
    # account and Region that have the specified retiring principal.
    #
    # You can specify any principal in your Amazon Web Services account. The
    # grants that are returned include grants for KMS keys in your Amazon
    # Web Services account and other Amazon Web Services accounts. You might
    # use this operation to determine which grants you may retire. To retire
    # a grant, use the RetireGrant operation.
    #
    # For detailed information about grants, including grant terminology,
    # see [Grants in KMS][1] in the <i> <i>Key Management Service Developer
    # Guide</i> </i>. For examples of creating grants in several programming
    # languages, see [Use CreateGrant with an Amazon Web Services SDK or
    # CLI][2].
    #
    # **Cross-account use**: You must specify a principal in your Amazon Web
    # Services account. This operation returns a list of grants where the
    # retiring principal specified in the `ListRetirableGrants` request is
    # the same retiring principal on the grant. This can include grants on
    # KMS keys owned by other Amazon Web Services accounts, but you do not
    # need `kms:ListRetirableGrants` permission (or any other additional
    # permission) in any Amazon Web Services account other than your own.
    #
    # **Required permissions**: [kms:ListRetirableGrants][3] (IAM policy) in
    # your Amazon Web Services account.
    #
    # <note markdown="1"> KMS authorizes `ListRetirableGrants` requests by evaluating the caller
    # account's kms:ListRetirableGrants permissions. The authorized
    # resource in `ListRetirableGrants` calls is the retiring principal
    # specified in the request. KMS does not evaluate the caller's
    # permissions to verify their access to any KMS keys or grants that
    # might be returned by the `ListRetirableGrants` call.
    #
    #  </note>
    #
    # **Related operations:**
    #
    # * CreateGrant
    #
    # * ListGrants
    #
    # * RetireGrant
    #
    # * RevokeGrant
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][4].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/example_kms_CreateGrant_section.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [Integer] :limit
    #   Use this parameter to specify the maximum number of items to return.
    #   When this value is present, KMS does not return more than the
    #   specified number of items, but it might return fewer.
    #
    #   This value is optional. If you include a value, it must be between 1
    #   and 100, inclusive. If you do not include a value, it defaults to 50.
    #
    # @option params [String] :marker
    #   Use this parameter in a subsequent request after you receive a
    #   response with truncated results. Set it to the value of `NextMarker`
    #   from the truncated response you just received.
    #
    # @option params [required, String] :retiring_principal
    #   The retiring principal for which to list grants. Enter a principal in
    #   your Amazon Web Services account.
    #
    #   To specify the retiring principal, use the [Amazon Resource Name
    #   (ARN)][1] of an Amazon Web Services principal. Valid principals
    #   include Amazon Web Services accounts, IAM users, IAM roles, federated
    #   users, and assumed role users. For help with the ARN syntax for a
    #   principal, see [IAM ARNs][2] in the <i> <i>Identity and Access
    #   Management User Guide</i> </i>.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html#identifiers-arns
    #
    # @return [Types::ListGrantsResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListGrantsResponse#grants #grants} => Array&lt;Types::GrantListEntry&gt;
    #   * {Types::ListGrantsResponse#next_marker #next_marker} => String
    #   * {Types::ListGrantsResponse#truncated #truncated} => Boolean
    #
    # The returned {Seahorse::Client::Response response} is a pageable response and is Enumerable. For details on usage see {Aws::PageableResponse PageableResponse}.
    #
    #
    # @example Example: To list grants that the specified principal can retire
    #
    #   # The following example lists the grants that the specified principal (identity) can retire.
    #
    #   resp = client.list_retirable_grants({
    #     retiring_principal: "arn:aws:iam::111122223333:role/ExampleRole", # The retiring principal whose grants you want to list. Use the Amazon Resource Name (ARN) of a principal such as an AWS account (root), IAM user, federated user, or assumed role user.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     grants: [
    #       {
    #         creation_date: Time.parse("2016-12-07T11:09:35-08:00"), 
    #         grant_id: "0c237476b39f8bc44e45212e08498fbe3151305030726c0590dd8d3e9f3d6a60", 
    #         grantee_principal: "arn:aws:iam::111122223333:role/ExampleRole", 
    #         issuing_account: "arn:aws:iam::444455556666:root", 
    #         key_id: "arn:aws:kms:us-east-2:444455556666:key/1234abcd-12ab-34cd-56ef-1234567890ab", 
    #         operations: [
    #           "Decrypt", 
    #           "Encrypt", 
    #         ], 
    #         retiring_principal: "arn:aws:iam::111122223333:role/ExampleRole", 
    #       }, 
    #     ], # A list of grants that the specified principal can retire.
    #     truncated: false, # A boolean that indicates whether there are more items in the list. Returns true when there are more items, or false when there are not.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_retirable_grants({
    #     limit: 1,
    #     marker: "MarkerType",
    #     retiring_principal: "PrincipalIdType", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.grants #=> Array
    #   resp.grants[0].key_id #=> String
    #   resp.grants[0].grant_id #=> String
    #   resp.grants[0].name #=> String
    #   resp.grants[0].creation_date #=> Time
    #   resp.grants[0].grantee_principal #=> String
    #   resp.grants[0].retiring_principal #=> String
    #   resp.grants[0].issuing_account #=> String
    #   resp.grants[0].operations #=> Array
    #   resp.grants[0].operations[0] #=> String, one of "Decrypt", "Encrypt", "GenerateDataKey", "GenerateDataKeyWithoutPlaintext", "ReEncryptFrom", "ReEncryptTo", "Sign", "Verify", "GetPublicKey", "CreateGrant", "RetireGrant", "DescribeKey", "GenerateDataKeyPair", "GenerateDataKeyPairWithoutPlaintext", "GenerateMac", "VerifyMac", "DeriveSharedSecret"
    #   resp.grants[0].constraints.encryption_context_subset #=> Hash
    #   resp.grants[0].constraints.encryption_context_subset["EncryptionContextKey"] #=> String
    #   resp.grants[0].constraints.encryption_context_equals #=> Hash
    #   resp.grants[0].constraints.encryption_context_equals["EncryptionContextKey"] #=> String
    #   resp.next_marker #=> String
    #   resp.truncated #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ListRetirableGrants AWS API Documentation
    #
    # @overload list_retirable_grants(params = {})
    # @param [Hash] params ({})
    def list_retirable_grants(params = {}, options = {})
      req = build_request(:list_retirable_grants, params)
      req.send_request(options)
    end

    # Attaches a key policy to the specified KMS key.
    #
    # For more information about key policies, see [Key Policies][1] in the
    # *Key Management Service Developer Guide*. For help writing and
    # formatting a JSON policy document, see the [IAM JSON Policy
    # Reference][2] in the <i> <i>Identity and Access Management User
    # Guide</i> </i>. For examples of adding a key policy in multiple
    # programming languages, see [Use PutKeyPolicy with an Amazon Web
    # Services SDK or CLI][3] in the *Key Management Service Developer
    # Guide*.
    #
    # **Cross-account use**: No. You cannot perform this operation on a KMS
    # key in a different Amazon Web Services account.
    #
    # **Required permissions**: [kms:PutKeyPolicy][4] (key policy)
    #
    # **Related operations**: GetKeyPolicy
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][5].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html
    # [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/example_kms_PutKeyPolicy_section.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Sets the key policy on the specified KMS key.
    #
    #   Specify the key ID or key ARN of the KMS key.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    # @option params [String] :policy_name
    #   The name of the key policy. If no policy name is specified, the
    #   default value is `default`. The only valid value is `default`.
    #
    # @option params [required, String] :policy
    #   The key policy to attach to the KMS key.
    #
    #   The key policy must meet the following criteria:
    #
    #   * The key policy must allow the calling principal to make a subsequent
    #     `PutKeyPolicy` request on the KMS key. This reduces the risk that
    #     the KMS key becomes unmanageable. For more information, see [Default
    #     key policy][1] in the *Key Management Service Developer Guide*. (To
    #     omit this condition, set `BypassPolicyLockoutSafetyCheck` to true.)
    #
    #   * Each statement in the key policy must contain one or more
    #     principals. The principals in the key policy must exist and be
    #     visible to KMS. When you create a new Amazon Web Services principal,
    #     you might need to enforce a delay before including the new principal
    #     in a key policy because the new principal might not be immediately
    #     visible to KMS. For more information, see [Changes that I make are
    #     not always immediately visible][2] in the *Amazon Web Services
    #     Identity and Access Management User Guide*.
    #
    #   <note markdown="1"> If either of the required `Resource` or `Action` elements are missing
    #   from a key policy statement, the policy statement has no effect. When
    #   a key policy statement is missing one of these elements, the KMS
    #   console correctly reports an error, but the `PutKeyPolicy` API request
    #   succeeds, even though the policy statement is ineffective.
    #
    #    For more information on required key policy elements, see [Elements in
    #   a key policy][3] in the *Key Management Service Developer Guide*.
    #
    #    </note>
    #
    #   A key policy document can include only the following characters:
    #
    #   * Printable ASCII characters from the space character (`\u0020`)
    #     through the end of the ASCII character range.
    #
    #   * Printable characters in the Basic Latin and Latin-1 Supplement
    #     character set (through `\u00FF`).
    #
    #   * The tab (`\u0009`), line feed (`\u000A`), and carriage return
    #     (`\u000D`) special characters
    #
    #   <note markdown="1"> If the key policy exceeds the length constraint, KMS returns a
    #   `LimitExceededException`.
    #
    #    </note>
    #
    #   For information about key policies, see [Key policies in KMS][4] in
    #   the *Key Management Service Developer Guide*.For help writing and
    #   formatting a JSON policy document, see the [IAM JSON Policy
    #   Reference][5] in the <i> <i>Identity and Access Management User
    #   Guide</i> </i>.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#prevent-unmanageable-key
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_eventual-consistency
    #   [3]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-overview.html#key-policy-elements
    #   [4]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html
    #   [5]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html
    #
    # @option params [Boolean] :bypass_policy_lockout_safety_check
    #   Skips ("bypasses") the key policy lockout safety check. The default
    #   value is false.
    #
    #   Setting this value to true increases the risk that the KMS key becomes
    #   unmanageable. Do not set this value to true indiscriminately.
    #
    #    For more information, see [Default key policy][1] in the *Key
    #   Management Service Developer Guide*.
    #
    #   Use this parameter only when you intend to prevent the principal that
    #   is making the request from making a subsequent [PutKeyPolicy][2]
    #   request on the KMS key.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#prevent-unmanageable-key
    #   [2]: https://docs.aws.amazon.com/kms/latest/APIReference/API_PutKeyPolicy.html
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To attach a key policy to a KMS key
    #
    #   # The following example attaches a key policy to the specified KMS key.
    #
    #   resp = client.put_key_policy({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key to attach the key policy to. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #     policy: "{\"Version\":\"2012-10-17\",\"Id\":\"custom-policy-2016-12-07\",\"Statement\":[{\"Sid\":\"EnableIAMUserPermissions\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::111122223333:root\"},\"Action\":\"kms:*\",\"Resource\":\"*\"},{\"Sid\":\"AllowaccessforKeyAdministrators\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":[\"arn:aws:iam::111122223333:user/ExampleAdminUser\",\"arn:aws:iam::111122223333:role/ExampleAdminRole\"]},\"Action\":[\"kms:Create*\",\"kms:Describe*\",\"kms:Enable*\",\"kms:List*\",\"kms:Put*\",\"kms:Update*\",\"kms:Revoke*\",\"kms:Disable*\",\"kms:Get*\",\"kms:Delete*\",\"kms:ScheduleKeyDeletion\",\"kms:CancelKeyDeletion\"],\"Resource\":\"*\"},{\"Sid\":\"Allowuseofthekey\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::111122223333:role/ExamplePowerUserRole\"},\"Action\":[\"kms:Encrypt\",\"kms:Decrypt\",\"kms:ReEncrypt*\",\"kms:GenerateDataKey*\",\"kms:DescribeKey\"],\"Resource\":\"*\"},{\"Sid\":\"Allowattachmentofpersistentresources\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::111122223333:role/ExamplePowerUserRole\"},\"Action\":[\"kms:CreateGrant\",\"kms:ListGrants\",\"kms:RevokeGrant\"],\"Resource\":\"*\",\"Condition\":{\"Bool\":{\"kms:GrantIsForAWSResource\":\"true\"}}}]}", # The key policy document.
    #     policy_name: "default", # The name of the key policy.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_key_policy({
    #     key_id: "KeyIdType", # required
    #     policy_name: "PolicyNameType",
    #     policy: "PolicyType", # required
    #     bypass_policy_lockout_safety_check: false,
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/PutKeyPolicy AWS API Documentation
    #
    # @overload put_key_policy(params = {})
    # @param [Hash] params ({})
    def put_key_policy(params = {}, options = {})
      req = build_request(:put_key_policy, params)
      req.send_request(options)
    end

    # Decrypts ciphertext and then reencrypts it entirely within KMS. You
    # can use this operation to change the KMS key under which data is
    # encrypted, such as when you [manually rotate][1] a KMS key or change
    # the KMS key that protects a ciphertext. You can also use it to
    # reencrypt ciphertext under the same KMS key, such as to change the
    # [encryption context][2] of a ciphertext.
    #
    # The `ReEncrypt` operation can decrypt ciphertext that was encrypted by
    # using a KMS key in an KMS operation, such as Encrypt or
    # GenerateDataKey. It can also decrypt ciphertext that was encrypted by
    # using the public key of an [asymmetric KMS key][3] outside of KMS.
    # However, it cannot decrypt ciphertext produced by other libraries,
    # such as the [Amazon Web Services Encryption SDK][4] or [Amazon S3
    # client-side encryption][5]. These libraries return a ciphertext format
    # that is incompatible with KMS.
    #
    # When you use the `ReEncrypt` operation, you need to provide
    # information for the decrypt operation and the subsequent encrypt
    # operation.
    #
    # * If your ciphertext was encrypted under an asymmetric KMS key, you
    #   must use the `SourceKeyId` parameter to identify the KMS key that
    #   encrypted the ciphertext. You must also supply the encryption
    #   algorithm that was used. This information is required to decrypt the
    #   data.
    #
    # * If your ciphertext was encrypted under a symmetric encryption KMS
    #   key, the `SourceKeyId` parameter is optional. KMS can get this
    #   information from metadata that it adds to the symmetric ciphertext
    #   blob. This feature adds durability to your implementation by
    #   ensuring that authorized users can decrypt ciphertext decades after
    #   it was encrypted, even if they've lost track of the key ID.
    #   However, specifying the source KMS key is always recommended as a
    #   best practice. When you use the `SourceKeyId` parameter to specify a
    #   KMS key, KMS uses only the KMS key you specify. If the ciphertext
    #   was encrypted under a different KMS key, the `ReEncrypt` operation
    #   fails. This practice ensures that you use the KMS key that you
    #   intend.
    #
    # * To reencrypt the data, you must use the `DestinationKeyId` parameter
    #   to specify the KMS key that re-encrypts the data after it is
    #   decrypted. If the destination KMS key is an asymmetric KMS key, you
    #   must also provide the encryption algorithm. The algorithm that you
    #   choose must be compatible with the KMS key.
    #
    #   When you use an asymmetric KMS key to encrypt or reencrypt data, be
    #   sure to record the KMS key and encryption algorithm that you choose.
    #   You will be required to provide the same KMS key and encryption
    #   algorithm when you decrypt the data. If the KMS key and algorithm do
    #   not match the values used to encrypt the data, the decrypt operation
    #   fails.
    #
    #    You are not required to supply the key ID and encryption algorithm
    #   when you decrypt with symmetric encryption KMS keys because KMS
    #   stores this information in the ciphertext blob. KMS cannot store
    #   metadata in ciphertext generated with asymmetric keys. The standard
    #   format for asymmetric key ciphertext does not include configurable
    #   fields.
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][6] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: Yes. The source KMS key and destination KMS key
    # can be in different Amazon Web Services accounts. Either or both KMS
    # keys can be in a different account than the caller. To specify a KMS
    # key in a different account, you must use its key ARN or alias ARN.
    #
    # **Required permissions**:
    #
    # * [kms:ReEncryptFrom][7] permission on the source KMS key (key policy)
    #
    # * [kms:ReEncryptTo][7] permission on the destination KMS key (key
    #   policy)
    #
    # To permit reencryption from or to a KMS key, include the
    # `"kms:ReEncrypt*"` permission in your [key policy][8]. This permission
    # is automatically included in the key policy when you use the console
    # to create a KMS key. But you must include it manually when you create
    # a KMS key programmatically or when you use the PutKeyPolicy operation
    # to set a key policy.
    #
    # **Related operations:**
    #
    # * Decrypt
    #
    # * Encrypt
    #
    # * GenerateDataKey
    #
    # * GenerateDataKeyPair
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][9].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys-manually.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/encrypt_context.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html
    # [4]: https://docs.aws.amazon.com/encryption-sdk/latest/developer-guide/
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingClientSideEncryption.html
    # [6]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [7]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [8]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html
    # [9]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [String, StringIO, File] :ciphertext_blob
    #   Ciphertext of the data to reencrypt.
    #
    #   This parameter is required in all cases except when `DryRun` is `true`
    #   and `DryRunModifiers` is set to `IGNORE_CIPHERTEXT`.
    #
    # @option params [Hash<String,String>] :source_encryption_context
    #   Specifies the encryption context to use to decrypt the ciphertext.
    #   Enter the same encryption context that was used to encrypt the
    #   ciphertext.
    #
    #   An *encryption context* is a collection of non-secret key-value pairs
    #   that represent additional authenticated data. When you use an
    #   encryption context to encrypt data, you must specify the same (an
    #   exact case-sensitive match) encryption context to decrypt the data. An
    #   encryption context is supported only on operations with symmetric
    #   encryption KMS keys. On operations with symmetric encryption KMS keys,
    #   an encryption context is optional, but it is strongly recommended.
    #
    #   For more information, see [Encryption context][1] in the *Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/encrypt_context.html
    #
    # @option params [String] :source_key_id
    #   Specifies the KMS key that KMS will use to decrypt the ciphertext
    #   before it is re-encrypted.
    #
    #   Enter a key ID of the KMS key that was used to encrypt the ciphertext.
    #   If you identify a different KMS key, the `ReEncrypt` operation throws
    #   an `IncorrectKeyException`.
    #
    #   This parameter is required only when the ciphertext was encrypted
    #   under an asymmetric KMS key or when `DryRun` is `true` and
    #   `DryRunModifiers` is set to `IGNORE_CIPHERTEXT`. If you used a
    #   symmetric encryption KMS key, KMS can get the KMS key from metadata
    #   that it adds to the symmetric ciphertext blob. However, it is always
    #   recommended as a best practice. This practice ensures that you use the
    #   KMS key that you intend.
    #
    #   To specify a KMS key, use its key ID, key ARN, alias name, or alias
    #   ARN. When using an alias name, prefix it with `"alias/"`. To specify a
    #   KMS key in a different Amazon Web Services account, you must use the
    #   key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey. To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [required, String] :destination_key_id
    #   A unique identifier for the KMS key that is used to reencrypt the
    #   data. Specify a symmetric encryption KMS key or an asymmetric KMS key
    #   with a `KeyUsage` value of `ENCRYPT_DECRYPT`. To find the `KeyUsage`
    #   value of a KMS key, use the DescribeKey operation.
    #
    #   To specify a KMS key, use its key ID, key ARN, alias name, or alias
    #   ARN. When using an alias name, prefix it with `"alias/"`. To specify a
    #   KMS key in a different Amazon Web Services account, you must use the
    #   key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey. To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [Hash<String,String>] :destination_encryption_context
    #   Specifies that encryption context to use when the reencrypting the
    #   data.
    #
    #   Do not include confidential or sensitive information in this field.
    #   This field may be displayed in plaintext in CloudTrail logs and other
    #   output.
    #
    #   A destination encryption context is valid only when the destination
    #   KMS key is a symmetric encryption KMS key. The standard ciphertext
    #   format for asymmetric KMS keys does not include fields for metadata.
    #
    #   An *encryption context* is a collection of non-secret key-value pairs
    #   that represent additional authenticated data. When you use an
    #   encryption context to encrypt data, you must specify the same (an
    #   exact case-sensitive match) encryption context to decrypt the data. An
    #   encryption context is supported only on operations with symmetric
    #   encryption KMS keys. On operations with symmetric encryption KMS keys,
    #   an encryption context is optional, but it is strongly recommended.
    #
    #   For more information, see [Encryption context][1] in the *Key
    #   Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/encrypt_context.html
    #
    # @option params [String] :source_encryption_algorithm
    #   Specifies the encryption algorithm that KMS will use to decrypt the
    #   ciphertext before it is reencrypted. The default value,
    #   `SYMMETRIC_DEFAULT`, represents the algorithm used for symmetric
    #   encryption KMS keys.
    #
    #   Specify the same algorithm that was used to encrypt the ciphertext. If
    #   you specify a different algorithm, the decrypt attempt fails.
    #
    #   This parameter is required only when the ciphertext was encrypted
    #   under an asymmetric KMS key.
    #
    # @option params [String] :destination_encryption_algorithm
    #   Specifies the encryption algorithm that KMS will use to reecrypt the
    #   data after it has decrypted it. The default value,
    #   `SYMMETRIC_DEFAULT`, represents the encryption algorithm used for
    #   symmetric encryption KMS keys.
    #
    #   This parameter is required only when the destination KMS key is an
    #   asymmetric KMS key.
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   Use a grant token when your permission to call this operation comes
    #   from a new grant that has not yet achieved *eventual consistency*. For
    #   more information, see [Grant token][1] and [Using a grant token][2] in
    #   the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html#grant_token
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/using-grant-token.html
    #
    # @option params [Boolean] :dry_run
    #   Checks if your request will succeed. `DryRun` is an optional
    #   parameter.
    #
    #   To learn more about how to use this parameter, see [Testing your
    #   permissions][1] in the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/testing-permissions.html
    #
    # @option params [Array<String>] :dry_run_modifiers
    #   Specifies the modifiers to apply to the dry run operation.
    #   `DryRunModifiers` is an optional parameter that only applies when
    #   `DryRun` is set to `true`.
    #
    #   When set to `IGNORE_CIPHERTEXT`, KMS performs only authorization
    #   validation without ciphertext validation. This allows you to test
    #   permissions without requiring a valid ciphertext blob.
    #
    #   To learn more about how to use this parameter, see [Testing your
    #   permissions][1] in the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/testing-permissions.html
    #
    # @return [Types::ReEncryptResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ReEncryptResponse#ciphertext_blob #ciphertext_blob} => String
    #   * {Types::ReEncryptResponse#source_key_id #source_key_id} => String
    #   * {Types::ReEncryptResponse#key_id #key_id} => String
    #   * {Types::ReEncryptResponse#source_encryption_algorithm #source_encryption_algorithm} => String
    #   * {Types::ReEncryptResponse#destination_encryption_algorithm #destination_encryption_algorithm} => String
    #   * {Types::ReEncryptResponse#source_key_material_id #source_key_material_id} => String
    #   * {Types::ReEncryptResponse#destination_key_material_id #destination_key_material_id} => String
    #
    #
    # @example Example: To reencrypt data
    #
    #   # The following example reencrypts data with the specified KMS key.
    #
    #   resp = client.re_encrypt({
    #     ciphertext_blob: "<binary data>", # The data to reencrypt.
    #     destination_key_id: "0987dcba-09fe-87dc-65ba-ab0987654321", # The identifier of the KMS key to use to reencrypt the data. You can use any valid key identifier.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     ciphertext_blob: "<binary data>", # The reencrypted data.
    #     destination_encryption_algorithm: "SYMMETRIC_DEFAULT", # The encryption algorithm that was used to reencrypt the data.
    #     destination_key_material_id: "0b7fd7ddbac6eef27907413567cad8c810e2883dc8a7534067a82ee1142fc1e6", # The identifier of the key material used to reencrypt the data.
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/0987dcba-09fe-87dc-65ba-ab0987654321", # The ARN of the KMS key that was used to reencrypt the data.
    #     source_encryption_algorithm: "SYMMETRIC_DEFAULT", # The encryption algorithm that was used to decrypt the ciphertext before it was reencrypted.
    #     source_key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The ARN of the KMS key that was originally used to encrypt the data.
    #     source_key_material_id: "1c6be7ddbac6eef27907413567cad8c810e2883dc8a7534067a82ee1142fc1e6", # The identifier of the key material used to originally encrypt the data.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.re_encrypt({
    #     ciphertext_blob: "data",
    #     source_encryption_context: {
    #       "EncryptionContextKey" => "EncryptionContextValue",
    #     },
    #     source_key_id: "KeyIdType",
    #     destination_key_id: "KeyIdType", # required
    #     destination_encryption_context: {
    #       "EncryptionContextKey" => "EncryptionContextValue",
    #     },
    #     source_encryption_algorithm: "SYMMETRIC_DEFAULT", # accepts SYMMETRIC_DEFAULT, RSAES_OAEP_SHA_1, RSAES_OAEP_SHA_256, SM2PKE
    #     destination_encryption_algorithm: "SYMMETRIC_DEFAULT", # accepts SYMMETRIC_DEFAULT, RSAES_OAEP_SHA_1, RSAES_OAEP_SHA_256, SM2PKE
    #     grant_tokens: ["GrantTokenType"],
    #     dry_run: false,
    #     dry_run_modifiers: ["IGNORE_CIPHERTEXT"], # accepts IGNORE_CIPHERTEXT
    #   })
    #
    # @example Response structure
    #
    #   resp.ciphertext_blob #=> String
    #   resp.source_key_id #=> String
    #   resp.key_id #=> String
    #   resp.source_encryption_algorithm #=> String, one of "SYMMETRIC_DEFAULT", "RSAES_OAEP_SHA_1", "RSAES_OAEP_SHA_256", "SM2PKE"
    #   resp.destination_encryption_algorithm #=> String, one of "SYMMETRIC_DEFAULT", "RSAES_OAEP_SHA_1", "RSAES_OAEP_SHA_256", "SM2PKE"
    #   resp.source_key_material_id #=> String
    #   resp.destination_key_material_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ReEncrypt AWS API Documentation
    #
    # @overload re_encrypt(params = {})
    # @param [Hash] params ({})
    def re_encrypt(params = {}, options = {})
      req = build_request(:re_encrypt, params)
      req.send_request(options)
    end

    # Replicates a multi-Region key into the specified Region. This
    # operation creates a multi-Region replica key based on a multi-Region
    # primary key in a different Region of the same Amazon Web Services
    # partition. You can create multiple replicas of a primary key, but each
    # must be in a different Region. To create a multi-Region primary key,
    # use the CreateKey operation.
    #
    # This operation supports *multi-Region keys*, an KMS feature that lets
    # you create multiple interoperable KMS keys in different Amazon Web
    # Services Regions. Because these KMS keys have the same key ID, key
    # material, and other metadata, you can use them interchangeably to
    # encrypt data in one Amazon Web Services Region and decrypt it in a
    # different Amazon Web Services Region without re-encrypting the data or
    # making a cross-Region call. For more information about multi-Region
    # keys, see [Multi-Region keys in KMS][1] in the *Key Management Service
    # Developer Guide*.
    #
    # A *replica key* is a fully-functional KMS key that can be used
    # independently of its primary and peer replica keys. A primary key and
    # its replica keys share properties that make them interoperable. They
    # have the same [key ID][2] and key material. They also have the same
    # key spec, key usage, key material origin, and automatic key rotation
    # status. KMS automatically synchronizes these shared properties among
    # related multi-Region keys. All other properties of a replica key can
    # differ, including its [key policy][3], [tags][4], [aliases][5], and
    # [key state][6]. KMS pricing and quotas for KMS keys apply to each
    # primary key and replica key.
    #
    # When this operation completes, the new replica key has a transient key
    # state of `Creating`. This key state changes to `Enabled` (or
    # `PendingImport`) after a few seconds when the process of creating the
    # new replica key is complete. While the key state is `Creating`, you
    # can manage key, but you cannot yet use it in cryptographic operations.
    # If you are creating and using the replica key programmatically, retry
    # on `KMSInvalidStateException` or call `DescribeKey` to check its
    # `KeyState` value before using it. For details about the `Creating` key
    # state, see [Key states of KMS keys][6] in the *Key Management Service
    # Developer Guide*.
    #
    # You cannot create more than one replica of a primary key in any
    # Region. If the Region already includes a replica of the key you're
    # trying to replicate, `ReplicateKey` returns an
    # `AlreadyExistsException` error. If the key state of the existing
    # replica is `PendingDeletion`, you can cancel the scheduled key
    # deletion (CancelKeyDeletion) or wait for the key to be deleted. The
    # new replica key you create will have the same [shared properties][7]
    # as the original replica key.
    #
    # The CloudTrail log of a `ReplicateKey` operation records a
    # `ReplicateKey` operation in the primary key's Region and a CreateKey
    # operation in the replica key's Region.
    #
    # If you replicate a multi-Region primary key with imported key
    # material, the replica key is created with no key material. You must
    # import the same key material that you imported into the primary key.
    #
    # To convert a replica key to a primary key, use the UpdatePrimaryRegion
    # operation.
    #
    # <note markdown="1"> `ReplicateKey` uses different default values for the `KeyPolicy` and
    # `Tags` parameters than those used in the KMS console. For details, see
    # the parameter descriptions.
    #
    #  </note>
    #
    # **Cross-account use**: No. You cannot use this operation to create a
    # replica key in a different Amazon Web Services account.
    #
    # **Required permissions**:
    #
    # * `kms:ReplicateKey` on the primary key (in the primary key's
    #   Region). Include this permission in the primary key's key policy.
    #
    # * `kms:CreateKey` in an IAM policy in the replica Region.
    #
    # * To use the `Tags` parameter, `kms:TagResource` in an IAM policy in
    #   the replica Region.
    #
    # **Related operations**
    #
    # * CreateKey
    #
    # * UpdatePrimaryRegion
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][8].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-overview.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#key-id-key-id
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/tagging-keys.html
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-alias.html
    # [6]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [7]: https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-overview.html#mrk-sync-properties
    # [8]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Identifies the multi-Region primary key that is being replicated. To
    #   determine whether a KMS key is a multi-Region primary key, use the
    #   DescribeKey operation to check the value of the `MultiRegionKeyType`
    #   property.
    #
    #   Specify the key ID or key ARN of a multi-Region primary key.
    #
    #   For example:
    #
    #   * Key ID: `mrk-1234abcd12ab34cd56ef1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/mrk-1234abcd12ab34cd56ef1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    # @option params [required, String] :replica_region
    #   The Region ID of the Amazon Web Services Region for this replica key.
    #
    #   Enter the Region ID, such as `us-east-1` or `ap-southeast-2`. For a
    #   list of Amazon Web Services Regions in which KMS is supported, see
    #   [KMS service endpoints][1] in the *Amazon Web Services General
    #   Reference*.
    #
    #   The replica must be in a different Amazon Web Services Region than its
    #   primary key and other replicas of that primary key, but in the same
    #   Amazon Web Services partition. KMS must be available in the replica
    #   Region. If the Region is not enabled by default, the Amazon Web
    #   Services account must be enabled in the Region. For information about
    #   Amazon Web Services partitions, see [Amazon Resource Names (ARNs)][2]
    #   in the *Amazon Web Services General Reference*. For information about
    #   enabling and disabling Regions, see [Enabling a Region][3] and
    #   [Disabling a Region][4] in the *Amazon Web Services General
    #   Reference*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/kms.html#kms_region
    #   [2]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
    #   [3]: https://docs.aws.amazon.com/general/latest/gr/rande-manage.html#rande-manage-enable
    #   [4]: https://docs.aws.amazon.com/general/latest/gr/rande-manage.html#rande-manage-disable
    #
    # @option params [String] :policy
    #   The key policy to attach to the KMS key. This parameter is optional.
    #   If you do not provide a key policy, KMS attaches the [default key
    #   policy][1] to the KMS key.
    #
    #   The key policy is not a shared property of multi-Region keys. You can
    #   specify the same key policy or a different key policy for each key in
    #   a set of related multi-Region keys. KMS does not synchronize this
    #   property.
    #
    #   If you provide a key policy, it must meet the following criteria:
    #
    #   * The key policy must allow the calling principal to make a subsequent
    #     `PutKeyPolicy` request on the KMS key. This reduces the risk that
    #     the KMS key becomes unmanageable. For more information, see [Default
    #     key policy][2] in the *Key Management Service Developer Guide*. (To
    #     omit this condition, set `BypassPolicyLockoutSafetyCheck` to true.)
    #
    #   * Each statement in the key policy must contain one or more
    #     principals. The principals in the key policy must exist and be
    #     visible to KMS. When you create a new Amazon Web Services principal,
    #     you might need to enforce a delay before including the new principal
    #     in a key policy because the new principal might not be immediately
    #     visible to KMS. For more information, see [Changes that I make are
    #     not always immediately visible][3] in the *Amazon Web Services
    #     Identity and Access Management User Guide*.
    #
    #   A key policy document can include only the following characters:
    #
    #   * Printable ASCII characters from the space character (`\u0020`)
    #     through the end of the ASCII character range.
    #
    #   * Printable characters in the Basic Latin and Latin-1 Supplement
    #     character set (through `\u00FF`).
    #
    #   * The tab (`\u0009`), line feed (`\u000A`), and carriage return
    #     (`\u000D`) special characters
    #
    #   For information about key policies, see [Key policies in KMS][4] in
    #   the *Key Management Service Developer Guide*. For help writing and
    #   formatting a JSON policy document, see the [IAM JSON Policy
    #   Reference][5] in the <i> <i>Identity and Access Management User
    #   Guide</i> </i>.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#prevent-unmanageable-key
    #   [3]: https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_eventual-consistency
    #   [4]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html
    #   [5]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html
    #
    # @option params [Boolean] :bypass_policy_lockout_safety_check
    #   Skips ("bypasses") the key policy lockout safety check. The default
    #   value is false.
    #
    #   Setting this value to true increases the risk that the KMS key becomes
    #   unmanageable. Do not set this value to true indiscriminately.
    #
    #    For more information, see [Default key policy][1] in the *Key
    #   Management Service Developer Guide*.
    #
    #   Use this parameter only when you intend to prevent the principal that
    #   is making the request from making a subsequent [PutKeyPolicy][2]
    #   request on the KMS key.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#prevent-unmanageable-key
    #   [2]: https://docs.aws.amazon.com/kms/latest/APIReference/API_PutKeyPolicy.html
    #
    # @option params [String] :description
    #   A description of the KMS key. The default value is an empty string (no
    #   description).
    #
    #   Do not include confidential or sensitive information in this field.
    #   This field may be displayed in plaintext in CloudTrail logs and other
    #   output.
    #
    #   The description is not a shared property of multi-Region keys. You can
    #   specify the same description or a different description for each key
    #   in a set of related multi-Region keys. KMS does not synchronize this
    #   property.
    #
    # @option params [Array<Types::Tag>] :tags
    #   Assigns one or more tags to the replica key. Use this parameter to tag
    #   the KMS key when it is created. To tag an existing KMS key, use the
    #   TagResource operation.
    #
    #   Do not include confidential or sensitive information in this field.
    #   This field may be displayed in plaintext in CloudTrail logs and other
    #   output.
    #
    #   <note markdown="1"> Tagging or untagging a KMS key can allow or deny permission to the KMS
    #   key. For details, see [ABAC for KMS][1] in the *Key Management Service
    #   Developer Guide*.
    #
    #    </note>
    #
    #   To use this parameter, you must have [kms:TagResource][2] permission
    #   in an IAM policy.
    #
    #   Tags are not a shared property of multi-Region keys. You can specify
    #   the same tags or different tags for each key in a set of related
    #   multi-Region keys. KMS does not synchronize this property.
    #
    #   Each tag consists of a tag key and a tag value. Both the tag key and
    #   the tag value are required, but the tag value can be an empty (null)
    #   string. You cannot have more than one tag on a KMS key with the same
    #   tag key. If you specify an existing tag key with a different tag
    #   value, KMS replaces the current tag value with the specified one.
    #
    #   When you add tags to an Amazon Web Services resource, Amazon Web
    #   Services generates a cost allocation report with usage and costs
    #   aggregated by tags. Tags can also be used to control access to a KMS
    #   key. For details, see [Tags in KMS][3].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/abac.html
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    #   [3]: https://docs.aws.amazon.com/kms/latest/developerguide/tagging-keys.html
    #
    # @return [Types::ReplicateKeyResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ReplicateKeyResponse#replica_key_metadata #replica_key_metadata} => Types::KeyMetadata
    #   * {Types::ReplicateKeyResponse#replica_policy #replica_policy} => String
    #   * {Types::ReplicateKeyResponse#replica_tags #replica_tags} => Array&lt;Types::Tag&gt;
    #
    #
    # @example Example: To replicate a multi-Region key in a different AWS Region
    #
    #   # This example creates a multi-Region replica key in us-west-2 of a multi-Region primary key in us-east-1.
    #
    #   resp = client.replicate_key({
    #     key_id: "arn:aws:kms:us-east-1:111122223333:key/mrk-1234abcd12ab34cd56ef1234567890ab", # The key ID or key ARN of the multi-Region primary key
    #     replica_region: "us-west-2", # The Region of the new replica.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     replica_key_metadata: {
    #       aws_account_id: "111122223333", 
    #       arn: "arn:aws:kms:us-west-2:111122223333:key/mrk-1234abcd12ab34cd56ef1234567890ab", 
    #       creation_date: Time.parse(1607472987.918), 
    #       customer_master_key_spec: "SYMMETRIC_DEFAULT", 
    #       description: "", 
    #       enabled: true, 
    #       encryption_algorithms: [
    #         "SYMMETRIC_DEFAULT", 
    #       ], 
    #       key_id: "mrk-1234abcd12ab34cd56ef1234567890ab", 
    #       key_manager: "CUSTOMER", 
    #       key_state: "Enabled", 
    #       key_usage: "ENCRYPT_DECRYPT", 
    #       multi_region: true, 
    #       multi_region_configuration: {
    #         multi_region_key_type: "REPLICA", 
    #         primary_key: {
    #           arn: "arn:aws:kms:us-east-1:111122223333:key/mrk-1234abcd12ab34cd56ef1234567890ab", 
    #           region: "us-east-1", 
    #         }, 
    #         replica_keys: [
    #           {
    #             arn: "arn:aws:kms:us-west-2:111122223333:key/mrk-1234abcd12ab34cd56ef1234567890ab", 
    #             region: "us-west-2", 
    #           }, 
    #         ], 
    #       }, 
    #       origin: "AWS_KMS", 
    #     }, # An object that displays detailed information about the replica key.
    #     replica_policy: "{\n  \"Version\" : \"2012-10-17\",\n  \"Id\" : \"key-default-1\",...}", # The key policy of the replica key. If you don't specify a key policy, the replica key gets the default key policy for a KMS key.
    #     replica_tags: [
    #     ], # The tags on the replica key, if any.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.replicate_key({
    #     key_id: "KeyIdType", # required
    #     replica_region: "RegionType", # required
    #     policy: "PolicyType",
    #     bypass_policy_lockout_safety_check: false,
    #     description: "DescriptionType",
    #     tags: [
    #       {
    #         tag_key: "TagKeyType", # required
    #         tag_value: "TagValueType", # required
    #       },
    #     ],
    #   })
    #
    # @example Response structure
    #
    #   resp.replica_key_metadata.aws_account_id #=> String
    #   resp.replica_key_metadata.key_id #=> String
    #   resp.replica_key_metadata.arn #=> String
    #   resp.replica_key_metadata.creation_date #=> Time
    #   resp.replica_key_metadata.enabled #=> Boolean
    #   resp.replica_key_metadata.description #=> String
    #   resp.replica_key_metadata.key_usage #=> String, one of "SIGN_VERIFY", "ENCRYPT_DECRYPT", "GENERATE_VERIFY_MAC", "KEY_AGREEMENT"
    #   resp.replica_key_metadata.key_state #=> String, one of "Creating", "Enabled", "Disabled", "PendingDeletion", "PendingImport", "PendingReplicaDeletion", "Unavailable", "Updating"
    #   resp.replica_key_metadata.deletion_date #=> Time
    #   resp.replica_key_metadata.valid_to #=> Time
    #   resp.replica_key_metadata.origin #=> String, one of "AWS_KMS", "EXTERNAL", "AWS_CLOUDHSM", "EXTERNAL_KEY_STORE"
    #   resp.replica_key_metadata.custom_key_store_id #=> String
    #   resp.replica_key_metadata.cloud_hsm_cluster_id #=> String
    #   resp.replica_key_metadata.expiration_model #=> String, one of "KEY_MATERIAL_EXPIRES", "KEY_MATERIAL_DOES_NOT_EXPIRE"
    #   resp.replica_key_metadata.key_manager #=> String, one of "AWS", "CUSTOMER"
    #   resp.replica_key_metadata.customer_master_key_spec #=> String, one of "RSA_2048", "RSA_3072", "RSA_4096", "ECC_NIST_P256", "ECC_NIST_P384", "ECC_NIST_P521", "ECC_SECG_P256K1", "SYMMETRIC_DEFAULT", "HMAC_224", "HMAC_256", "HMAC_384", "HMAC_512", "SM2"
    #   resp.replica_key_metadata.key_spec #=> String, one of "RSA_2048", "RSA_3072", "RSA_4096", "ECC_NIST_P256", "ECC_NIST_P384", "ECC_NIST_P521", "ECC_SECG_P256K1", "SYMMETRIC_DEFAULT", "HMAC_224", "HMAC_256", "HMAC_384", "HMAC_512", "SM2", "ML_DSA_44", "ML_DSA_65", "ML_DSA_87", "ECC_NIST_EDWARDS25519"
    #   resp.replica_key_metadata.encryption_algorithms #=> Array
    #   resp.replica_key_metadata.encryption_algorithms[0] #=> String, one of "SYMMETRIC_DEFAULT", "RSAES_OAEP_SHA_1", "RSAES_OAEP_SHA_256", "SM2PKE"
    #   resp.replica_key_metadata.signing_algorithms #=> Array
    #   resp.replica_key_metadata.signing_algorithms[0] #=> String, one of "RSASSA_PSS_SHA_256", "RSASSA_PSS_SHA_384", "RSASSA_PSS_SHA_512", "RSASSA_PKCS1_V1_5_SHA_256", "RSASSA_PKCS1_V1_5_SHA_384", "RSASSA_PKCS1_V1_5_SHA_512", "ECDSA_SHA_256", "ECDSA_SHA_384", "ECDSA_SHA_512", "SM2DSA", "ML_DSA_SHAKE_256", "ED25519_SHA_512", "ED25519_PH_SHA_512"
    #   resp.replica_key_metadata.key_agreement_algorithms #=> Array
    #   resp.replica_key_metadata.key_agreement_algorithms[0] #=> String, one of "ECDH"
    #   resp.replica_key_metadata.multi_region #=> Boolean
    #   resp.replica_key_metadata.multi_region_configuration.multi_region_key_type #=> String, one of "PRIMARY", "REPLICA"
    #   resp.replica_key_metadata.multi_region_configuration.primary_key.arn #=> String
    #   resp.replica_key_metadata.multi_region_configuration.primary_key.region #=> String
    #   resp.replica_key_metadata.multi_region_configuration.replica_keys #=> Array
    #   resp.replica_key_metadata.multi_region_configuration.replica_keys[0].arn #=> String
    #   resp.replica_key_metadata.multi_region_configuration.replica_keys[0].region #=> String
    #   resp.replica_key_metadata.pending_deletion_window_in_days #=> Integer
    #   resp.replica_key_metadata.mac_algorithms #=> Array
    #   resp.replica_key_metadata.mac_algorithms[0] #=> String, one of "HMAC_SHA_224", "HMAC_SHA_256", "HMAC_SHA_384", "HMAC_SHA_512"
    #   resp.replica_key_metadata.xks_key_configuration.id #=> String
    #   resp.replica_key_metadata.current_key_material_id #=> String
    #   resp.replica_policy #=> String
    #   resp.replica_tags #=> Array
    #   resp.replica_tags[0].tag_key #=> String
    #   resp.replica_tags[0].tag_value #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ReplicateKey AWS API Documentation
    #
    # @overload replicate_key(params = {})
    # @param [Hash] params ({})
    def replicate_key(params = {}, options = {})
      req = build_request(:replicate_key, params)
      req.send_request(options)
    end

    # Deletes a grant. Typically, you retire a grant when you no longer need
    # its permissions. To identify the grant to retire, use a [grant
    # token][1], or both the grant ID and a key identifier (key ID or key
    # ARN) of the KMS key. The CreateGrant operation returns both values.
    #
    # This operation can be called by the *retiring principal* for a grant,
    # by the *grantee principal* if the grant allows the `RetireGrant`
    # operation, and by the Amazon Web Services account in which the grant
    # is created. It can also be called by principals to whom permission for
    # retiring a grant is delegated.
    #
    # For detailed information about grants, including grant terminology,
    # see [Grants in KMS][2] in the <i> <i>Key Management Service Developer
    # Guide</i> </i>. For examples of creating grants in several programming
    # languages, see [Use CreateGrant with an Amazon Web Services SDK or
    # CLI][3].
    #
    # **Cross-account use**: Yes. You can retire a grant on a KMS key in a
    # different Amazon Web Services account.
    #
    # **Required permissions**: Permission to retire a grant is determined
    # primarily by the grant. For details, see [Retiring and revoking
    # grants][4] in the *Key Management Service Developer Guide*.
    #
    # **Related operations:**
    #
    # * CreateGrant
    #
    # * ListGrants
    #
    # * ListRetirableGrants
    #
    # * RevokeGrant
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][5].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html#grant_token
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/example_kms_CreateGrant_section.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/grant-delete.html
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [String] :grant_token
    #   Identifies the grant to be retired. You can use a grant token to
    #   identify a new grant even before it has achieved eventual consistency.
    #
    #   Only the CreateGrant operation returns a grant token. For details, see
    #   [Grant token][1] and [Eventual consistency][2] in the *Key Management
    #   Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html#grant_token
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html#terms-eventual-consistency
    #
    # @option params [String] :key_id
    #   The key ARN KMS key associated with the grant. To find the key ARN,
    #   use the ListKeys operation.
    #
    #   For example:
    #   `arn:aws:kms:us-east-2:444455556666:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    # @option params [String] :grant_id
    #   Identifies the grant to retire. To get the grant ID, use CreateGrant,
    #   ListGrants, or ListRetirableGrants.
    #
    #   * Grant ID Example -
    #     0123456789012345678901234567890123456789012345678901234567890123
    #
    #   ^
    #
    # @option params [Boolean] :dry_run
    #   Checks if your request will succeed. `DryRun` is an optional
    #   parameter.
    #
    #   To learn more about how to use this parameter, see [Testing your
    #   permissions][1] in the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/testing-permissions.html
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To retire a grant
    #
    #   # The following example retires a grant.
    #
    #   resp = client.retire_grant({
    #     grant_id: "0c237476b39f8bc44e45212e08498fbe3151305030726c0590dd8d3e9f3d6a60", # The identifier of the grant to retire.
    #     key_id: "arn:aws:kms:us-east-2:444455556666:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The Amazon Resource Name (ARN) of the KMS key associated with the grant.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.retire_grant({
    #     grant_token: "GrantTokenType",
    #     key_id: "KeyIdType",
    #     grant_id: "GrantIdType",
    #     dry_run: false,
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/RetireGrant AWS API Documentation
    #
    # @overload retire_grant(params = {})
    # @param [Hash] params ({})
    def retire_grant(params = {}, options = {})
      req = build_request(:retire_grant, params)
      req.send_request(options)
    end

    # Deletes the specified grant. You revoke a grant to terminate the
    # permissions that the grant allows. For more information, see [Retiring
    # and revoking grants][1] in the <i> <i>Key Management Service Developer
    # Guide</i> </i>.
    #
    # When you create, retire, or revoke a grant, there might be a brief
    # delay, usually less than five minutes, until the grant is available
    # throughout KMS. This state is known as *eventual consistency*. For
    # details, see [Eventual consistency][2] in the <i> <i>Key Management
    # Service Developer Guide</i> </i>.
    #
    # For detailed information about grants, including grant terminology,
    # see [Grants in KMS][3] in the <i> <i>Key Management Service Developer
    # Guide</i> </i>. For examples of creating grants in several programming
    # languages, see [Use CreateGrant with an Amazon Web Services SDK or
    # CLI][4].
    #
    # **Cross-account use**: Yes. To perform this operation on a KMS key in
    # a different Amazon Web Services account, specify the key ARN in the
    # value of the `KeyId` parameter.
    #
    # **Required permissions**: [kms:RevokeGrant][5] (key policy).
    #
    # **Related operations:**
    #
    # * CreateGrant
    #
    # * ListGrants
    #
    # * ListRetirableGrants
    #
    # * RetireGrant
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][6].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/grant-delete.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html#terms-eventual-consistency
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/example_kms_CreateGrant_section.html
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [6]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   A unique identifier for the KMS key associated with the grant. To get
    #   the key ID and key ARN for a KMS key, use ListKeys or DescribeKey.
    #
    #   Specify the key ID or key ARN of the KMS key. To specify a KMS key in
    #   a different Amazon Web Services account, you must use the key ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    # @option params [required, String] :grant_id
    #   Identifies the grant to revoke. To get the grant ID, use CreateGrant,
    #   ListGrants, or ListRetirableGrants.
    #
    # @option params [Boolean] :dry_run
    #   Checks if your request will succeed. `DryRun` is an optional
    #   parameter.
    #
    #   To learn more about how to use this parameter, see [Testing your
    #   permissions][1] in the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/testing-permissions.html
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To revoke a grant
    #
    #   # The following example revokes a grant.
    #
    #   resp = client.revoke_grant({
    #     grant_id: "0c237476b39f8bc44e45212e08498fbe3151305030726c0590dd8d3e9f3d6a60", # The identifier of the grant to revoke.
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key associated with the grant. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.revoke_grant({
    #     key_id: "KeyIdType", # required
    #     grant_id: "GrantIdType", # required
    #     dry_run: false,
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/RevokeGrant AWS API Documentation
    #
    # @overload revoke_grant(params = {})
    # @param [Hash] params ({})
    def revoke_grant(params = {}, options = {})
      req = build_request(:revoke_grant, params)
      req.send_request(options)
    end

    # Immediately initiates rotation of the key material of the specified
    # symmetric encryption KMS key.
    #
    # You can perform [on-demand rotation][1] of the key material in
    # customer managed KMS keys, regardless of whether or not [automatic key
    # rotation][2] is enabled. On-demand rotations do not change existing
    # automatic rotation schedules. For example, consider a KMS key that has
    # automatic key rotation enabled with a rotation period of 730 days. If
    # the key is scheduled to automatically rotate on April 14, 2024, and
    # you perform an on-demand rotation on April 10, 2024, the key will
    # automatically rotate, as scheduled, on April 14, 2024 and every 730
    # days thereafter.
    #
    # <note markdown="1"> You can perform on-demand key rotation a **maximum of 25 times** per
    # KMS key. You can use the KMS console to view the number of remaining
    # on-demand rotations available for a KMS key.
    #
    #  </note>
    #
    # You can use GetKeyRotationStatus to identify any in progress on-demand
    # rotations. You can use ListKeyRotations to identify the date that
    # completed on-demand rotations were performed. You can monitor rotation
    # of the key material for your KMS keys in CloudTrail and Amazon
    # CloudWatch.
    #
    # On-demand key rotation is supported only on symmetric encryption KMS
    # keys. You cannot perform on-demand rotation of [asymmetric KMS
    # keys][3], [HMAC KMS keys][4], or KMS keys in a [custom key store][5].
    # When you initiate on-demand key rotation on a symmetric encryption KMS
    # key with imported key material, you must have already imported [new
    # key material][6] and that key material's state should be
    # `PENDING_ROTATION`. Use the `ListKeyRotations` operation to check the
    # state of all key materials associated with a KMS key. To perform
    # on-demand rotation of a set of related [multi-Region keys][7], import
    # new key material in the primary Region key, import the same key
    # material in each replica Region key, and invoke the on-demand rotation
    # on the primary Region key.
    #
    # You cannot initiate on-demand rotation of [Amazon Web Services managed
    # KMS keys][8]. KMS always rotates the key material of Amazon Web
    # Services managed keys every year. Rotation of [Amazon Web Services
    # owned KMS keys][9] is managed by the Amazon Web Services service that
    # owns the key.
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][10] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: No. You cannot perform this operation on a KMS
    # key in a different Amazon Web Services account.
    #
    # **Required permissions**: [kms:RotateKeyOnDemand][11] (key policy)
    #
    # **Related operations:**
    #
    # * EnableKeyRotation
    #
    # * DisableKeyRotation
    #
    # * GetKeyRotationStatus
    #
    # * ImportKeyMaterial
    #
    # * ListKeyRotations
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][12].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/rotating-keys-on-demand.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/rotating-keys-enable-disable.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/hmac.html
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/key-store-overview.html
    # [6]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys-import-key-material.html
    # [7]: https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html#multi-region-rotate
    # [8]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-key
    # [9]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-owned-key
    # [10]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [11]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [12]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Identifies a symmetric encryption KMS key. You cannot perform
    #   on-demand rotation of [asymmetric KMS keys][1], [HMAC KMS keys][2],
    #   multi-Region KMS keys with [imported key material][3], or KMS keys in
    #   a [custom key store][4]. To perform on-demand rotation of a set of
    #   related [multi-Region keys][5], invoke the on-demand rotation on the
    #   primary key.
    #
    #   Specify the key ID or key ARN of the KMS key.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/hmac.html
    #   [3]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys.html
    #   [4]: https://docs.aws.amazon.com/kms/latest/developerguide/key-store-overview.html
    #   [5]: https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html#multi-region-rotate
    #
    # @return [Types::RotateKeyOnDemandResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::RotateKeyOnDemandResponse#key_id #key_id} => String
    #
    #
    # @example Example: To perform on-demand rotation of key material
    #
    #   # The following example immediately initiates rotation of the key material for the specified KMS key.
    #
    #   resp = client.rotate_key_on_demand({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key whose key material you want to initiate on-demand rotation on. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The KMS key that you initiated on-demand rotation on.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.rotate_key_on_demand({
    #     key_id: "KeyIdType", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.key_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/RotateKeyOnDemand AWS API Documentation
    #
    # @overload rotate_key_on_demand(params = {})
    # @param [Hash] params ({})
    def rotate_key_on_demand(params = {}, options = {})
      req = build_request(:rotate_key_on_demand, params)
      req.send_request(options)
    end

    # Schedules the deletion of a KMS key. By default, KMS applies a waiting
    # period of 30 days, but you can specify a waiting period of 7-30 days.
    # When this operation is successful, the key state of the KMS key
    # changes to `PendingDeletion` and the key can't be used in any
    # cryptographic operations. It remains in this state for the duration of
    # the waiting period. Before the waiting period ends, you can use
    # CancelKeyDeletion to cancel the deletion of the KMS key. After the
    # waiting period ends, KMS deletes the KMS key, its key material, and
    # all KMS data associated with it, including all aliases that refer to
    # it.
    #
    # Deleting a KMS key is a destructive and potentially dangerous
    # operation. When a KMS key is deleted, all data that was encrypted
    # under the KMS key is unrecoverable. (The only exception is a
    # [multi-Region replica key][1], or an [asymmetric or HMAC KMS key with
    # imported key material][2].) To prevent the use of a KMS key without
    # deleting it, use DisableKey.
    #
    # You can schedule the deletion of a multi-Region primary key and its
    # replica keys at any time. However, KMS will not delete a multi-Region
    # primary key with existing replica keys. If you schedule the deletion
    # of a primary key with replicas, its key state changes to
    # `PendingReplicaDeletion` and it cannot be replicated or used in
    # cryptographic operations. This status can continue indefinitely. When
    # the last of its replicas keys is deleted (not just scheduled), the key
    # state of the primary key changes to `PendingDeletion` and its waiting
    # period (`PendingWindowInDays`) begins. For details, see [Deleting
    # multi-Region keys][3] in the *Key Management Service Developer Guide*.
    #
    # When KMS [deletes a KMS key from an CloudHSM key store][4], it makes a
    # best effort to delete the associated key material from the associated
    # CloudHSM cluster. However, you might need to manually [delete the
    # orphaned key material][5] from the cluster and its backups. [Deleting
    # a KMS key from an external key store][6] has no effect on the
    # associated external key. However, for both types of custom key stores,
    # deleting a KMS key is destructive and irreversible. You cannot decrypt
    # ciphertext encrypted under the KMS key by using only its associated
    # external key or CloudHSM key. Also, you cannot recreate a KMS key in
    # an external key store by creating a new KMS key with the same key
    # material.
    #
    # For more information about scheduling a KMS key for deletion, see
    # [Deleting KMS keys][7] in the *Key Management Service Developer
    # Guide*.
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][8] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: No. You cannot perform this operation on a KMS
    # key in a different Amazon Web Services account.
    #
    # **Required permissions**: kms:ScheduleKeyDeletion (key policy)
    #
    # **Related operations**
    #
    # * CancelKeyDeletion
    #
    # * DisableKey
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][9].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-delete.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html#import-delete-key
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html#deleting-mrks
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html#delete-cmk-keystore
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/fix-keystore.html#fix-keystore-orphaned-key
    # [6]: https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html#delete-xks-key
    # [7]: https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html
    # [8]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [9]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   The unique identifier of the KMS key to delete.
    #
    #   Specify the key ID or key ARN of the KMS key.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    # @option params [Integer] :pending_window_in_days
    #   The waiting period, specified in number of days. After the waiting
    #   period ends, KMS deletes the KMS key.
    #
    #   If the KMS key is a multi-Region primary key with replica keys, the
    #   waiting period begins when the last of its replica keys is deleted.
    #   Otherwise, the waiting period begins immediately.
    #
    #   This value is optional. If you include a value, it must be between 7
    #   and 30, inclusive. If you do not include a value, it defaults to 30.
    #   You can use the [ `kms:ScheduleKeyDeletionPendingWindowInDays` ][1]
    #   condition key to further constrain the values that principals can
    #   specify in the `PendingWindowInDays` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/conditions-kms.html#conditions-kms-schedule-key-deletion-pending-window-in-days
    #
    # @return [Types::ScheduleKeyDeletionResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ScheduleKeyDeletionResponse#key_id #key_id} => String
    #   * {Types::ScheduleKeyDeletionResponse#deletion_date #deletion_date} => Time
    #   * {Types::ScheduleKeyDeletionResponse#key_state #key_state} => String
    #   * {Types::ScheduleKeyDeletionResponse#pending_window_in_days #pending_window_in_days} => Integer
    #
    #
    # @example Example: To schedule a KMS key for deletion
    #
    #   # The following example schedules the specified KMS key for deletion.
    #
    #   resp = client.schedule_key_deletion({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key to schedule for deletion. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #     pending_window_in_days: 7, # The waiting period, specified in number of days. After the waiting period ends, KMS deletes the KMS key.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     deletion_date: Time.parse("2016-12-17T16:00:00-08:00"), # The date and time after which KMS deletes the KMS key.
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The ARN of the KMS key that is scheduled for deletion.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.schedule_key_deletion({
    #     key_id: "KeyIdType", # required
    #     pending_window_in_days: 1,
    #   })
    #
    # @example Response structure
    #
    #   resp.key_id #=> String
    #   resp.deletion_date #=> Time
    #   resp.key_state #=> String, one of "Creating", "Enabled", "Disabled", "PendingDeletion", "PendingImport", "PendingReplicaDeletion", "Unavailable", "Updating"
    #   resp.pending_window_in_days #=> Integer
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/ScheduleKeyDeletion AWS API Documentation
    #
    # @overload schedule_key_deletion(params = {})
    # @param [Hash] params ({})
    def schedule_key_deletion(params = {}, options = {})
      req = build_request(:schedule_key_deletion, params)
      req.send_request(options)
    end

    # Creates a [digital signature][1] for a message or message digest by
    # using the private key in an asymmetric signing KMS key. To verify the
    # signature, use the Verify operation, or use the public key in the same
    # asymmetric KMS key outside of KMS. For information about asymmetric
    # KMS keys, see [Asymmetric KMS keys][2] in the *Key Management Service
    # Developer Guide*.
    #
    # Digital signatures are generated and verified by using asymmetric key
    # pair, such as an RSA, ECC, or ML-DSA pair that is represented by an
    # asymmetric KMS key. The key owner (or an authorized user) uses their
    # private key to sign a message. Anyone with the public key can verify
    # that the message was signed with that particular private key and that
    # the message hasn't changed since it was signed.
    #
    # To use the `Sign` operation, provide the following information:
    #
    # * Use the `KeyId` parameter to identify an asymmetric KMS key with a
    #   `KeyUsage` value of `SIGN_VERIFY`. To get the `KeyUsage` value of a
    #   KMS key, use the DescribeKey operation. The caller must have
    #   `kms:Sign` permission on the KMS key.
    #
    # * Use the `Message` parameter to specify the message or message digest
    #   to sign. You can submit messages of up to 4096 bytes. To sign a
    #   larger message, generate a hash digest of the message, and then
    #   provide the hash digest in the `Message` parameter. To indicate
    #   whether the message is a full message, a digest, or an ML-DSA
    #   EXTERNAL\_MU, use the `MessageType` parameter.
    #
    # * Choose a signing algorithm that is compatible with the KMS key.
    #
    # When signing a message, be sure to record the KMS key and the signing
    # algorithm. This information is required to verify the signature.
    #
    # <note markdown="1"> Best practices recommend that you limit the time during which any
    # signature is effective. This deters an attack where the actor uses a
    # signed message to establish validity repeatedly or long after the
    # message is superseded. Signatures do not include a timestamp, but you
    # can include a timestamp in the signed message to help you detect when
    # its time to refresh the signature.
    #
    #  </note>
    #
    # To verify the signature that this operation generates, use the Verify
    # operation. Or use the GetPublicKey operation to download the public
    # key and then use the public key to verify the signature outside of
    # KMS.
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][3] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: Yes. To perform this operation with a KMS key
    # in a different Amazon Web Services account, specify the key ARN or
    # alias ARN in the value of the `KeyId` parameter.
    #
    # **Required permissions**: [kms:Sign][4] (key policy)
    #
    # **Related operations**: Verify
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][5].
    #
    #
    #
    # [1]: https://en.wikipedia.org/wiki/Digital_signature
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Identifies an asymmetric KMS key. KMS uses the private key in the
    #   asymmetric KMS key to sign the message. The `KeyUsage` type of the KMS
    #   key must be `SIGN_VERIFY`. To find the `KeyUsage` of a KMS key, use
    #   the DescribeKey operation.
    #
    #   To specify a KMS key, use its key ID, key ARN, alias name, or alias
    #   ARN. When using an alias name, prefix it with `"alias/"`. To specify a
    #   KMS key in a different Amazon Web Services account, you must use the
    #   key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey. To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [required, String, StringIO, File] :message
    #   Specifies the message or message digest to sign. Messages can be
    #   0-4096 bytes. To sign a larger message, provide a message digest.
    #
    #   If you provide a message digest, use the `DIGEST` value of
    #   `MessageType` to prevent the digest from being hashed again while
    #   signing.
    #
    # @option params [String] :message_type
    #   Tells KMS whether the value of the `Message` parameter should be
    #   hashed as part of the signing algorithm. Use `RAW` for unhashed
    #   messages; use `DIGEST` for message digests, which are already hashed;
    #   use `EXTERNAL_MU` for 64-byte representative μ used in ML-DSA signing
    #   as defined in NIST FIPS 204 Section 6.2.
    #
    #   When the value of `MessageType` is `RAW`, KMS uses the standard
    #   signing algorithm, which begins with a hash function. When the value
    #   is `DIGEST`, KMS skips the hashing step in the signing algorithm. When
    #   the value is `EXTERNAL_MU` KMS skips the concatenated hashing of the
    #   public key hash and the message done in the ML-DSA signing algorithm.
    #
    #   Use the `DIGEST` or `EXTERNAL_MU` value only when the value of the
    #   `Message` parameter is a message digest. If you use the `DIGEST` value
    #   with an unhashed message, the security of the signing operation can be
    #   compromised.
    #
    #   When using ECC\_NIST\_EDWARDS25519 KMS keys:
    #
    #   * ED25519\_SHA\_512 signing algorithm requires KMS `MessageType:RAW`
    #
    #   * ED25519\_PH\_SHA\_512 signing algorithm requires KMS
    #     `MessageType:DIGEST`
    #
    #   When the value of `MessageType` is `DIGEST`, the length of the
    #   `Message` value must match the length of hashed messages for the
    #   specified signing algorithm.
    #
    #   When the value of `MessageType` is `EXTERNAL_MU` the length of the
    #   `Message` value must be 64 bytes.
    #
    #   You can submit a message digest and omit the `MessageType` or specify
    #   `RAW` so the digest is hashed again while signing. However, this can
    #   cause verification failures when verifying with a system that assumes
    #   a single hash.
    #
    #   The hashing algorithm that `Sign` uses is based on the
    #   `SigningAlgorithm` value.
    #
    #   * Signing algorithms that end in SHA\_256 use the SHA\_256 hashing
    #     algorithm.
    #
    #   * Signing algorithms that end in SHA\_384 use the SHA\_384 hashing
    #     algorithm.
    #
    #   * Signing algorithms that end in SHA\_512 use the SHA\_512 hashing
    #     algorithm.
    #
    #   * Signing algorithms that end in SHAKE\_256 use the SHAKE\_256 hashing
    #     algorithm.
    #
    #   * SM2DSA uses the SM3 hashing algorithm. For details, see [Offline
    #     verification with SM2 key pairs][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/offline-operations.html#key-spec-sm-offline-verification
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   Use a grant token when your permission to call this operation comes
    #   from a new grant that has not yet achieved *eventual consistency*. For
    #   more information, see [Grant token][1] and [Using a grant token][2] in
    #   the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html#grant_token
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/using-grant-token.html
    #
    # @option params [required, String] :signing_algorithm
    #   Specifies the signing algorithm to use when signing the message.
    #
    #   Choose an algorithm that is compatible with the type and size of the
    #   specified asymmetric KMS key. When signing with RSA key pairs,
    #   RSASSA-PSS algorithms are preferred. We include RSASSA-PKCS1-v1\_5
    #   algorithms for compatibility with existing applications.
    #
    # @option params [Boolean] :dry_run
    #   Checks if your request will succeed. `DryRun` is an optional
    #   parameter.
    #
    #   To learn more about how to use this parameter, see [Testing your
    #   permissions][1] in the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/testing-permissions.html
    #
    # @return [Types::SignResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::SignResponse#key_id #key_id} => String
    #   * {Types::SignResponse#signature #signature} => String
    #   * {Types::SignResponse#signing_algorithm #signing_algorithm} => String
    #
    #
    # @example Example: To digitally sign a message with an asymmetric KMS key.
    #
    #   # This operation uses the private key in an asymmetric elliptic curve (ECC) KMS key to generate a digital signature for a
    #   # given message.
    #
    #   resp = client.sign({
    #     key_id: "alias/ECC_signing_key", # The asymmetric KMS key to be used to generate the digital signature. This example uses an alias of the KMS key.
    #     message: "<message to be signed>", # Message to be signed. Use Base-64 for the CLI.
    #     message_type: "RAW", # Indicates whether the message is RAW or a DIGEST.
    #     signing_algorithm: "ECDSA_SHA_384", # The requested signing algorithm. This must be an algorithm that the KMS key supports.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The key ARN of the asymmetric KMS key that was used to sign the message.
    #     signature: "<binary data>", # The digital signature of the message.
    #     signing_algorithm: "ECDSA_SHA_384", # The actual signing algorithm that was used to generate the signature.
    #   }
    #
    # @example Example: To digitally sign a message digest with an asymmetric KMS key.
    #
    #   # This operation uses the private key in an asymmetric RSA signing KMS key to generate a digital signature for a message
    #   # digest. In this example, a large message was hashed and the resulting digest is provided in the Message parameter. To
    #   # tell KMS not to hash the message again, the MessageType field is set to DIGEST
    #
    #   resp = client.sign({
    #     key_id: "alias/RSA_signing_key", # The asymmetric KMS key to be used to generate the digital signature. This example uses an alias of the KMS key.
    #     message: "<message digest to be signed>", # Message to be signed. Use Base-64 for the CLI.
    #     message_type: "DIGEST", # Indicates whether the message is RAW or a DIGEST. When it is RAW, KMS hashes the message before signing. When it is DIGEST, KMS skips the hashing step and signs the Message value.
    #     signing_algorithm: "RSASSA_PKCS1_V1_5_SHA_256", # The requested signing algorithm. This must be an algorithm that the KMS key supports.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/0987dcba-09fe-87dc-65ba-ab0987654321", # The key ARN of the asymmetric KMS key that was used to sign the message.
    #     signature: "<binary data>", # The digital signature of the message.
    #     signing_algorithm: "RSASSA_PKCS1_V1_5_SHA_256", # The actual signing algorithm that was used to generate the signature.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.sign({
    #     key_id: "KeyIdType", # required
    #     message: "data", # required
    #     message_type: "RAW", # accepts RAW, DIGEST, EXTERNAL_MU
    #     grant_tokens: ["GrantTokenType"],
    #     signing_algorithm: "RSASSA_PSS_SHA_256", # required, accepts RSASSA_PSS_SHA_256, RSASSA_PSS_SHA_384, RSASSA_PSS_SHA_512, RSASSA_PKCS1_V1_5_SHA_256, RSASSA_PKCS1_V1_5_SHA_384, RSASSA_PKCS1_V1_5_SHA_512, ECDSA_SHA_256, ECDSA_SHA_384, ECDSA_SHA_512, SM2DSA, ML_DSA_SHAKE_256, ED25519_SHA_512, ED25519_PH_SHA_512
    #     dry_run: false,
    #   })
    #
    # @example Response structure
    #
    #   resp.key_id #=> String
    #   resp.signature #=> String
    #   resp.signing_algorithm #=> String, one of "RSASSA_PSS_SHA_256", "RSASSA_PSS_SHA_384", "RSASSA_PSS_SHA_512", "RSASSA_PKCS1_V1_5_SHA_256", "RSASSA_PKCS1_V1_5_SHA_384", "RSASSA_PKCS1_V1_5_SHA_512", "ECDSA_SHA_256", "ECDSA_SHA_384", "ECDSA_SHA_512", "SM2DSA", "ML_DSA_SHAKE_256", "ED25519_SHA_512", "ED25519_PH_SHA_512"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/Sign AWS API Documentation
    #
    # @overload sign(params = {})
    # @param [Hash] params ({})
    def sign(params = {}, options = {})
      req = build_request(:sign, params)
      req.send_request(options)
    end

    # Adds or edits tags on a [customer managed key][1].
    #
    # <note markdown="1"> Tagging or untagging a KMS key can allow or deny permission to the KMS
    # key. For details, see [ABAC for KMS][2] in the *Key Management Service
    # Developer Guide*.
    #
    #  </note>
    #
    # Each tag consists of a tag key and a tag value, both of which are
    # case-sensitive strings. The tag value can be an empty (null) string.
    # To add a tag, specify a new tag key and a tag value. To edit a tag,
    # specify an existing tag key and a new tag value.
    #
    # You can use this operation to tag a [customer managed key][1], but you
    # cannot tag an [Amazon Web Services managed key][3], an [Amazon Web
    # Services owned key][4], a [custom key store][5], or an [alias][6].
    #
    # You can also add tags to a KMS key while creating it (CreateKey) or
    # replicating it (ReplicateKey).
    #
    # For information about using tags in KMS, see [Tagging keys][7]. For
    # general information about tags, including the format and syntax, see
    # [Tagging Amazon Web Services resources][8] in the *Amazon Web Services
    # General Reference*.
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][9] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: No. You cannot perform this operation on a KMS
    # key in a different Amazon Web Services account.
    #
    # **Required permissions**: [kms:TagResource][10] (key policy)
    #
    # **Related operations**
    #
    # * CreateKey
    #
    # * ListResourceTags
    #
    # * ReplicateKey
    #
    # * UntagResource
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][11].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-mgn-key
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/abac.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-key
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-owned-key
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/key-store-overview.html
    # [6]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-alias.html
    # [7]: https://docs.aws.amazon.com/kms/latest/developerguide/tagging-keys.html
    # [8]: https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html
    # [9]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [10]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [11]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Identifies a customer managed key in the account and Region.
    #
    #   Specify the key ID or key ARN of the KMS key.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    # @option params [required, Array<Types::Tag>] :tags
    #   One or more tags. Each tag consists of a tag key and a tag value. The
    #   tag value can be an empty (null) string.
    #
    #   Do not include confidential or sensitive information in this field.
    #   This field may be displayed in plaintext in CloudTrail logs and other
    #   output.
    #
    #   You cannot have more than one tag on a KMS key with the same tag key.
    #   If you specify an existing tag key with a different tag value, KMS
    #   replaces the current tag value with the specified one.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To tag a KMS key
    #
    #   # The following example tags a KMS key.
    #
    #   resp = client.tag_resource({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key you are tagging. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #     tags: [
    #       {
    #         tag_key: "Purpose", 
    #         tag_value: "Test", 
    #       }, 
    #     ], # A list of tags.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.tag_resource({
    #     key_id: "KeyIdType", # required
    #     tags: [ # required
    #       {
    #         tag_key: "TagKeyType", # required
    #         tag_value: "TagValueType", # required
    #       },
    #     ],
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/TagResource AWS API Documentation
    #
    # @overload tag_resource(params = {})
    # @param [Hash] params ({})
    def tag_resource(params = {}, options = {})
      req = build_request(:tag_resource, params)
      req.send_request(options)
    end

    # Deletes tags from a [customer managed key][1]. To delete a tag,
    # specify the tag key and the KMS key.
    #
    # <note markdown="1"> Tagging or untagging a KMS key can allow or deny permission to the KMS
    # key. For details, see [ABAC for KMS][2] in the *Key Management Service
    # Developer Guide*.
    #
    #  </note>
    #
    # When it succeeds, the `UntagResource` operation doesn't return any
    # output. Also, if the specified tag key isn't found on the KMS key, it
    # doesn't throw an exception or return a response. To confirm that the
    # operation worked, use the ListResourceTags operation.
    #
    # For information about using tags in KMS, see [Tagging keys][3]. For
    # general information about tags, including the format and syntax, see
    # [Tagging Amazon Web Services resources][4] in the *Amazon Web Services
    # General Reference*.
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][5] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: No. You cannot perform this operation on a KMS
    # key in a different Amazon Web Services account.
    #
    # **Required permissions**: [kms:UntagResource][6] (key policy)
    #
    # **Related operations**
    #
    # * CreateKey
    #
    # * ListResourceTags
    #
    # * ReplicateKey
    #
    # * TagResource
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][7].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-mgn-key
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/abac.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/tagging-keys.html
    # [4]: https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [6]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [7]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Identifies the KMS key from which you are removing tags.
    #
    #   Specify the key ID or key ARN of the KMS key.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    # @option params [required, Array<String>] :tag_keys
    #   One or more tag keys. Specify only the tag keys, not the tag values.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To remove tags from a KMS key
    #
    #   # The following example removes tags from a KMS key.
    #
    #   resp = client.untag_resource({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key whose tags you are removing.
    #     tag_keys: [
    #       "Purpose", 
    #       "CostCenter", 
    #     ], # A list of tag keys. Provide only the tag keys, not the tag values.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.untag_resource({
    #     key_id: "KeyIdType", # required
    #     tag_keys: ["TagKeyType"], # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/UntagResource AWS API Documentation
    #
    # @overload untag_resource(params = {})
    # @param [Hash] params ({})
    def untag_resource(params = {}, options = {})
      req = build_request(:untag_resource, params)
      req.send_request(options)
    end

    # Associates an existing KMS alias with a different KMS key. Each alias
    # is associated with only one KMS key at a time, although a KMS key can
    # have multiple aliases. The alias and the KMS key must be in the same
    # Amazon Web Services account and Region.
    #
    # <note markdown="1"> Adding, deleting, or updating an alias can allow or deny permission to
    # the KMS key. For details, see [ABAC for KMS][1] in the *Key Management
    # Service Developer Guide*.
    #
    #  </note>
    #
    # The current and new KMS key must be the same type (both symmetric or
    # both asymmetric or both HMAC), and they must have the same key usage.
    # This restriction prevents errors in code that uses aliases. If you
    # must assign an alias to a different type of KMS key, use DeleteAlias
    # to delete the old alias and CreateAlias to create a new alias.
    #
    # You cannot use `UpdateAlias` to change an alias name. To change an
    # alias name, use DeleteAlias to delete the old alias and CreateAlias to
    # create a new alias.
    #
    # Because an alias is not a property of a KMS key, you can create,
    # update, and delete the aliases of a KMS key without affecting the KMS
    # key. Also, aliases do not appear in the response from the DescribeKey
    # operation. To get the aliases of all KMS keys in the account, use the
    # ListAliases operation.
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][2] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: No. You cannot perform this operation on a KMS
    # key in a different Amazon Web Services account.
    #
    # **Required permissions**
    #
    # * [kms:UpdateAlias][3] on the alias (IAM policy).
    #
    # * [kms:UpdateAlias][3] on the current KMS key (key policy).
    #
    # * [kms:UpdateAlias][3] on the new KMS key (key policy).
    #
    # For details, see [Controlling access to aliases][4] in the *Key
    # Management Service Developer Guide*.
    #
    # **Related operations:**
    #
    # * CreateAlias
    #
    # * DeleteAlias
    #
    # * ListAliases
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][5].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/abac.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-alias.html#alias-access
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :alias_name
    #   Identifies the alias that is changing its KMS key. This value must
    #   begin with `alias/` followed by the alias name, such as
    #   `alias/ExampleAlias`. You cannot use `UpdateAlias` to change the alias
    #   name.
    #
    #   Do not include confidential or sensitive information in this field.
    #   This field may be displayed in plaintext in CloudTrail logs and other
    #   output.
    #
    # @option params [required, String] :target_key_id
    #   Identifies the [customer managed key][1] to associate with the alias.
    #   You don't have permission to associate an alias with an [Amazon Web
    #   Services managed key][2].
    #
    #   The KMS key must be in the same Amazon Web Services account and Region
    #   as the alias. Also, the new target KMS key must be the same type as
    #   the current target KMS key (both symmetric or both asymmetric or both
    #   HMAC) and they must have the same key usage.
    #
    #   Specify the key ID or key ARN of the KMS key.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    #   To verify that the alias is mapped to the correct KMS key, use
    #   ListAliases.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-mgn-key
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-key
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To update an alias
    #
    #   # The following example updates the specified alias to refer to the specified KMS key.
    #
    #   resp = client.update_alias({
    #     alias_name: "alias/ExampleAlias", # The alias to update.
    #     target_key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key that the alias will refer to after this operation succeeds. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.update_alias({
    #     alias_name: "AliasNameType", # required
    #     target_key_id: "KeyIdType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/UpdateAlias AWS API Documentation
    #
    # @overload update_alias(params = {})
    # @param [Hash] params ({})
    def update_alias(params = {}, options = {})
      req = build_request(:update_alias, params)
      req.send_request(options)
    end

    # Changes the properties of a custom key store. You can use this
    # operation to change the properties of an CloudHSM key store or an
    # external key store.
    #
    # Use the required `CustomKeyStoreId` parameter to identify the custom
    # key store. Use the remaining optional parameters to change its
    # properties. This operation does not return any property values. To
    # verify the updated property values, use the DescribeCustomKeyStores
    # operation.
    #
    # This operation is part of the custom key stores feature in KMS, which
    # combines the convenience and extensive integration of KMS with the
    # isolation and control of a key store that you own and manage.
    #
    # When updating the properties of an external key store, verify that the
    # updated settings connect your key store, via the external key store
    # proxy, to the same external key manager as the previous settings, or
    # to a backup or snapshot of the external key manager with the same
    # cryptographic keys. If the updated connection settings fail, you can
    # fix them and retry, although an extended delay might disrupt Amazon
    # Web Services services. However, if KMS permanently loses its access to
    # cryptographic keys, ciphertext encrypted under those keys is
    # unrecoverable.
    #
    # <note markdown="1"> For external key stores:
    #
    #  Some external key managers provide a simpler method for updating an
    # external key store. For details, see your external key manager
    # documentation.
    #
    #  When updating an external key store in the KMS console, you can upload
    # a JSON-based proxy configuration file with the desired values. You
    # cannot upload the proxy configuration file to the
    # `UpdateCustomKeyStore` operation. However, you can use the file to
    # help you determine the correct values for the `UpdateCustomKeyStore`
    # parameters.
    #
    #  </note>
    #
    # For an CloudHSM key store, you can use this operation to change the
    # custom key store friendly name (`NewCustomKeyStoreName`), to tell KMS
    # about a change to the `kmsuser` crypto user password
    # (`KeyStorePassword`), or to associate the custom key store with a
    # different, but related, CloudHSM cluster (`CloudHsmClusterId`). To
    # update any property of an CloudHSM key store, the `ConnectionState` of
    # the CloudHSM key store must be `DISCONNECTED`.
    #
    # For an external key store, you can use this operation to change the
    # custom key store friendly name (`NewCustomKeyStoreName`), or to tell
    # KMS about a change to the external key store proxy authentication
    # credentials (`XksProxyAuthenticationCredential`), connection method
    # (`XksProxyConnectivity`), external proxy endpoint
    # (`XksProxyUriEndpoint`) and path (`XksProxyUriPath`). For external key
    # stores with an `XksProxyConnectivity` of `VPC_ENDPOINT_SERVICE`, you
    # can also update the Amazon VPC endpoint service name
    # (`XksProxyVpcEndpointServiceName`). To update most properties of an
    # external key store, the `ConnectionState` of the external key store
    # must be `DISCONNECTED`. However, you can update the
    # `CustomKeyStoreName`, `XksProxyAuthenticationCredential`, and
    # `XksProxyUriPath` of an external key store when it is in the CONNECTED
    # or DISCONNECTED state.
    #
    # If your update requires a `DISCONNECTED` state, before using
    # `UpdateCustomKeyStore`, use the DisconnectCustomKeyStore operation to
    # disconnect the custom key store. After the `UpdateCustomKeyStore`
    # operation completes, use the ConnectCustomKeyStore to reconnect the
    # custom key store. To find the `ConnectionState` of the custom key
    # store, use the DescribeCustomKeyStores operation.
    #
    #
    #
    # Before updating the custom key store, verify that the new values allow
    # KMS to connect the custom key store to its backing key store. For
    # example, before you change the `XksProxyUriPath` value, verify that
    # the external key store proxy is reachable at the new path.
    #
    # If the operation succeeds, it returns a JSON object with no
    # properties.
    #
    # **Cross-account use**: No. You cannot perform this operation on a
    # custom key store in a different Amazon Web Services account.
    #
    # **Required permissions**: [kms:UpdateCustomKeyStore][1] (IAM policy)
    #
    # **Related operations:**
    #
    # * ConnectCustomKeyStore
    #
    # * CreateCustomKeyStore
    #
    # * DeleteCustomKeyStore
    #
    # * DescribeCustomKeyStores
    #
    # * DisconnectCustomKeyStore
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][2].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :custom_key_store_id
    #   Identifies the custom key store that you want to update. Enter the ID
    #   of the custom key store. To find the ID of a custom key store, use the
    #   DescribeCustomKeyStores operation.
    #
    # @option params [String] :new_custom_key_store_name
    #   Changes the friendly name of the custom key store to the value that
    #   you specify. The custom key store name must be unique in the Amazon
    #   Web Services account.
    #
    #   Do not include confidential or sensitive information in this field.
    #   This field may be displayed in plaintext in CloudTrail logs and other
    #   output.
    #
    #   To change this value, an CloudHSM key store must be disconnected. An
    #   external key store can be connected or disconnected.
    #
    # @option params [String] :key_store_password
    #   Enter the current password of the `kmsuser` crypto user (CU) in the
    #   CloudHSM cluster that is associated with the custom key store. This
    #   parameter is valid only for custom key stores with a
    #   `CustomKeyStoreType` of `AWS_CLOUDHSM`.
    #
    #   This parameter tells KMS the current password of the `kmsuser` crypto
    #   user (CU). It does not set or change the password of any users in the
    #   CloudHSM cluster.
    #
    #   To change this value, the CloudHSM key store must be disconnected.
    #
    # @option params [String] :cloud_hsm_cluster_id
    #   Associates the custom key store with a related CloudHSM cluster. This
    #   parameter is valid only for custom key stores with a
    #   `CustomKeyStoreType` of `AWS_CLOUDHSM`.
    #
    #   Enter the cluster ID of the cluster that you used to create the custom
    #   key store or a cluster that shares a backup history and has the same
    #   cluster certificate as the original cluster. You cannot use this
    #   parameter to associate a custom key store with an unrelated cluster.
    #   In addition, the replacement cluster must [fulfill the
    #   requirements][1] for a cluster associated with a custom key store. To
    #   view the cluster certificate of a cluster, use the
    #   [DescribeClusters][2] operation.
    #
    #   To change this value, the CloudHSM key store must be disconnected.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/create-keystore.html#before-keystore
    #   [2]: https://docs.aws.amazon.com/cloudhsm/latest/APIReference/API_DescribeClusters.html
    #
    # @option params [String] :xks_proxy_uri_endpoint
    #   Changes the URI endpoint that KMS uses to connect to your external key
    #   store proxy (XKS proxy). This parameter is valid only for custom key
    #   stores with a `CustomKeyStoreType` of `EXTERNAL_KEY_STORE`.
    #
    #   For external key stores with an `XksProxyConnectivity` value of
    #   `PUBLIC_ENDPOINT`, the protocol must be HTTPS.
    #
    #   For external key stores with an `XksProxyConnectivity` value of
    #   `VPC_ENDPOINT_SERVICE`, specify `https://` followed by the private DNS
    #   name associated with the VPC endpoint service. Each external key store
    #   must use a different private DNS name.
    #
    #   The combined `XksProxyUriEndpoint` and `XksProxyUriPath` values must
    #   be unique in the Amazon Web Services account and Region.
    #
    #   To change this value, the external key store must be disconnected.
    #
    # @option params [String] :xks_proxy_uri_path
    #   Changes the base path to the proxy APIs for this external key store.
    #   To find this value, see the documentation for your external key
    #   manager and external key store proxy (XKS proxy). This parameter is
    #   valid only for custom key stores with a `CustomKeyStoreType` of
    #   `EXTERNAL_KEY_STORE`.
    #
    #   The value must start with `/` and must end with `/kms/xks/v1`, where
    #   `v1` represents the version of the KMS external key store proxy API.
    #   You can include an optional prefix between the required elements such
    #   as `/example/kms/xks/v1`.
    #
    #   The combined `XksProxyUriEndpoint` and `XksProxyUriPath` values must
    #   be unique in the Amazon Web Services account and Region.
    #
    #   You can change this value when the external key store is connected or
    #   disconnected.
    #
    # @option params [String] :xks_proxy_vpc_endpoint_service_name
    #   Changes the name that KMS uses to identify the Amazon VPC endpoint
    #   service for your external key store proxy (XKS proxy). This parameter
    #   is valid when the `CustomKeyStoreType` is `EXTERNAL_KEY_STORE` and the
    #   `XksProxyConnectivity` is `VPC_ENDPOINT_SERVICE`.
    #
    #   To change this value, the external key store must be disconnected.
    #
    # @option params [String] :xks_proxy_vpc_endpoint_service_owner
    #   Changes the Amazon Web Services account ID that KMS uses to identify
    #   the Amazon VPC endpoint service for your external key store proxy (XKS
    #   proxy). This parameter is optional. If not specified, the current
    #   Amazon Web Services account ID for the VPC endpoint service will not
    #   be updated.
    #
    #   To change this value, the external key store must be disconnected.
    #
    # @option params [Types::XksProxyAuthenticationCredentialType] :xks_proxy_authentication_credential
    #   Changes the credentials that KMS uses to sign requests to the external
    #   key store proxy (XKS proxy). This parameter is valid only for custom
    #   key stores with a `CustomKeyStoreType` of `EXTERNAL_KEY_STORE`.
    #
    #   You must specify both the `AccessKeyId` and `SecretAccessKey` value in
    #   the authentication credential, even if you are only updating one
    #   value.
    #
    #   This parameter doesn't establish or change your authentication
    #   credentials on the proxy. It just tells KMS the credential that you
    #   established with your external key store proxy. For example, if you
    #   rotate the credential on your external key store proxy, you can use
    #   this parameter to update the credential in KMS.
    #
    #   You can change this value when the external key store is connected or
    #   disconnected.
    #
    # @option params [String] :xks_proxy_connectivity
    #   Changes the connectivity setting for the external key store. To
    #   indicate that the external key store proxy uses a Amazon VPC endpoint
    #   service to communicate with KMS, specify `VPC_ENDPOINT_SERVICE`.
    #   Otherwise, specify `PUBLIC_ENDPOINT`.
    #
    #   If you change the `XksProxyConnectivity` to `VPC_ENDPOINT_SERVICE`,
    #   you must also change the `XksProxyUriEndpoint` and add an
    #   `XksProxyVpcEndpointServiceName` value.
    #
    #   If you change the `XksProxyConnectivity` to `PUBLIC_ENDPOINT`, you
    #   must also change the `XksProxyUriEndpoint` and specify a null or empty
    #   string for the `XksProxyVpcEndpointServiceName` value.
    #
    #   To change this value, the external key store must be disconnected.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To edit the friendly name of a custom key store
    #
    #   # This example changes the friendly name of the AWS KMS custom key store to the name that you specify. This operation does
    #   # not return any data. To verify that the operation worked, use the DescribeCustomKeyStores operation.
    #
    #   resp = client.update_custom_key_store({
    #     custom_key_store_id: "cks-1234567890abcdef0", # The ID of the custom key store that you are updating.
    #     new_custom_key_store_name: "DevelopmentKeys", # A new friendly name for the custom key store.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #   }
    #
    # @example Example: To edit the password of an AWS CloudHSM key store
    #
    #   # This example tells AWS KMS the password for the kmsuser crypto user in the AWS CloudHSM cluster that is associated with
    #   # the AWS KMS custom key store. (It does not change the password in the CloudHSM cluster.) This operation does not return
    #   # any data.
    #
    #   resp = client.update_custom_key_store({
    #     custom_key_store_id: "cks-1234567890abcdef0", # The ID of the custom key store that you are updating.
    #     key_store_password: "ExamplePassword", # The password for the kmsuser crypto user in the CloudHSM cluster.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #   }
    #
    # @example Example: To associate the custom key store with a different, but related, AWS CloudHSM cluster.
    #
    #   # This example changes the AWS CloudHSM cluster that is associated with an AWS CloudHSM key store to a related cluster,
    #   # such as a different backup of the same cluster. This operation does not return any data. To verify that the operation
    #   # worked, use the DescribeCustomKeyStores operation.
    #
    #   resp = client.update_custom_key_store({
    #     cloud_hsm_cluster_id: "cluster-234abcdefABC", # The ID of the AWS CloudHSM cluster that you want to associate with the custom key store. This cluster must be related to the original CloudHSM cluster for this key store.
    #     custom_key_store_id: "cks-1234567890abcdef0", # The ID of the custom key store that you are updating.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #   }
    #
    # @example Example: To update the proxy authentication credential of an external key store
    #
    #   # To update the proxy authentication credential for your external key store, specify both the
    #   # <code>RawSecretAccessKey</code> and the <code>AccessKeyId</code>, even if you are changing only one of the values. You
    #   # can use this feature to fix an invalid credential or to change the credential when the external key store proxy rotates
    #   # it.
    #
    #   resp = client.update_custom_key_store({
    #     custom_key_store_id: "cks-1234567890abcdef0", # Identifies the custom key store
    #     xks_proxy_authentication_credential: {
    #       access_key_id: "ABCDE12345670EXAMPLE", 
    #       raw_secret_access_key: "DXjSUawnel2fr6SKC7G25CNxTyWKE5PF9XX6H/u9pSo=", 
    #     }, # Specifies the values in the proxy authentication credential
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #   }
    #
    # @example Example: To edit the proxy URI path of an external key store.
    #
    #   # This example updates the proxy URI path for an external key store
    #
    #   resp = client.update_custom_key_store({
    #     custom_key_store_id: "cks-1234567890abcdef0", # The ID of the custom key store that you are updating
    #     xks_proxy_uri_path: "/new-path/kms/xks/v1", # The URI path to the external key store proxy APIs
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #   }
    #
    # @example Example: To update the proxy connectivity of an external key store to VPC_ENDPOINT_SERVICE
    #
    #   # To change the external key store proxy connectivity option from public endpoint connectivity to VPC endpoint service
    #   # connectivity, in addition to changing the <code>XksProxyConnectivity</code> value, you must change the
    #   # <code>XksProxyUriEndpoint</code> value to reflect the private DNS name associated with the VPC endpoint service. You
    #   # must also add an <code>XksProxyVpcEndpointServiceName</code> value.
    #
    #   resp = client.update_custom_key_store({
    #     custom_key_store_id: "cks-1234567890abcdef0", # Identifies the custom key store
    #     xks_proxy_connectivity: "VPC_ENDPOINT_SERVICE", # Specifies the connectivity option
    #     xks_proxy_uri_endpoint: "https://myproxy-private.xks.example.com", # Specifies the URI endpoint that AWS KMS uses when communicating with the external key store proxy
    #     xks_proxy_vpc_endpoint_service_name: "com.amazonaws.vpce.us-east-1.vpce-svc-example", # Specifies the name of the VPC endpoint service that the proxy uses for communication
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.update_custom_key_store({
    #     custom_key_store_id: "CustomKeyStoreIdType", # required
    #     new_custom_key_store_name: "CustomKeyStoreNameType",
    #     key_store_password: "KeyStorePasswordType",
    #     cloud_hsm_cluster_id: "CloudHsmClusterIdType",
    #     xks_proxy_uri_endpoint: "XksProxyUriEndpointType",
    #     xks_proxy_uri_path: "XksProxyUriPathType",
    #     xks_proxy_vpc_endpoint_service_name: "XksProxyVpcEndpointServiceNameType",
    #     xks_proxy_vpc_endpoint_service_owner: "AccountIdType",
    #     xks_proxy_authentication_credential: {
    #       access_key_id: "XksProxyAuthenticationAccessKeyIdType", # required
    #       raw_secret_access_key: "XksProxyAuthenticationRawSecretAccessKeyType", # required
    #     },
    #     xks_proxy_connectivity: "PUBLIC_ENDPOINT", # accepts PUBLIC_ENDPOINT, VPC_ENDPOINT_SERVICE
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/UpdateCustomKeyStore AWS API Documentation
    #
    # @overload update_custom_key_store(params = {})
    # @param [Hash] params ({})
    def update_custom_key_store(params = {}, options = {})
      req = build_request(:update_custom_key_store, params)
      req.send_request(options)
    end

    # Updates the description of a KMS key. To see the description of a KMS
    # key, use DescribeKey.
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][1] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: No. You cannot perform this operation on a KMS
    # key in a different Amazon Web Services account.
    #
    # **Required permissions**: [kms:UpdateKeyDescription][2] (key policy)
    #
    # **Related operations**
    #
    # * CreateKey
    #
    # * DescribeKey
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][3].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Updates the description of the specified KMS key.
    #
    #   Specify the key ID or key ARN of the KMS key.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    # @option params [required, String] :description
    #   New description for the KMS key.
    #
    #   Do not include confidential or sensitive information in this field.
    #   This field may be displayed in plaintext in CloudTrail logs and other
    #   output.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To update the description of a KMS key
    #
    #   # The following example updates the description of the specified KMS key.
    #
    #   resp = client.update_key_description({
    #     description: "Example description that indicates the intended use of this KMS key.", # The updated description.
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The identifier of the KMS key whose description you are updating. You can use the key ID or the Amazon Resource Name (ARN) of the KMS key.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.update_key_description({
    #     key_id: "KeyIdType", # required
    #     description: "DescriptionType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/UpdateKeyDescription AWS API Documentation
    #
    # @overload update_key_description(params = {})
    # @param [Hash] params ({})
    def update_key_description(params = {}, options = {})
      req = build_request(:update_key_description, params)
      req.send_request(options)
    end

    # Changes the primary key of a multi-Region key.
    #
    # This operation changes the replica key in the specified Region to a
    # primary key and changes the former primary key to a replica key. For
    # example, suppose you have a primary key in `us-east-1` and a replica
    # key in `eu-west-2`. If you run `UpdatePrimaryRegion` with a
    # `PrimaryRegion` value of `eu-west-2`, the primary key is now the key
    # in `eu-west-2`, and the key in `us-east-1` becomes a replica key. For
    # details, see [Change the primary key in a set of multi-Region keys][1]
    # in the *Key Management Service Developer Guide*.
    #
    # This operation supports *multi-Region keys*, an KMS feature that lets
    # you create multiple interoperable KMS keys in different Amazon Web
    # Services Regions. Because these KMS keys have the same key ID, key
    # material, and other metadata, you can use them interchangeably to
    # encrypt data in one Amazon Web Services Region and decrypt it in a
    # different Amazon Web Services Region without re-encrypting the data or
    # making a cross-Region call. For more information about multi-Region
    # keys, see [Multi-Region keys in KMS][2] in the *Key Management Service
    # Developer Guide*.
    #
    # The *primary key* of a multi-Region key is the source for properties
    # that are always shared by primary and replica keys, including the key
    # material, [key ID][3], [key spec][4], [key usage][5], [key material
    # origin][6], and [automatic key rotation][7]. It's the only key that
    # can be replicated. You cannot [delete the primary key][8] until all
    # replica keys are deleted.
    #
    # The key ID and primary Region that you specify uniquely identify the
    # replica key that will become the primary key. The primary Region must
    # already have a replica key. This operation does not create a KMS key
    # in the specified Region. To find the replica keys, use the DescribeKey
    # operation on the primary key or any replica key. To create a replica
    # key, use the ReplicateKey operation.
    #
    # You can run this operation while using the affected multi-Region keys
    # in cryptographic operations. This operation should not delay,
    # interrupt, or cause failures in cryptographic operations.
    #
    # Even after this operation completes, the process of updating the
    # primary Region might still be in progress for a few more seconds.
    # Operations such as `DescribeKey` might display both the old and new
    # primary keys as replicas. The old and new primary keys have a
    # transient key state of `Updating`. The original key state is restored
    # when the update is complete. While the key state is `Updating`, you
    # can use the keys in cryptographic operations, but you cannot replicate
    # the new primary key or perform certain management operations, such as
    # enabling or disabling these keys. For details about the `Updating` key
    # state, see [Key states of KMS keys][9] in the *Key Management Service
    # Developer Guide*.
    #
    # This operation does not return any output. To verify that primary key
    # is changed, use the DescribeKey operation.
    #
    # **Cross-account use**: No. You cannot use this operation in a
    # different Amazon Web Services account.
    #
    # **Required permissions**:
    #
    # * `kms:UpdatePrimaryRegion` on the current primary key (in the primary
    #   key's Region). Include this permission primary key's key policy.
    #
    # * `kms:UpdatePrimaryRegion` on the current replica key (in the replica
    #   key's Region). Include this permission in the replica key's key
    #   policy.
    #
    # **Related operations**
    #
    # * CreateKey
    #
    # * ReplicateKey
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][10].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-update.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-overview.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#key-id-key-id
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#key-spec
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#key-usage
    # [6]: https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#key-origin
    # [7]: https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html
    # [8]: https://docs.aws.amazon.com/kms/latest/APIReference/API_ScheduleKeyDeletion.html
    # [9]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [10]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Identifies the current primary key. When the operation completes, this
    #   KMS key will be a replica key.
    #
    #   Specify the key ID or key ARN of a multi-Region primary key.
    #
    #   For example:
    #
    #   * Key ID: `mrk-1234abcd12ab34cd56ef1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/mrk-1234abcd12ab34cd56ef1234567890ab`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey.
    #
    # @option params [required, String] :primary_region
    #   The Amazon Web Services Region of the new primary key. Enter the
    #   Region ID, such as `us-east-1` or `ap-southeast-2`. There must be an
    #   existing replica key in this Region.
    #
    #   When the operation completes, the multi-Region key in this Region will
    #   be the primary key.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To update the primary Region of a multi-Region KMS key
    #
    #   # The following UpdatePrimaryRegion example changes the multi-Region replica key in the eu-central-1 Region to the primary
    #   # key. The current primary key in the us-west-1 Region becomes a replica key. 
    #   # The KeyId parameter identifies the current primary key in the us-west-1 Region. The PrimaryRegion parameter indicates
    #   # the Region of the replica key that will become the new primary key.
    #   # This operation does not return any output. To verify that primary key is changed, use the DescribeKey operation.
    #
    #   resp = client.update_primary_region({
    #     key_id: "arn:aws:kms:us-west-1:111122223333:key/mrk-1234abcd12ab34cd56ef1234567890ab", # The current primary key.
    #     primary_region: "eu-central-1", # The Region of the replica key that will become the primary key.
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.update_primary_region({
    #     key_id: "KeyIdType", # required
    #     primary_region: "RegionType", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/UpdatePrimaryRegion AWS API Documentation
    #
    # @overload update_primary_region(params = {})
    # @param [Hash] params ({})
    def update_primary_region(params = {}, options = {})
      req = build_request(:update_primary_region, params)
      req.send_request(options)
    end

    # Verifies a digital signature that was generated by the Sign operation.
    #
    #
    #
    # Verification confirms that an authorized user signed the message with
    # the specified KMS key and signing algorithm, and the message hasn't
    # changed since it was signed. If the signature is verified, the value
    # of the `SignatureValid` field in the response is `True`. If the
    # signature verification fails, the `Verify` operation fails with an
    # `KMSInvalidSignatureException` exception.
    #
    # A digital signature is generated by using the private key in an
    # asymmetric KMS key. The signature is verified by using the public key
    # in the same asymmetric KMS key. For information about asymmetric KMS
    # keys, see [Asymmetric KMS keys][1] in the *Key Management Service
    # Developer Guide*.
    #
    # To use the `Verify` operation, specify the same asymmetric KMS key,
    # message, and signing algorithm that were used to produce the
    # signature. The message type does not need to be the same as the one
    # used for signing, but it must indicate whether the value of the
    # `Message` parameter should be hashed as part of the verification
    # process.
    #
    # You can also verify the digital signature by using the public key of
    # the KMS key outside of KMS. Use the GetPublicKey operation to download
    # the public key in the asymmetric KMS key and then use the public key
    # to verify the signature outside of KMS. The advantage of using the
    # `Verify` operation is that it is performed within KMS. As a result,
    # it's easy to call, the operation is performed within the FIPS
    # boundary, it is logged in CloudTrail, and you can use key policy and
    # IAM policy to determine who is authorized to use the KMS key to verify
    # signatures.
    #
    # To verify a signature outside of KMS with an SM2 public key (China
    # Regions only), you must specify the distinguishing ID. By default, KMS
    # uses `1234567812345678` as the distinguishing ID. For more
    # information, see [Offline verification with SM2 key pairs][2].
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][3] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: Yes. To perform this operation with a KMS key
    # in a different Amazon Web Services account, specify the key ARN or
    # alias ARN in the value of the `KeyId` parameter.
    #
    # **Required permissions**: [kms:Verify][4] (key policy)
    #
    # **Related operations**: Sign
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][5].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/symmetric-asymmetric.html
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/offline-operations.html#key-spec-sm-offline-verification
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String] :key_id
    #   Identifies the asymmetric KMS key that will be used to verify the
    #   signature. This must be the same KMS key that was used to generate the
    #   signature. If you specify a different KMS key, the signature
    #   verification fails.
    #
    #   To specify a KMS key, use its key ID, key ARN, alias name, or alias
    #   ARN. When using an alias name, prefix it with `"alias/"`. To specify a
    #   KMS key in a different Amazon Web Services account, you must use the
    #   key ARN or alias ARN.
    #
    #   For example:
    #
    #   * Key ID: `1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Key ARN:
    #     `arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab`
    #
    #   * Alias name: `alias/ExampleAlias`
    #
    #   * Alias ARN: `arn:aws:kms:us-east-2:111122223333:alias/ExampleAlias`
    #
    #   To get the key ID and key ARN for a KMS key, use ListKeys or
    #   DescribeKey. To get the alias name and alias ARN, use ListAliases.
    #
    # @option params [required, String, StringIO, File] :message
    #   Specifies the message that was signed. You can submit a raw message of
    #   up to 4096 bytes, or a hash digest of the message. If you submit a
    #   digest, use the `MessageType` parameter with a value of `DIGEST`.
    #
    #   If the message specified here is different from the message that was
    #   signed, the signature verification fails. A message and its hash
    #   digest are considered to be the same message.
    #
    # @option params [String] :message_type
    #   Tells KMS whether the value of the `Message` parameter should be
    #   hashed as part of the signing algorithm. Use `RAW` for unhashed
    #   messages; use `DIGEST` for message digests, which are already hashed;
    #   use `EXTERNAL_MU` for 64-byte representative μ used in ML-DSA signing
    #   as defined in NIST FIPS 204 Section 6.2.
    #
    #   When the value of `MessageType` is `RAW`, KMS uses the standard
    #   signing algorithm, which begins with a hash function. When the value
    #   is `DIGEST`, KMS skips the hashing step in the signing algorithm. When
    #   the value is `EXTERNAL_MU` KMS skips the concatenated hashing of the
    #   public key hash and the message done in the ML-DSA signing algorithm.
    #
    #   Use the `DIGEST` or `EXTERNAL_MU` value only when the value of the
    #   `Message` parameter is a message digest. If you use the `DIGEST` value
    #   with an unhashed message, the security of the signing operation can be
    #   compromised.
    #
    #   When using ECC\_NIST\_EDWARDS25519 KMS keys:
    #
    #   * ED25519\_SHA\_512 signing algorithm requires KMS `MessageType:RAW`
    #
    #   * ED25519\_PH\_SHA\_512 signing algorithm requires KMS
    #     `MessageType:DIGEST`
    #
    #   When the value of `MessageType` is `DIGEST`, the length of the
    #   `Message` value must match the length of hashed messages for the
    #   specified signing algorithm.
    #
    #   When the value of `MessageType` is `EXTERNAL_MU` the length of the
    #   `Message` value must be 64 bytes.
    #
    #   You can submit a message digest and omit the `MessageType` or specify
    #   `RAW` so the digest is hashed again while signing. However, if the
    #   signed message is hashed once while signing, but twice while
    #   verifying, verification fails, even when the message hasn't changed.
    #
    #   The hashing algorithm that `Verify` uses is based on the
    #   `SigningAlgorithm` value.
    #
    #   * Signing algorithms that end in SHA\_256 use the SHA\_256 hashing
    #     algorithm.
    #
    #   * Signing algorithms that end in SHA\_384 use the SHA\_384 hashing
    #     algorithm.
    #
    #   * Signing algorithms that end in SHA\_512 use the SHA\_512 hashing
    #     algorithm.
    #
    #   * Signing algorithms that end in SHAKE\_256 use the SHAKE\_256 hashing
    #     algorithm.
    #
    #   * SM2DSA uses the SM3 hashing algorithm. For details, see [Offline
    #     verification with SM2 key pairs][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/offline-operations.html#key-spec-sm-offline-verification
    #
    # @option params [required, String, StringIO, File] :signature
    #   The signature that the `Sign` operation generated.
    #
    # @option params [required, String] :signing_algorithm
    #   The signing algorithm that was used to sign the message. If you submit
    #   a different algorithm, the signature verification fails.
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   Use a grant token when your permission to call this operation comes
    #   from a new grant that has not yet achieved *eventual consistency*. For
    #   more information, see [Grant token][1] and [Using a grant token][2] in
    #   the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html#grant_token
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/using-grant-token.html
    #
    # @option params [Boolean] :dry_run
    #   Checks if your request will succeed. `DryRun` is an optional
    #   parameter.
    #
    #   To learn more about how to use this parameter, see [Testing your
    #   permissions][1] in the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/testing-permissions.html
    #
    # @return [Types::VerifyResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::VerifyResponse#key_id #key_id} => String
    #   * {Types::VerifyResponse#signature_valid #signature_valid} => Boolean
    #   * {Types::VerifyResponse#signing_algorithm #signing_algorithm} => String
    #
    #
    # @example Example: To use an asymmetric KMS key to verify a digital signature
    #
    #   # This operation uses the public key in an elliptic curve (ECC) asymmetric key to verify a digital signature within AWS
    #   # KMS.
    #
    #   resp = client.verify({
    #     key_id: "alias/ECC_signing_key", # The asymmetric KMS key to be used to verify the digital signature. This example uses an alias to identify the KMS key.
    #     message: "<message to be verified>", # The message that was signed.
    #     message_type: "RAW", # Indicates whether the message is RAW or a DIGEST.
    #     signature: "<binary data>", # The signature to be verified.
    #     signing_algorithm: "ECDSA_SHA_384", # The signing algorithm to be used to verify the signature.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The key ARN of the asymmetric KMS key that was used to verify the digital signature.
    #     signature_valid: true, # A value of 'true' Indicates that the signature was verified. If verification fails, the call to Verify fails.
    #     signing_algorithm: "ECDSA_SHA_384", # The signing algorithm that was used to verify the signature.
    #   }
    #
    # @example Example: To use an asymmetric KMS key to verify a digital signature on a message digest
    #
    #   # This operation uses the public key in an RSA asymmetric signing key pair to verify the digital signature of a message
    #   # digest. Hashing a message into a digest before sending it to KMS lets you verify messages that exceed the 4096-byte
    #   # message size limit. To indicate that the value of Message is a digest, use the MessageType parameter 
    #
    #   resp = client.verify({
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/0987dcba-09fe-87dc-65ba-ab0987654321", # The asymmetric KMS key to be used to verify the digital signature. This example uses an alias to identify the KMS key.
    #     message: "<message digest to be verified>", # The message that was signed.
    #     message_type: "DIGEST", # Indicates whether the message is RAW or a DIGEST. When it is RAW, KMS hashes the message before signing. When it is DIGEST, KMS skips the hashing step and signs the Message value.
    #     signature: "<binary data>", # The signature to be verified.
    #     signing_algorithm: "RSASSA_PSS_SHA_512", # The signing algorithm to be used to verify the signature.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_id: "arn:aws:kms:us-east-2:111122223333:key/0987dcba-09fe-87dc-65ba-ab0987654321", # The key ARN of the asymmetric KMS key that was used to verify the digital signature.
    #     signature_valid: true, # A value of 'true' Indicates that the signature was verified. If verification fails, the call to Verify fails.
    #     signing_algorithm: "RSASSA_PSS_SHA_512", # The signing algorithm that was used to verify the signature.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.verify({
    #     key_id: "KeyIdType", # required
    #     message: "data", # required
    #     message_type: "RAW", # accepts RAW, DIGEST, EXTERNAL_MU
    #     signature: "data", # required
    #     signing_algorithm: "RSASSA_PSS_SHA_256", # required, accepts RSASSA_PSS_SHA_256, RSASSA_PSS_SHA_384, RSASSA_PSS_SHA_512, RSASSA_PKCS1_V1_5_SHA_256, RSASSA_PKCS1_V1_5_SHA_384, RSASSA_PKCS1_V1_5_SHA_512, ECDSA_SHA_256, ECDSA_SHA_384, ECDSA_SHA_512, SM2DSA, ML_DSA_SHAKE_256, ED25519_SHA_512, ED25519_PH_SHA_512
    #     grant_tokens: ["GrantTokenType"],
    #     dry_run: false,
    #   })
    #
    # @example Response structure
    #
    #   resp.key_id #=> String
    #   resp.signature_valid #=> Boolean
    #   resp.signing_algorithm #=> String, one of "RSASSA_PSS_SHA_256", "RSASSA_PSS_SHA_384", "RSASSA_PSS_SHA_512", "RSASSA_PKCS1_V1_5_SHA_256", "RSASSA_PKCS1_V1_5_SHA_384", "RSASSA_PKCS1_V1_5_SHA_512", "ECDSA_SHA_256", "ECDSA_SHA_384", "ECDSA_SHA_512", "SM2DSA", "ML_DSA_SHAKE_256", "ED25519_SHA_512", "ED25519_PH_SHA_512"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/Verify AWS API Documentation
    #
    # @overload verify(params = {})
    # @param [Hash] params ({})
    def verify(params = {}, options = {})
      req = build_request(:verify, params)
      req.send_request(options)
    end

    # Verifies the hash-based message authentication code (HMAC) for a
    # specified message, HMAC KMS key, and MAC algorithm. To verify the
    # HMAC, `VerifyMac` computes an HMAC using the message, HMAC KMS key,
    # and MAC algorithm that you specify, and compares the computed HMAC to
    # the HMAC that you specify. If the HMACs are identical, the
    # verification succeeds; otherwise, it fails. Verification indicates
    # that the message hasn't changed since the HMAC was calculated, and
    # the specified key was used to generate and verify the HMAC.
    #
    # HMAC KMS keys and the HMAC algorithms that KMS uses conform to
    # industry standards defined in [RFC 2104][1].
    #
    # This operation is part of KMS support for HMAC KMS keys. For details,
    # see [HMAC keys in KMS][2] in the *Key Management Service Developer
    # Guide*.
    #
    # The KMS key that you use for this operation must be in a compatible
    # key state. For details, see [Key states of KMS keys][3] in the *Key
    # Management Service Developer Guide*.
    #
    # **Cross-account use**: Yes. To perform this operation with a KMS key
    # in a different Amazon Web Services account, specify the key ARN or
    # alias ARN in the value of the `KeyId` parameter.
    #
    # **Required permissions**: [kms:VerifyMac][4] (key policy)
    #
    # **Related operations**: GenerateMac
    #
    # **Eventual consistency**: The KMS API follows an eventual consistency
    # model. For more information, see [KMS eventual consistency][5].
    #
    #
    #
    # [1]: https://datatracker.ietf.org/doc/html/rfc2104
    # [2]: https://docs.aws.amazon.com/kms/latest/developerguide/hmac.html
    # [3]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    # [4]: https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
    # [5]: https://docs.aws.amazon.com/kms/latest/developerguide/accessing-kms.html#programming-eventual-consistency
    #
    # @option params [required, String, StringIO, File] :message
    #   The message that will be used in the verification. Enter the same
    #   message that was used to generate the HMAC.
    #
    #   GenerateMac and `VerifyMac` do not provide special handling for
    #   message digests. If you generated an HMAC for a hash digest of a
    #   message, you must verify the HMAC for the same hash digest.
    #
    # @option params [required, String] :key_id
    #   The KMS key that will be used in the verification.
    #
    #   Enter a key ID of the KMS key that was used to generate the HMAC. If
    #   you identify a different KMS key, the `VerifyMac` operation fails.
    #
    # @option params [required, String] :mac_algorithm
    #   The MAC algorithm that will be used in the verification. Enter the
    #   same MAC algorithm that was used to compute the HMAC. This algorithm
    #   must be supported by the HMAC KMS key identified by the `KeyId`
    #   parameter.
    #
    # @option params [required, String, StringIO, File] :mac
    #   The HMAC to verify. Enter the HMAC that was generated by the
    #   GenerateMac operation when you specified the same message, HMAC KMS
    #   key, and MAC algorithm as the values specified in this request.
    #
    # @option params [Array<String>] :grant_tokens
    #   A list of grant tokens.
    #
    #   Use a grant token when your permission to call this operation comes
    #   from a new grant that has not yet achieved *eventual consistency*. For
    #   more information, see [Grant token][1] and [Using a grant token][2] in
    #   the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/grants.html#grant_token
    #   [2]: https://docs.aws.amazon.com/kms/latest/developerguide/using-grant-token.html
    #
    # @option params [Boolean] :dry_run
    #   Checks if your request will succeed. `DryRun` is an optional
    #   parameter.
    #
    #   To learn more about how to use this parameter, see [Testing your
    #   permissions][1] in the *Key Management Service Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/kms/latest/developerguide/testing-permissions.html
    #
    # @return [Types::VerifyMacResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::VerifyMacResponse#key_id #key_id} => String
    #   * {Types::VerifyMacResponse#mac_valid #mac_valid} => Boolean
    #   * {Types::VerifyMacResponse#mac_algorithm #mac_algorithm} => String
    #
    #
    # @example Example: To verify an HMAC
    #
    #   # This example verifies an HMAC for a particular message, HMAC KMS keys, and MAC algorithm. A value of 'true' in the
    #   # MacValid value in the response indicates that the HMAC is valid.
    #
    #   resp = client.verify_mac({
    #     key_id: "1234abcd-12ab-34cd-56ef-1234567890ab", # The HMAC KMS key input to the HMAC algorithm.
    #     mac: "<HMAC_TAG>", # The HMAC to be verified.
    #     mac_algorithm: "HMAC_SHA_384", # The HMAC algorithm requested for the operation.
    #     message: "Hello World", # The message input to the HMAC algorithm.
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     key_id: "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab", # The key ARN of the HMAC key used in the operation.
    #     mac_algorithm: "HMAC_SHA_384", # The HMAC algorithm used in the operation.
    #     mac_valid: true, # A value of 'true' indicates that verification succeeded. If verification fails, the call to VerifyMac fails.
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.verify_mac({
    #     message: "data", # required
    #     key_id: "KeyIdType", # required
    #     mac_algorithm: "HMAC_SHA_224", # required, accepts HMAC_SHA_224, HMAC_SHA_256, HMAC_SHA_384, HMAC_SHA_512
    #     mac: "data", # required
    #     grant_tokens: ["GrantTokenType"],
    #     dry_run: false,
    #   })
    #
    # @example Response structure
    #
    #   resp.key_id #=> String
    #   resp.mac_valid #=> Boolean
    #   resp.mac_algorithm #=> String, one of "HMAC_SHA_224", "HMAC_SHA_256", "HMAC_SHA_384", "HMAC_SHA_512"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/kms-2014-11-01/VerifyMac AWS API Documentation
    #
    # @overload verify_mac(params = {})
    # @param [Hash] params ({})
    def verify_mac(params = {}, options = {})
      req = build_request(:verify_mac, params)
      req.send_request(options)
    end

    # @!endgroup

    # @param params ({})
    # @api private
    def build_request(operation_name, params = {})
      handlers = @handlers.for(operation_name)
      tracer = config.telemetry_provider.tracer_provider.tracer(
        Aws::Telemetry.module_to_tracer_name('Aws::KMS')
      )
      context = Seahorse::Client::RequestContext.new(
        operation_name: operation_name,
        operation: config.api.operation(operation_name),
        client: self,
        params: params,
        config: config,
        tracer: tracer
      )
      context[:gem_name] = 'aws-sdk-kms'
      context[:gem_version] = '1.123.0'
      Seahorse::Client::Request.new(handlers, context)
    end

    # @api private
    # @deprecated
    def waiter_names
      []
    end

    class << self

      # @api private
      attr_reader :identifier

      # @api private
      def errors_module
        Errors
      end

    end
  end
end
