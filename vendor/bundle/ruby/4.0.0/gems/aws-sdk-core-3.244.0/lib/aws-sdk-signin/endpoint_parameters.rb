# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::Signin
  # Endpoint parameters used to influence endpoints per request.
  #
  # @!attribute use_dual_stack
  #   When true, use the dual-stack endpoint. If the configured endpoint does not support dual-stack, dispatching the request MAY return an error.
  #
  #   @return [boolean]
  #
  # @!attribute use_fips
  #   When true, send this request to the FIPS-compliant regional endpoint. If the configured endpoint does not have a FIPS compliant endpoint, dispatching the request will return an error.
  #
  #   @return [boolean]
  #
  # @!attribute endpoint
  #   Override the endpoint used to send this request
  #
  #   @return [string]
  #
  # @!attribute region
  #   The AWS region used to dispatch the request.
  #
  #   @return [string]
  #
  EndpointParameters = Struct.new(
    :use_dual_stack,
    :use_fips,
    :endpoint,
    :region,
  ) do
    include Aws::Structure

    # @api private
    class << self
      PARAM_MAP = {
        'UseDualStack' => :use_dual_stack,
        'UseFIPS' => :use_fips,
        'Endpoint' => :endpoint,
        'Region' => :region,
      }.freeze
    end

    def initialize(options = {})
      self[:use_dual_stack] = options[:use_dual_stack]
      self[:use_dual_stack] = false if self[:use_dual_stack].nil?
      self[:use_fips] = options[:use_fips]
      self[:use_fips] = false if self[:use_fips].nil?
      self[:endpoint] = options[:endpoint]
      self[:region] = options[:region]
    end

    def self.create(config, options={})
      new({
        use_dual_stack: config.use_dualstack_endpoint,
        use_fips: config.use_fips_endpoint,
        endpoint: (config.endpoint.to_s unless config.regional_endpoint),
        region: config.region,
      }.merge(options))
    end
  end
end
