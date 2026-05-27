# frozen_string_literal: true

module Aws
  # setup autoloading for Plugins
  # Most plugins are required explicitly from service clients
  # but users may reference them outside of client usage.
  module Plugins
    autoload :ApiKey, 'aws-sdk-core/plugins/api_key'
    autoload :BearerAuthorization, 'aws-sdk-core/plugins/bearer_authorization'
    autoload :ChecksumAlgorithm, 'aws-sdk-core/plugins/checksum_algorithm'
    autoload :ClientMetricsPlugin, 'aws-sdk-core/plugins/client_metrics_plugin'
    autoload :ClientMetricsSendPlugin, 'aws-sdk-core/plugins/client_metrics_send_plugin'
    autoload :CredentialsConfiguration, 'aws-sdk-core/plugins/credentials_configuration'
    autoload :DefaultsMode, 'aws-sdk-core/plugins/defaults_mode'
    autoload :EndpointDiscovery, 'aws-sdk-core/plugins/endpoint_discovery'
    autoload :EndpointPattern, 'aws-sdk-core/plugins/endpoint_pattern'
    autoload :EventStreamConfiguration, 'aws-sdk-core/plugins/event_stream_configuration'
    autoload :GlobalConfiguration, 'aws-sdk-core/plugins/global_configuration'
    autoload :HelpfulSocketErrors, 'aws-sdk-core/plugins/helpful_socket_errors'
    autoload :HttpChecksum, 'aws-sdk-core/plugins/http_checksum'
    autoload :IdempotencyToken, 'aws-sdk-core/plugins/idempotency_token'
    autoload :InvocationId, 'aws-sdk-core/plugins/invocation_id'
    autoload :JsonvalueConverter, 'aws-sdk-core/plugins/jsonvalue_converter'
    autoload :Logging, 'aws-sdk-core/plugins/logging'
    autoload :ParamConverter, 'aws-sdk-core/plugins/param_converter'
    autoload :ParamValidator, 'aws-sdk-core/plugins/param_validator'
    autoload :RecursionDetection, 'aws-sdk-core/plugins/recursion_detection'
    autoload :RegionalEndpoint, 'aws-sdk-core/plugins/regional_endpoint'
    autoload :RequestCompression, 'aws-sdk-core/plugins/request_compression'
    autoload :ResponsePaging, 'aws-sdk-core/plugins/response_paging'
    autoload :RetryErrors, 'aws-sdk-core/plugins/retry_errors'
    autoload :Sign, 'aws-sdk-core/plugins/sign'
    autoload :SignatureV4, 'aws-sdk-core/plugins/signature_v4'
    autoload :StubResponses, 'aws-sdk-core/plugins/stub_responses'
    autoload :Telemetry, 'aws-sdk-core/plugins/telemetry'
    autoload :TransferEncoding, 'aws-sdk-core/plugins/transfer_encoding'
    autoload :UserAgent, 'aws-sdk-core/plugins/user_agent'
  end
end