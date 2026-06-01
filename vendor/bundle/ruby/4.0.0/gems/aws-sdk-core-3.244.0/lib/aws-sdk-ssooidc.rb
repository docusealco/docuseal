# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE


unless Module.const_defined?(:Aws)
  require 'aws-sdk-core'
  require 'aws-sigv4'
end

Aws::Plugins::GlobalConfiguration.add_identifier(:ssooidc)

# This module provides support for AWS SSO OIDC. This module is available in the
# `aws-sdk-core` gem.
#
# # Client
#
# The {Client} class provides one method for each API operation. Operation
# methods each accept a hash of request parameters and return a response
# structure.
#
#     ssooidc = Aws::SSOOIDC::Client.new
#     resp = ssooidc.create_token(params)
#
# See {Client} for more information.
#
# # Errors
#
# Errors returned from AWS SSO OIDC are defined in the
# {Errors} module and all extend {Errors::ServiceError}.
#
#     begin
#       # do stuff
#     rescue Aws::SSOOIDC::Errors::ServiceError
#       # rescues all AWS SSO OIDC API errors
#     end
#
# See {Errors} for more information.
#
# @!group service
module Aws::SSOOIDC
  autoload :Types, 'aws-sdk-ssooidc/types'
  autoload :ClientApi, 'aws-sdk-ssooidc/client_api'
  module Plugins
    autoload :Endpoints, 'aws-sdk-ssooidc/plugins/endpoints.rb'
  end
  autoload :Client, 'aws-sdk-ssooidc/client'
  autoload :Errors, 'aws-sdk-ssooidc/errors'
  autoload :Resource, 'aws-sdk-ssooidc/resource'
  autoload :EndpointParameters, 'aws-sdk-ssooidc/endpoint_parameters'
  autoload :EndpointProvider, 'aws-sdk-ssooidc/endpoint_provider'
  autoload :Endpoints, 'aws-sdk-ssooidc/endpoints'

  GEM_VERSION = '3.244.0'

end

require_relative 'aws-sdk-ssooidc/customizations'
