# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE


require 'aws-sdk-kms'
require 'aws-sigv4'
require 'aws-sdk-core'

Aws::Plugins::GlobalConfiguration.add_identifier(:s3)

# This module provides support for Amazon Simple Storage Service. This module is available in the
# `aws-sdk-s3` gem.
#
# # Client
#
# The {Client} class provides one method for each API operation. Operation
# methods each accept a hash of request parameters and return a response
# structure.
#
#     s3 = Aws::S3::Client.new
#     resp = s3.abort_multipart_upload(params)
#
# See {Client} for more information.
#
# # Errors
#
# Errors returned from Amazon Simple Storage Service are defined in the
# {Errors} module and all extend {Errors::ServiceError}.
#
#     begin
#       # do stuff
#     rescue Aws::S3::Errors::ServiceError
#       # rescues all Amazon Simple Storage Service API errors
#     end
#
# See {Errors} for more information.
#
# @!group service
module Aws::S3
  autoload :Types, 'aws-sdk-s3/types'
  autoload :ClientApi, 'aws-sdk-s3/client_api'
  module Plugins
    autoload :Endpoints, 'aws-sdk-s3/plugins/endpoints.rb'
  end
  autoload :Client, 'aws-sdk-s3/client'
  autoload :Errors, 'aws-sdk-s3/errors'
  autoload :Waiters, 'aws-sdk-s3/waiters'
  autoload :Resource, 'aws-sdk-s3/resource'
  autoload :EndpointParameters, 'aws-sdk-s3/endpoint_parameters'
  autoload :EndpointProvider, 'aws-sdk-s3/endpoint_provider'
  autoload :Endpoints, 'aws-sdk-s3/endpoints'
  autoload :Bucket, 'aws-sdk-s3/bucket'
  autoload :BucketAcl, 'aws-sdk-s3/bucket_acl'
  autoload :BucketCors, 'aws-sdk-s3/bucket_cors'
  autoload :BucketLifecycle, 'aws-sdk-s3/bucket_lifecycle'
  autoload :BucketLifecycleConfiguration, 'aws-sdk-s3/bucket_lifecycle_configuration'
  autoload :BucketLogging, 'aws-sdk-s3/bucket_logging'
  autoload :BucketNotification, 'aws-sdk-s3/bucket_notification'
  autoload :BucketPolicy, 'aws-sdk-s3/bucket_policy'
  autoload :BucketRequestPayment, 'aws-sdk-s3/bucket_request_payment'
  autoload :BucketTagging, 'aws-sdk-s3/bucket_tagging'
  autoload :BucketVersioning, 'aws-sdk-s3/bucket_versioning'
  autoload :BucketWebsite, 'aws-sdk-s3/bucket_website'
  autoload :MultipartUpload, 'aws-sdk-s3/multipart_upload'
  autoload :MultipartUploadPart, 'aws-sdk-s3/multipart_upload_part'
  autoload :Object, 'aws-sdk-s3/object'
  autoload :ObjectAcl, 'aws-sdk-s3/object_acl'
  autoload :ObjectSummary, 'aws-sdk-s3/object_summary'
  autoload :ObjectVersion, 'aws-sdk-s3/object_version'
  autoload :EventStreams, 'aws-sdk-s3/event_streams'

  GEM_VERSION = '1.218.0'

end

require_relative 'aws-sdk-s3/customizations'
