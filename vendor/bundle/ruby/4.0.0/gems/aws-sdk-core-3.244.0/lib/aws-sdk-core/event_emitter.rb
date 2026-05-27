# frozen_string_literal: true

module Aws
  class EventEmitter

    def initialize
      @listeners = {}
      @validate_event = true
      @signal_queue = Queue.new
    end

    attr_accessor :stream

    attr_accessor :encoder

    attr_accessor :validate_event

    attr_accessor :signal_queue

    def on(type, callback)
      (@listeners[type] ||= []) << callback
    end

    def signal(type, event)
      return unless @listeners[type]
      @listeners[type].each do |listener|
        listener.call(event) if event.event_type == type
      end
    end

    def emit(type, params)
      unless @stream
        raise Aws::Errors::SignalEventError.new(
          "Signaling events before making async request"\
          " is not allowed."
        )
      end
      if @validate_event && type != :end_stream
        Aws::ParamValidator.validate!(
          @encoder.rules.shape.member(type), params)
      end
      @stream.data(
        @encoder.encode(type, params),
        end_stream: type == :end_stream
      )
    end
  end
end
