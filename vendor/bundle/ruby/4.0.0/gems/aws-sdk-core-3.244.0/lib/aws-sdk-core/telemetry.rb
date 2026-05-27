# frozen_string_literal: true

require_relative 'telemetry/base'
require_relative 'telemetry/no_op'
require_relative 'telemetry/otel'
require_relative 'telemetry/span_kind'
require_relative 'telemetry/span_status'

module Aws
  # Observability is the extent to which a system's current state can be
  # inferred from the data it emits. The data emitted is commonly referred
  # as Telemetry. The AWS SDK for Ruby currently supports traces as
  # a telemetry signal.
  #
  # A telemetry provider is used to emit telemetry data. By default, the
  # {NoOpTelemetryProvider} will not record or emit any telemetry data.
  # The SDK currently supports OpenTelemetry (OTel) as a provider. See
  # {OTelProvider} for more information.
  #
  # If a provider isn't supported, you can implement your own provider by
  # inheriting the following base classes and implementing the interfaces
  # defined:
  # * {TelemetryProviderBase}
  # * {ContextManagerBase}
  # * {TracerProviderBase}
  # * {TracerBase}
  # * {SpanBase}
  module Telemetry
    class << self
      # @api private
      def module_to_tracer_name(module_name)
        "#{module_name.gsub('::', '.')}.client".downcase
      end

      # @api private
      def http_request_attrs(context)
        {
          'http.method' => context.http_request.http_method,
          'net.protocol.name' => 'http'
        }.tap do |h|
          h['net.protocol.version'] =
            if context.client.is_a? Seahorse::Client::AsyncBase
              '2'
            else
              Net::HTTP::HTTPVersion
            end

          unless context.config.stub_responses
            h['net.peer.name'] = context.http_request.endpoint.host
            h['net.peer.port'] = context.http_request.endpoint.port.to_s
          end

          if context.http_request.headers.key?('Content-Length')
            h['http.request_content_length'] =
              context.http_request.headers['Content-Length']
          end
        end
      end

      # @api private
      def http_response_attrs(context)
        {
          'http.status_code' => context.http_response.status_code.to_s
        }.tap do |h|
          if context.http_response.headers.key?('Content-Length')
            h['http.response_content_length'] =
              context.http_response.headers['Content-Length']
          end

          if context.http_response.headers.key?('x-amz-request-id')
            h['aws.request_id'] =
              context.http_response.headers['x-amz-request-id']
          end
        end
      end
    end
  end
end
