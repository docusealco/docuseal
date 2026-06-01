# frozen_string_literal: true

module Aws
  module Plugins
    # @api private
    class EndpointPattern < Seahorse::Client::Plugin
      option(
        :disable_host_prefix_injection,
        default: false,
        doc_type: 'Boolean',
        docstring: 'When `true`, the SDK will not prepend the modeled host prefix to the endpoint.'
      ) do |cfg|
        resolve_disable_host_prefix_injection(cfg)
      end

      def add_handlers(handlers, _config)
        handlers.add(Handler, priority: 10)
      end

      class << self
        private

        def resolve_disable_host_prefix_injection(cfg)
          value = ENV['AWS_DISABLE_HOST_PREFIX_INJECTION'] ||
                  Aws.shared_config.disable_host_prefix_injection(profile: cfg.profile) ||
                  'false'
          value = Aws::Util.str_2_bool(value)
          unless [true, false].include?(value)
            raise ArgumentError,
                  'Must provide either `true` or `false` for '\
                    'disable_host_prefix_injection profile option or for '\
                    'ENV[\'AWS_DISABLE_HOST_PREFIX_INJECTION\']'
          end
          value
        end
      end

      # @api private
      class Handler < Seahorse::Client::Handler
        def call(context)
          unless context.config.disable_host_prefix_injection
            endpoint_trait = context.operation.endpoint_pattern
            apply_endpoint_trait(context, endpoint_trait) if endpoint_trait && !endpoint_trait.empty?
          end
          @handler.call(context)
        end

        private

        def apply_endpoint_trait(context, trait)
          pattern = trait['hostPrefix']
          return unless pattern

          host_prefix = pattern.gsub(/\{.+?}/) do |label|
            label = label.delete('{}')
            replace_label_value(label, context.operation.input, context.params)
          end
          context.http_request.endpoint.host = host_prefix + context.http_request.endpoint.host
        end

        def replace_label_value(label, input_ref, params)
          name = nil
          input_ref.shape.members.each do |m_name, ref|
            name = m_name if ref['hostLabel'] && ref['hostLabelName'] == label
          end
          raise Errors::MissingEndpointHostLabelValue, name if name.nil? || params[name].nil?

          params[name]
        end
      end
    end
  end
end
