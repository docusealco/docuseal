# frozen_string_literal: true
module Temple
  module Generators
    # Implements a rails output buffer.
    #
    #   @output_buffer = ActiveSupport::SafeBuffer
    #   @output_buffer.safe_concat "static"
    #   @output_buffer.safe_concat dynamic.to_s
    #   @output_buffer
    #
    # @api public
    class RailsOutputBuffer < StringBuffer
      define_options :streaming, # ignored
                     buffer_class: 'ActionView::OutputBuffer',
                     buffer: '@output_buffer',
                     capture_generator: RailsOutputBuffer

      def call(exp)
        [preamble, compile(exp), postamble].flatten.compact.join('; '.freeze)
      end

      def create_buffer
        if buffer == '@output_buffer'
          "#{buffer} = output_buffer || #{options[:buffer_class]}.new"
        else
          "#{buffer} = #{options[:buffer_class]}.new"
        end
      end

      def concat(str)
        "#{buffer}.safe_concat((#{str}))"
      end
    end
  end
end
