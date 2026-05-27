# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE


require 'aws-sdk-core'
require 'aws-sigv4'

Aws::Plugins::GlobalConfiguration.add_identifier(:kms)

# This module provides support for AWS Key Management Service. This module is available in the
# `aws-sdk-kms` gem.
#
# # Client
#
# The {Client} class provides one method for each API operation. Operation
# methods each accept a hash of request parameters and return a response
# structure.
#
#     kms = Aws::KMS::Client.new
#     resp = kms.cancel_key_deletion(params)
#
# See {Client} for more information.
#
# # Errors
#
# Errors returned from AWS Key Management Service are defined in the
# {Errors} module and all extend {Errors::ServiceError}.
#
#     begin
#       # do stuff
#     rescue Aws::KMS::Errors::ServiceError
#       # rescues all AWS Key Management Service API errors
#     end
#
# See {Errors} for more information.
#
# @!group service
module Aws::KMS
  autoload :Types, 'aws-sdk-kms/types'
  autoload :ClientApi, 'aws-sdk-kms/client_api'
  module Plugins
    autoload :Endpoints, 'aws-sdk-kms/plugins/endpoints.rb'
  end
  autoload :Client, 'aws-sdk-kms/client'
  autoload :Errors, 'aws-sdk-kms/errors'
  autoload :Resource, 'aws-sdk-kms/resource'
  autoload :EndpointParameters, 'aws-sdk-kms/endpoint_parameters'
  autoload :EndpointProvider, 'aws-sdk-kms/endpoint_provider'
  autoload :Endpoints, 'aws-sdk-kms/endpoints'

  GEM_VERSION = '1.123.0'

end

require_relative 'aws-sdk-kms/customizations'
