# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE


require 'aws-sdk-core'
require 'aws-sigv4'

Aws::Plugins::GlobalConfiguration.add_identifier(:secretsmanager)

# This module provides support for AWS Secrets Manager. This module is available in the
# `aws-sdk-secretsmanager` gem.
#
# # Client
#
# The {Client} class provides one method for each API operation. Operation
# methods each accept a hash of request parameters and return a response
# structure.
#
#     secrets_manager = Aws::SecretsManager::Client.new
#     resp = secrets_manager.batch_get_secret_value(params)
#
# See {Client} for more information.
#
# # Errors
#
# Errors returned from AWS Secrets Manager are defined in the
# {Errors} module and all extend {Errors::ServiceError}.
#
#     begin
#       # do stuff
#     rescue Aws::SecretsManager::Errors::ServiceError
#       # rescues all AWS Secrets Manager API errors
#     end
#
# See {Errors} for more information.
#
# @!group service
module Aws::SecretsManager
  autoload :Types, 'aws-sdk-secretsmanager/types'
  autoload :ClientApi, 'aws-sdk-secretsmanager/client_api'
  module Plugins
    autoload :Endpoints, 'aws-sdk-secretsmanager/plugins/endpoints.rb'
  end
  autoload :Client, 'aws-sdk-secretsmanager/client'
  autoload :Errors, 'aws-sdk-secretsmanager/errors'
  autoload :Resource, 'aws-sdk-secretsmanager/resource'
  autoload :EndpointParameters, 'aws-sdk-secretsmanager/endpoint_parameters'
  autoload :EndpointProvider, 'aws-sdk-secretsmanager/endpoint_provider'
  autoload :Endpoints, 'aws-sdk-secretsmanager/endpoints'

  GEM_VERSION = '1.129.0'

end

require_relative 'aws-sdk-secretsmanager/customizations'
