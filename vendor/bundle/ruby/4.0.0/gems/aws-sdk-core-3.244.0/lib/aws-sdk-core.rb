# frozen_string_literal: true

require 'aws-partitions'
require 'seahorse'
require 'jmespath'
require 'aws-sigv4'

require_relative 'aws-sdk-core/deprecations'
# defaults
require_relative 'aws-defaults'

module Aws

  autoload :IniParser, 'aws-sdk-core/ini_parser'

  # Credentials and credentials providers
  autoload :Credentials, 'aws-sdk-core/credentials'
  autoload :CredentialProvider, 'aws-sdk-core/credential_provider'
  autoload :RefreshingCredentials, 'aws-sdk-core/refreshing_credentials'
  autoload :AssumeRoleCredentials, 'aws-sdk-core/assume_role_credentials'
  autoload :AssumeRoleWebIdentityCredentials, 'aws-sdk-core/assume_role_web_identity_credentials'
  autoload :CredentialProviderChain, 'aws-sdk-core/credential_provider_chain'
  autoload :ECSCredentials, 'aws-sdk-core/ecs_credentials'
  autoload :InstanceProfileCredentials, 'aws-sdk-core/instance_profile_credentials'
  autoload :SharedCredentials, 'aws-sdk-core/shared_credentials'
  autoload :ProcessCredentials, 'aws-sdk-core/process_credentials'
  autoload :SSOCredentials, 'aws-sdk-core/sso_credentials'
  autoload :LoginCredentials, 'aws-sdk-core/login_credentials'


  # tokens and token providers
  autoload :Token, 'aws-sdk-core/token'
  autoload :TokenProvider, 'aws-sdk-core/token_provider'
  autoload :StaticTokenProvider, 'aws-sdk-core/static_token_provider'
  autoload :RefreshingToken, 'aws-sdk-core/refreshing_token'
  autoload :SSOTokenProvider, 'aws-sdk-core/sso_token_provider'
  autoload :TokenProviderChain, 'aws-sdk-core/token_provider_chain'

  # client modules
  autoload :ClientStubs, 'aws-sdk-core/client_stubs'
  autoload :AsyncClientStubs, 'aws-sdk-core/async_client_stubs'
  autoload :EagerLoader, 'aws-sdk-core/eager_loader'
  autoload :Errors, 'aws-sdk-core/errors'
  autoload :PageableResponse, 'aws-sdk-core/pageable_response'
  autoload :Pager, 'aws-sdk-core/pager'
  autoload :ParamConverter, 'aws-sdk-core/param_converter'
  autoload :ParamValidator, 'aws-sdk-core/param_validator'
  autoload :SharedConfig, 'aws-sdk-core/shared_config'
  autoload :Structure, 'aws-sdk-core/structure'
  autoload :EmptyStructure, 'aws-sdk-core/structure'
  autoload :TypeBuilder, 'aws-sdk-core/type_builder'
  autoload :Util, 'aws-sdk-core/util'

  # protocols
  autoload :ErrorHandler, 'aws-sdk-core/error_handler'
  autoload :Rest, 'aws-sdk-core/rest'
  autoload :Xml, 'aws-sdk-core/xml'
  autoload :Json, 'aws-sdk-core/json'
  autoload :Query, 'aws-sdk-core/query'
  autoload :RpcV2, 'aws-sdk-core/rpc_v2'

  # event stream
  autoload :Binary, 'aws-sdk-core/binary'
  autoload :EventEmitter, 'aws-sdk-core/event_emitter'

  # endpoint discovery
  autoload :EndpointCache, 'aws-sdk-core/endpoint_cache'

  autoload :Telemetry, 'aws-sdk-core/telemetry'

  # utilities
  autoload :ARN, 'aws-sdk-core/arn'
  autoload :ARNParser, 'aws-sdk-core/arn_parser'
  autoload :EC2Metadata, 'aws-sdk-core/ec2_metadata'
  autoload :LRUCache, 'aws-sdk-core/lru_cache'

  # dynamic endpoints
  autoload :Endpoints, 'aws-sdk-core/endpoints'

  CORE_GEM_VERSION = File.read(File.expand_path('../VERSION', __dir__)).strip

  @config = {}

  class << self

    # @api private
    def shared_config
      enabled = ENV["AWS_SDK_CONFIG_OPT_OUT"] ? false : true
      @shared_config ||= SharedConfig.new(config_enabled: enabled)
    end

    # @return [Hash] Returns a hash of default configuration options shared
    #   by all constructed clients.
    attr_reader :config

    # @param [Hash] config
    def config=(config)
      if Hash === config
        @config = config
      else
        raise ArgumentError, 'configuration object must be a hash'
      end
    end

    # @see (Aws::Partitions.partition)
    def partition(partition_name)
      Aws::Partitions.partition(partition_name)
    end

    # @see (Aws::Partitions.partitions)
    def partitions
      Aws::Partitions.partitions
    end

    # The SDK ships with a ca certificate bundle to use when verifying SSL
    # peer certificates. By default, this cert bundle is *NOT* used. The
    # SDK will rely on the default cert available to OpenSSL. This ensures
    # the cert provided by your OS is used.
    #
    # For cases where the default cert is unavailable, e.g. Windows, you
    # can call this method.
    #
    #     Aws.use_bundled_cert!
    #
    # @return [String] Returns the path to the bundled cert.
    def use_bundled_cert!
      config.delete(:ssl_ca_directory)
      config.delete(:ssl_ca_store)
      config[:ssl_ca_bundle] = File.expand_path(File.join(
        File.dirname(__FILE__),
        '..',
        'ca-bundle.crt'
      ))
    end

    # Close any long-lived connections maintained by the SDK's internal
    # connection pool.
    #
    # Applications that rely heavily on the `fork()` system call on POSIX systems
    # should call this method in the child process directly after fork to ensure
    # there are no race conditions between the parent
    # process and its children
    # for the pooled TCP connections.
    #
    # Child processes that make multi-threaded calls to the SDK should block on
    # this call before beginning work.
    #
    # @return [nil]
    def empty_connection_pools!
      Seahorse::Client::NetHttp::ConnectionPool.pools.each do |pool|
        pool.empty!
      end
    end

    # @api private
    def eager_autoload!(*args)
      msg = 'Aws.eager_autoload is no longer needed, usage of '\
            'autoload has been replaced with require statements'
      warn(msg)
    end

  end
end

# Setup additional autoloads/modules
require_relative 'aws-sdk-core/client_side_monitoring'
require_relative 'aws-sdk-core/log'
require_relative 'aws-sdk-core/plugins'
require_relative 'aws-sdk-core/resources'
require_relative 'aws-sdk-core/stubbing'
require_relative 'aws-sdk-core/waiters'

# aws-sdk-sts is included to support Aws::AssumeRoleCredentials
require_relative 'aws-sdk-sts'

# aws-sdk-sso is included to support Aws::SSOCredentials
require_relative 'aws-sdk-sso'
require_relative 'aws-sdk-ssooidc'

# aws-sdk-signin is included to support Aws::SignInCredentials
require_relative 'aws-sdk-signin'
