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

Aws::Plugins::GlobalConfiguration.add_identifier(:sso)

# This module provides support for AWS Single Sign-On. This module is available in the
# `aws-sdk-core` gem.
#
# # Client
#
# The {Client} class provides one method for each API operation. Operation
# methods each accept a hash of request parameters and return a response
# structure.
#
#     sso = Aws::SSO::Client.new
#     resp = sso.get_role_credentials(params)
#
# See {Client} for more information.
#
# # Errors
#
# Errors returned from AWS Single Sign-On are defined in the
# {Errors} module and all extend {Errors::ServiceError}.
#
#     begin
#       # do stuff
#     rescue Aws::SSO::Errors::ServiceError
#       # rescues all AWS Single Sign-On API errors
#     end
#
# See {Errors} for more information.
#
# @!group service
module Aws::SSO
  autoload :Types, 'aws-sdk-sso/types'
  autoload :ClientApi, 'aws-sdk-sso/client_api'
  module Plugins
    autoload :Endpoints, 'aws-sdk-sso/plugins/endpoints.rb'
  end
  autoload :Client, 'aws-sdk-sso/client'
  autoload :Errors, 'aws-sdk-sso/errors'
  autoload :Resource, 'aws-sdk-sso/resource'
  autoload :EndpointParameters, 'aws-sdk-sso/endpoint_parameters'
  autoload :EndpointProvider, 'aws-sdk-sso/endpoint_provider'
  autoload :Endpoints, 'aws-sdk-sso/endpoints'

  GEM_VERSION = '3.244.0'

end

require_relative 'aws-sdk-sso/customizations'
