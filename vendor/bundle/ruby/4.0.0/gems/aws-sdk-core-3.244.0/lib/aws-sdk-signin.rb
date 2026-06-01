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

Aws::Plugins::GlobalConfiguration.add_identifier(:signin)

# This module provides support for AWS Sign-In Service. This module is available in the
# `aws-sdk-core` gem.
#
# # Client
#
# The {Client} class provides one method for each API operation. Operation
# methods each accept a hash of request parameters and return a response
# structure.
#
#     signin = Aws::Signin::Client.new
#     resp = signin.create_o_auth_2_token(params)
#
# See {Client} for more information.
#
# # Errors
#
# Errors returned from AWS Sign-In Service are defined in the
# {Errors} module and all extend {Errors::ServiceError}.
#
#     begin
#       # do stuff
#     rescue Aws::Signin::Errors::ServiceError
#       # rescues all AWS Sign-In Service API errors
#     end
#
# See {Errors} for more information.
#
# @!group service
module Aws::Signin
  autoload :Types, 'aws-sdk-signin/types'
  autoload :ClientApi, 'aws-sdk-signin/client_api'
  module Plugins
    autoload :Endpoints, 'aws-sdk-signin/plugins/endpoints.rb'
  end
  autoload :Client, 'aws-sdk-signin/client'
  autoload :Errors, 'aws-sdk-signin/errors'
  autoload :Resource, 'aws-sdk-signin/resource'
  autoload :EndpointParameters, 'aws-sdk-signin/endpoint_parameters'
  autoload :EndpointProvider, 'aws-sdk-signin/endpoint_provider'
  autoload :Endpoints, 'aws-sdk-signin/endpoints'

  GEM_VERSION = '3.244.0'

end

require_relative 'aws-sdk-signin/customizations'
