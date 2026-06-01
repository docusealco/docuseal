# frozen_string_literal: true

module Aws
  module Telemetry
    # OTelProvider allows to emit telemetry data based on OpenTelemetry.
    #
    # To use this provider, require the `opentelemetry-sdk` gem and then,
    # pass in an instance of a `Aws::Telemetry::OTelProvider` as the
    # telemetry provider in the client config.
    #
    # @example Configuration
    #     require 'opentelemetry-sdk'
    #
    #     # sets up the OpenTelemetry SDK with their config defaults
    #     OpenTelemetry::SDK.configure
    #
    #     otel_provider = Aws::Telemetry::OTelProvider.new
    #     client = Aws::S3::Client.new(telemetry_provider: otel_provider)
    #
    # OpenTelemetry supports many ways to export your telemetry data.
    # See {https://opentelemetry.io/docs/languages/ruby/exporters here} for
    # more information.
    #
    # @example Exporting via console
    #     require 'opentelemetry-sdk'
    #
    #     ENV['OTEL_TRACES_EXPORTER'] ||= 'console'
    #
    #     # configures the OpenTelemetry SDK with defaults
    #     OpenTelemetry::SDK.configure
    #
    #     otel_provider = Aws::Telemetry::OTelProvider.new
    #     client = Aws::S3::Client.new(telemetry_provider: otel_provider)
    class OTelProvider < TelemetryProviderBase
      def initialize
        unless otel_loaded?
          raise ArgumentError,
                'Requires the `opentelemetry-sdk` gem to use OTel Provider.'
        end
        super(
          tracer_provider: OTelTracerProvider.new,
          context_manager: OTelContextManager.new
        )
      end

      private

      def otel_loaded?
        if @use_otel.nil?
          @use_otel =
            begin
              require 'opentelemetry-sdk'
              true
            rescue LoadError, NameError
              false
            end
        end
        @use_otel
      end
    end

    # OpenTelemetry-based {TracerProviderBase}, an entry point for
    # creating Tracer instances.
    class OTelTracerProvider < TracerProviderBase
      def initialize
        super
        @tracer_provider = OpenTelemetry.tracer_provider
      end

      # Returns a Tracer instance.
      #
      # @param [optional String] name Tracer name
      # @return [Aws::Telemetry::OTelTracer]
      def tracer(name = nil)
        OTelTracer.new(@tracer_provider.tracer(name))
      end
    end

    # OpenTelemetry-based {TracerBase}, responsible for creating spans.
    class OTelTracer < TracerBase
      def initialize(tracer)
        super()
        @tracer = tracer
      end

      # Used when a caller wants to manage the activation/deactivation and
      # lifecycle of the Span and its parent manually.
      #
      # @param [String] name Span name
      # @param [Object] with_parent Parent Context
      # @param [Hash] attributes Attributes to attach to the span
      # @param [Aws::Telemetry::SpanKind] kind Type of Span
      # @return [Aws::Telemetry::OTelSpan]
      def start_span(name, with_parent: nil, attributes: nil, kind: nil)
        span = @tracer.start_span(
          name,
          with_parent: with_parent,
          attributes: attributes,
          kind: kind
        )
        OTelSpan.new(span)
      end

      # A helper for the default use-case of extending the current trace
      # with a span.
      # On exit, the Span that was active before calling this method will
      # be reactivated. If an exception occurs during the execution of the
      # provided block, it will be recorded on the span and re-raised.
      #
      # @param [String] name Span name
      # @param [Hash] attributes Attributes to attach to the span
      # @param [Aws::Telemetry::SpanKind] kind Type of Span
      # @return [Aws::Telemetry::OTelSpan]
      def in_span(name, attributes: nil, kind: nil, &block)
        @tracer.in_span(name, attributes: attributes, kind: kind) do |span|
          block.call(OTelSpan.new(span))
        end
      end

      # Returns the current active span.
      #
      # @return [Aws::Telemetry::OTelSpan]
      def current_span
        OTelSpan.new(OpenTelemetry::Trace.current_span)
      end
    end

    # OpenTelemetry-based {SpanBase}, represents a single operation
    # within a trace.
    class OTelSpan < SpanBase
      def initialize(span)
        super()
        @span = span
      end

      # Set attribute.
      #
      # @param [String] key
      # @param [String, Boolean, Numeric, Array<String, Numeric, Boolean>] value
      #   Value must be non-nil and (array of) string, boolean or numeric type.
      #   Array values must not contain nil elements and all elements must be of
      #   the same basic type (string, numeric, boolean)
      # @return [self] returns itself
      def set_attribute(key, value)
        @span.set_attribute(key, value)
      end
      alias []= set_attribute

      # Add attributes.
      #
      # @param [Hash{String => String, Numeric, Boolean, Array<String, Numeric,
      #   Boolean>}] attributes Values must be non-nil and (array of) string,
      #   boolean or numeric type. Array values must not contain nil elements
      #   and all elements must be of the same basic type (string, numeric,
      #   boolean)
      # @return [self] returns itself
      def add_attributes(attributes)
        @span.add_attributes(attributes)
      end

      # Add event to a Span.
      #
      # @param [String] name Name of the event
      # @param [Hash{String => String, Numeric, Boolean, Array<String,
      #   Numeric, Boolean>}] attributes Values must be non-nil and (array of)
      #   string, boolean or numeric type. Array values must not contain nil
      #   elements and all elements must be of the same basic type (string,
      #   numeric, boolean)
      # @return [self] returns itself
      def add_event(name, attributes: nil)
        @span.add_event(name, attributes: attributes)
      end

      # Sets the Span status.
      #
      # @param [Aws::Telemetry::Status] status The new status, which
      #   overrides the default Span status, which is `OK`
      # @return [void]
      def status=(status)
        @span.status = status
      end

      # Finishes the Span.
      #
      # @param [Time] end_timestamp End timestamp for the span
      # @return [self] returns itself
      def finish(end_timestamp: nil)
        @span.finish(end_timestamp: end_timestamp)
      end

      # Record an exception during the execution of this span. Multiple
      # exceptions can be recorded on a span.
      #
      # @param [Exception] exception The exception to be recorded
      # @param [Hash{String => String, Numeric, Boolean, Array<String,
      #   Numeric, Boolean>}] attributes One or more key:value pairs, where the
      #   keys must be strings and the values may be (array of) string, boolean
      #   or numeric type
      # @return [void]
      def record_exception(exception, attributes: nil)
        @span.record_exception(exception, attributes: attributes)
      end
    end

    # OpenTelemetry-based {ContextManagerBase}, manages context and
    # used to return the current context within a trace.
    class OTelContextManager < ContextManagerBase
      # Returns current context.
      #
      # @return [Context]
      def current
        OpenTelemetry::Context.current
      end

      # Associates a Context with the caller’s current execution unit.
      # Returns a token to be used with the matching call to detach.
      #
      # @param [Context] context The new context
      # @return [Object] token A token to be used when detaching
      def attach(context)
        OpenTelemetry::Context.attach(context)
      end

      # Restore the previous Context associated with the current
      # execution unit to the value it had before attaching a
      # specified Context.
      #
      # @param [Object] token The token provided by matching the call to attach
      # @return [Boolean] `True` if the calls matched, `False` otherwise
      def detach(token)
        OpenTelemetry::Context.detach(token)
      end
    end
  end
end
