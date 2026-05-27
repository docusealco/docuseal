# frozen_string_literal: true

require_relative 'endpoints/rule'
require_relative 'endpoints/condition'
require_relative 'endpoints/endpoint_rule'
require_relative 'endpoints/endpoint'
require_relative 'endpoints/error_rule'
require_relative 'endpoints/function'
require_relative 'endpoints/matchers'
require_relative 'endpoints/reference'
require_relative 'endpoints/rules_provider'
require_relative 'endpoints/rule_set'
require_relative 'endpoints/templater'
require_relative 'endpoints/tree_rule'
require_relative 'endpoints/url'

require 'aws-sigv4'

module Aws
  # @api private
  module Endpoints
    # Maps config auth scheme preferences to endpoint auth scheme names.
    ENDPOINT_AUTH_PREFERENCE_MAP = {
      'sigv4' => %w[sigv4 sigv4-s3express],
      'sigv4a' => ['sigv4a'],
      'httpBearerAuth' => ['bearer'],
      'noAuth' => ['none']
    }.freeze
    SUPPORTED_ENDPOINT_AUTH = ENDPOINT_AUTH_PREFERENCE_MAP.values.flatten.freeze

    # Maps configured auth scheme preferences to modeled auth traits.
    MODELED_AUTH_PREFERENCE_MAP = {
      'sigv4' => 'aws.auth#sigv4',
      'sigv4a' => 'aws.auth#sigv4a',
      'httpBearerAuth' => 'smithy.api#httpBearerAuth',
      'noAuth' => 'smithy.api#noAuth'
    }.freeze
    SUPPORTED_MODELED_AUTH = MODELED_AUTH_PREFERENCE_MAP.values.freeze

    class << self
      def resolve_auth_scheme(context, endpoint)
        if endpoint && (auth_schemes = endpoint.properties['authSchemes'])
          auth_scheme = endpoint_auth_scheme_preference(auth_schemes, context.config.auth_scheme_preference)
          raise 'No supported auth scheme for this endpoint.' unless auth_scheme

          merge_signing_defaults(auth_scheme, context.config)
        else
          default_auth_scheme(context)
        end
      end

      private

      def endpoint_auth_scheme_preference(auth_schemes, preferred_auth)
        ordered_auth = preferred_auth.each_with_object([]) do |pref, list|
          next unless ENDPOINT_AUTH_PREFERENCE_MAP.key?(pref)

          ENDPOINT_AUTH_PREFERENCE_MAP[pref].each { |name| list << { 'name' => name } }
        end
        ordered_auth += auth_schemes
        ordered_auth.find { |auth| SUPPORTED_ENDPOINT_AUTH.include?(auth['name']) }
      end

      def merge_signing_defaults(auth_scheme, config)
        if %w[sigv4 sigv4a sigv4-s3express].include?(auth_scheme['name'])
          auth_scheme['signingName'] ||= sigv4_name(config)

          # back fill disableNormalizePath for S3 until it gets correctly set in the rules
          if auth_scheme['signingName'] == 's3' &&
            !auth_scheme.include?('disableNormalizePath') &&
            auth_scheme.include?('disableDoubleEncoding')
            auth_scheme['disableNormalizePath'] = auth_scheme['disableDoubleEncoding']
          end
          if auth_scheme['name'] == 'sigv4a'
            # config option supersedes endpoint properties
            auth_scheme['signingRegionSet'] =
              config.sigv4a_signing_region_set || auth_scheme['signingRegionSet'] || [config.region]
          else
            auth_scheme['signingRegion'] ||= config.region
          end
        end
        auth_scheme
      end

      def sigv4_name(config)
        config.api.metadata['signingName'] || config.api.metadata['endpointPrefix']
      end

      def default_auth_scheme(context)
        if (modeled_auth = default_api_auth(context))
          auth = modeled_auth_scheme_preference(modeled_auth, context.config.auth_scheme_preference)
          case auth
          when 'aws.auth#sigv4', 'aws.auth#sigv4a'
            auth_scheme = { 'name' => auth.split('#').last }
            if s3_or_s3v4_signature_version?(context)
              auth_scheme = auth_scheme.merge(
                'disableDoubleEncoding' => true,
                'disableNormalizePath' => true
              )
            end
            merge_signing_defaults(auth_scheme, context.config)
          when 'smithy.api#httpBearerAuth'
            { 'name' => 'bearer' }
          when 'smithy.api#noAuth'
            { 'name' => 'none' }
          else
            raise 'No supported auth trait for this endpoint.'
          end
        else
          legacy_default_auth_scheme(context)
        end
      end

      def modeled_auth_scheme_preference(modeled_auth, preferred_auth)
        ordered_auth = preferred_auth.map { |pref| MODELED_AUTH_PREFERENCE_MAP[pref] }.compact
        ordered_auth += modeled_auth
        ordered_auth.find { |auth| SUPPORTED_MODELED_AUTH.include?(auth) }
      end

      def default_api_auth(context)
        context.config.api.operation(context.operation_name)['auth'] ||
          context.config.api.metadata['auth']
      end

      def s3_or_s3v4_signature_version?(context)
        %w[s3 s3v4].include?(context.config.api.metadata['signatureVersion'])
      end

      # Legacy auth resolution - looks for deprecated signatureVersion
      # and authType traits.

      def legacy_default_auth_scheme(context)
        case legacy_default_api_authtype(context)
        when 'v4', 'v4-unsigned-body'
          auth_scheme = { 'name' => 'sigv4' }
          merge_signing_defaults(auth_scheme, context.config)
        when 's3', 's3v4'
          auth_scheme = {
            'name' => 'sigv4',
            'disableDoubleEncoding' => true,
            'disableNormalizePath' => true
          }
          merge_signing_defaults(auth_scheme, context.config)
        when 'bearer'
          { 'name' => 'bearer' }
        when 'none', nil
          { 'name' => 'none' }
        end
      end

      def legacy_default_api_authtype(context)
        context.config.api.operation(context.operation_name)['authtype'] ||
          context.config.api.metadata['signatureVersion']
      end

    end
  end
end
