# frozen_string_literal: true

module Zip
  module IOExtras # :nodoc:
    # Implements many of the output convenience methods of IO.
    # relies on <<
    module AbstractOutputStream # :nodoc:
      include FakeIO

      def write(data)
        self << data
        data.to_s.bytesize
      end

      def print(*params)
        self << params.join

        # Deflate doesn't like `nil`s or empty strings!
        unless $OUTPUT_RECORD_SEPARATOR.nil? || $OUTPUT_RECORD_SEPARATOR.empty?
          self << $OUTPUT_RECORD_SEPARATOR
        end

        nil
      end

      def printf(a_format_string, *params)
        self << format(a_format_string, *params)
        nil
      end

      def putc(an_object)
        self << case an_object
                when Integer
                  an_object.chr
                when String
                  an_object
                else
                  raise TypeError, 'putc: Only Integer and String supported'
                end
        an_object
      end

      def puts(*params)
        params << "\n" if params.empty?
        params.flatten.each do |element|
          val = element.to_s
          self << val
          self << "\n" unless val[-1, 1] == "\n"
        end
      end
    end
  end
end
