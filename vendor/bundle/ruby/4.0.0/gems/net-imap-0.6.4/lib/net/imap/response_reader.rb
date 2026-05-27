# frozen_string_literal: true

module Net
  class IMAP
    # See https://www.rfc-editor.org/rfc/rfc9051#section-2.2.2
    class ResponseReader # :nodoc:
      attr_reader :client

      def initialize(client, sock)
        @client, @sock = client, sock
        # cached config
        @max_response_size = nil
        # response buffer state
        @buff = @literal_size = nil
      end

      def read_response_buffer
        @max_response_size = client.max_response_size
        @buff = String.new
        catch :eof do
          while true
            guard_response_too_large!
            read_line
            # check before allocating memory for literal
            guard_response_too_large!
            break unless literal_size
            read_literal
          end
        end
        buff
      ensure
        @buff = @literal_size = nil
      end

      private

      # cached config
      attr_reader :max_response_size

      # response buffer state
      attr_reader :buff, :literal_size

      def bytes_read          = buff.bytesize
      def empty?              = buff.empty?
      def done?               = line_done? && !literal_size
      def line_done?          = buff.end_with?(CRLF)

      def get_literal_size(buff)
        buff.end_with?("}\r\n") && buff.rindex(/\{(\d+)\}\r\n\z/n) && $1.to_i
      end

      def read_line
        line = (@sock.gets(CRLF, max_response_remaining) or throw :eof)
        @literal_size = get_literal_size(line)
        buff << line
      end

      def read_literal
        literal = String.new(capacity: literal_size)
        buff << (@sock.read(literal_size, literal) or throw :eof)
      ensure
        @literal_size = nil
      end

      def max_response_remaining = max_response_size &.- bytes_read
      def response_too_large?    = max_response_size &.< min_response_size
      def min_response_size      = bytes_read + min_response_remaining

      def min_response_remaining
        empty? ? 3 : done? ? 0 : (literal_size || 0) + 2
      end

      def guard_response_too_large!
        return unless response_too_large?
        raise ResponseTooLargeError.new(
          max_response_size:, bytes_read:, literal_size:,
        )
      end

    end
  end
end
