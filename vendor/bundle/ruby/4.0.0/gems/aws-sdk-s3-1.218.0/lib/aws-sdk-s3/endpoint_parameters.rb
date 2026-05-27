# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::S3
  # Endpoint parameters used to influence endpoints per request.
  #
  # @!attribute bucket
  #   The S3 bucket used to send the request. This is an optional parameter that will be set automatically for operations that are scoped to an S3 bucket.
  #
  #   @return [string]
  #
  # @!attribute region
  #   The AWS region used to dispatch the request.
  #
  #   @return [string]
  #
  # @!attribute use_fips
  #   When true, send this request to the FIPS-compliant regional endpoint. If the configured endpoint does not have a FIPS compliant endpoint, dispatching the request will return an error.
  #
  #   @return [boolean]
  #
  # @!attribute use_dual_stack
  #   When true, use the dual-stack endpoint. If the configured endpoint does not support dual-stack, dispatching the request MAY return an error.
  #
  #   @return [boolean]
  #
  # @!attribute endpoint
  #   Override the endpoint used to send this request
  #
  #   @return [string]
  #
  # @!attribute force_path_style
  #   When true, force a path-style endpoint to be used where the bucket name is part of the path.
  #
  #   @return [boolean]
  #
  # @!attribute accelerate
  #   When true, use S3 Accelerate. NOTE: Not all regions support S3 accelerate.
  #
  #   @return [boolean]
  #
  # @!attribute use_global_endpoint
  #   Whether the global endpoint should be used, rather then the regional endpoint for us-east-1.
  #
  #   @return [boolean]
  #
  # @!attribute use_object_lambda_endpoint
  #   Internal parameter to use object lambda endpoint for an operation (eg: WriteGetObjectResponse)
  #
  #   @return [boolean]
  #
  # @!attribute key
  #   The S3 Key used to send the request. This is an optional parameter that will be set automatically for operations that are scoped to an S3 Key.
  #
  #   @return [string]
  #
  # @!attribute prefix
  #   The S3 Prefix used to send the request. This is an optional parameter that will be set automatically for operations that are scoped to an S3 Prefix.
  #
  #   @return [string]
  #
  # @!attribute copy_source
  #   The Copy Source used for Copy Object request. This is an optional parameter that will be set automatically for operations that are scoped to Copy Source.
  #
  #   @return [string]
  #
  # @!attribute disable_access_points
  #   Internal parameter to disable Access Point Buckets
  #
  #   @return [boolean]
  #
  # @!attribute disable_multi_region_access_points
  #   Whether multi-region access points (MRAP) should be disabled.
  #
  #   @return [boolean]
  #
  # @!attribute use_arn_region
  #   When an Access Point ARN is provided and this flag is enabled, the SDK MUST use the ARN&#39;s region when constructing the endpoint instead of the client&#39;s configured region.
  #
  #   @return [boolean]
  #
  # @!attribute use_s3_express_control_endpoint
  #   Internal parameter to indicate whether S3Express operation should use control plane, (ex. CreateBucket)
  #
  #   @return [boolean]
  #
  # @!attribute disable_s3_express_session_auth
  #   Parameter to indicate whether S3Express session auth should be disabled
  #
  #   @return [boolean]
  #
  EndpointParameters = Struct.new(
    :bucket,
    :region,
    :use_fips,
    :use_dual_stack,
    :endpoint,
    :force_path_style,
    :accelerate,
    :use_global_endpoint,
    :use_object_lambda_endpoint,
    :key,
    :prefix,
    :copy_source,
    :disable_access_points,
    :disable_multi_region_access_points,
    :use_arn_region,
    :use_s3_express_control_endpoint,
    :disable_s3_express_session_auth,
  ) do
    include Aws::Structure

    # @api private
    class << self
      PARAM_MAP = {
        'Bucket' => :bucket,
        'Region' => :region,
        'UseFIPS' => :use_fips,
        'UseDualStack' => :use_dual_stack,
        'Endpoint' => :endpoint,
        'ForcePathStyle' => :force_path_style,
        'Accelerate' => :accelerate,
        'UseGlobalEndpoint' => :use_global_endpoint,
        'UseObjectLambdaEndpoint' => :use_object_lambda_endpoint,
        'Key' => :key,
        'Prefix' => :prefix,
        'CopySource' => :copy_source,
        'DisableAccessPoints' => :disable_access_points,
        'DisableMultiRegionAccessPoints' => :disable_multi_region_access_points,
        'UseArnRegion' => :use_arn_region,
        'UseS3ExpressControlEndpoint' => :use_s3_express_control_endpoint,
        'DisableS3ExpressSessionAuth' => :disable_s3_express_session_auth,
      }.freeze
    end

    def initialize(options = {})
      self[:bucket] = options[:bucket]
      self[:region] = options[:region]
      self[:use_fips] = options[:use_fips]
      self[:use_fips] = false if self[:use_fips].nil?
      self[:use_dual_stack] = options[:use_dual_stack]
      self[:use_dual_stack] = false if self[:use_dual_stack].nil?
      self[:endpoint] = options[:endpoint]
      self[:force_path_style] = options[:force_path_style]
      self[:force_path_style] = false if self[:force_path_style].nil?
      self[:accelerate] = options[:accelerate]
      self[:accelerate] = false if self[:accelerate].nil?
      self[:use_global_endpoint] = options[:use_global_endpoint]
      self[:use_global_endpoint] = false if self[:use_global_endpoint].nil?
      self[:use_object_lambda_endpoint] = options[:use_object_lambda_endpoint]
      self[:key] = options[:key]
      self[:prefix] = options[:prefix]
      self[:copy_source] = options[:copy_source]
      self[:disable_access_points] = options[:disable_access_points]
      self[:disable_multi_region_access_points] = options[:disable_multi_region_access_points]
      self[:disable_multi_region_access_points] = false if self[:disable_multi_region_access_points].nil?
      self[:use_arn_region] = options[:use_arn_region]
      self[:use_s3_express_control_endpoint] = options[:use_s3_express_control_endpoint]
      self[:disable_s3_express_session_auth] = options[:disable_s3_express_session_auth]
    end

    def self.create(config, options={})
      new({
        region: config.region,
        use_fips: config.use_fips_endpoint,
        endpoint: (config.endpoint.to_s unless config.regional_endpoint),
        force_path_style: config.force_path_style,
        use_global_endpoint: config.s3_us_east_1_regional_endpoint == 'legacy',
        disable_multi_region_access_points: config.s3_disable_multiregion_access_points,
        use_arn_region: config.s3_use_arn_region,
        disable_s3_express_session_auth: config.disable_s3_express_session_auth,
      }.merge(options))
    end
  end
end
