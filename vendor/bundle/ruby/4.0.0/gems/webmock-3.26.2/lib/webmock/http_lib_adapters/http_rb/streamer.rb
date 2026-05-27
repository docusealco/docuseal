# frozen_string_literal: true

module HTTP
  class Response
    class Streamer
      def initialize(str, encoding: Encoding::BINARY)
        @io = StringIO.new str
        @encoding = encoding
      end

      def readpartial(size = nil, outbuf = nil)
        unless size
          if defined?(HTTP::Connection::BUFFER_SIZE)
            size = HTTP::Connection::BUFFER_SIZE
          elsif defined?(HTTP::Client::BUFFER_SIZE)
            size = HTTP::Client::BUFFER_SIZE
          end
        end

        chunk = @io.read(size, outbuf)

        # HTTP.rb 6.0+ expects EOFError at end-of-stream instead of nil
        if chunk.nil?
          raise EOFError if HTTP::VERSION >= "6.0.0"
          return nil
        end

        chunk.force_encoding(@encoding)
      end

      def close
        @io.close
      end

      def finished_request?
        @io.eof?
      end

      def sequence_id
        -1
      end
    end
  end
end
