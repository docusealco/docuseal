# frozen_string_literal: true

module Aws
  module Plugins
    # @api private
    class Telemetry < Seahorse::Client::Plugin
      option(
        :telemetry_provider,
        default: Aws::Telemetry::NoOpTelemetryProvider,
        doc_type: Aws::Telemetry::TelemetryProviderBase,
        rbs_type: Aws::Telemetry::TelemetryProviderBase,
        docstring: <<-DOCS) do |_cfg|
Allows you to provide a telemetry provider, which is used to 
emit telemetry data. By default, uses `NoOpTelemetryProvider` which 
will not record or emit any telemetry data. The SDK supports the 
following telemetry providers:

* OpenTelemetry (OTel) - To use the OTel provider, install and require the 
`opentelemetry-sdk` gem and then, pass in an instance of a 
`Aws::Telemetry::OTelProvider` for telemetry provider.
        DOCS
        Aws::Telemetry::NoOpTelemetryProvider.new
      end

      def after_initialize(client)
        validate_telemetry_provider(client.config)
      end

      def validate_telemetry_provider(config)
        unless config.telemetry_provider.is_a?(Aws::Telemetry::TelemetryProviderBase)
          raise ArgumentError,
                'Must provide a telemetry provider for the '\
                '`telemetry_provider` configuration option.'
        end
      end

      class Handler < Seahorse::Client::Handler
        def call(context)
          span_wrapper(context) { @handler.call(context) }
        end

        private

        def span_wrapper(context, &block)
          service_id = service_id(context)
          attributes = {
            'rpc.system' => 'aws-api',
            'rpc.service' => service_id,
            'rpc.method' => context.operation.name,
            'code.function' => context.operation_name.to_s,
            'code.namespace' => 'Aws::Plugins::Telemetry'
          }
          context.tracer.in_span(
            parent_span_name(context, service_id),
            attributes: attributes,
            kind: Aws::Telemetry::SpanKind::CLIENT,
            &block
          )
        end

        def service_id(context)
          context.config.api.metadata['serviceId'] ||
            context.config.api.metadata['serviceAbbreviation'] ||
            context.config.api.metadata['serviceFullName']
        end

        def parent_span_name(context, service_id)
          "#{service_id}.#{context.operation.name}".delete(' ')
        end
      end

      handler(Handler, step: :initialize, priority: 99)
    end
  end
end
