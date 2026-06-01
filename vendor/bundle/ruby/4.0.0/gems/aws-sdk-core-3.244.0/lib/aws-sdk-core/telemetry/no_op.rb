# frozen_string_literal: true

module Aws
  module Telemetry
    # No-op implementation for {TelemetryProviderBase}.
    class NoOpTelemetryProvider < TelemetryProviderBase
      def initialize
        super(
          tracer_provider: NoOpTracerProvider.new,
          context_manager: NoOpContextManager.new
        )
      end
    end

    # No-op implementation for {TracerProviderBase}.
    class NoOpTracerProvider < TracerProviderBase
      def tracer(name = nil)
        @tracer ||= NoOpTracer.new
      end
    end

    # No-op implementation for {TracerBase}.
    class NoOpTracer < TracerBase
      def start_span(name, with_parent: nil, attributes: nil, kind: nil)
        NoOpSpan.new
      end

      def in_span(name, attributes: nil, kind: nil)
        yield NoOpSpan.new
      end

      def current_span
        NoOpSpan.new
      end
    end

    # No-op implementation for {SpanBase}.
    class NoOpSpan < SpanBase
      def set_attribute(key, value)
        self
      end
      alias []= set_attribute

      def add_attributes(attributes)
        self
      end

      def add_event(name, attributes: nil)
        self
      end

      def status=(status); end

      def finish(end_timestamp: nil)
        self
      end

      def record_exception(exception, attributes: nil); end
    end

    # No-op implementation for {ContextManagerBase}.
    class NoOpContextManager < ContextManagerBase
      def current; end

      def attach(context); end

      def detach(token); end
    end
  end
end
