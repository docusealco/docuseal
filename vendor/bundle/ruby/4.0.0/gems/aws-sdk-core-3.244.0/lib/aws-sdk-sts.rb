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

Aws::Plugins::GlobalConfiguration.add_identifier(:sts)

# This module provides support for AWS Security Token Service. This module is available in the
# `aws-sdk-core` gem.
#
# # Client
#
# The {Client} class provides one method for each API operation. Operation
# methods each accept a hash of request parameters and return a response
# structure.
#
#     sts = Aws::STS::Client.new
#     resp = sts.assume_role(params)
#
# See {Client} for more information.
#
# # Errors
#
# Errors returned from AWS Security Token Service are defined in the
# {Errors} module and all extend {Errors::ServiceError}.
#
#     begin
#       # do stuff
#     rescue Aws::STS::Errors::ServiceError
#       # rescues all AWS Security Token Service API errors
#     end
#
# See {Errors} for more information.
#
# @!group service
module Aws::STS
  autoload :Types, 'aws-sdk-sts/types'
  autoload :ClientApi, 'aws-sdk-sts/client_api'
  module Plugins
    autoload :Endpoints, 'aws-sdk-sts/plugins/endpoints.rb'
  end
  autoload :Client, 'aws-sdk-sts/client'
  autoload :Errors, 'aws-sdk-sts/errors'
  autoload :Resource, 'aws-sdk-sts/resource'
  autoload :EndpointParameters, 'aws-sdk-sts/endpoint_parameters'
  autoload :EndpointProvider, 'aws-sdk-sts/endpoint_provider'
  autoload :Endpoints, 'aws-sdk-sts/endpoints'

  GEM_VERSION = '3.244.0'

end

require_relative 'aws-sdk-sts/customizations'
