# frozen_string_literal: true

module Zip
  class DecryptedIo # :nodoc:all
    CHUNK_SIZE = 32_768

    def initialize(io, decrypter, compressed_size)
      @io = io
      @decrypter = decrypter
      @bytes_remaining = compressed_size
      @buffer = +''
    end

    def read(length = nil, outbuf = +'')
      return (length.nil? || length.zero? ? '' : nil) if eof?

      while length.nil? || (@buffer.bytesize < length)
        break if input_finished?

        @buffer << produce_input
      end

      @decrypter.check_integrity!(@io) if input_finished?

      outbuf.replace(@buffer.slice!(0...(length || @buffer.bytesize)))
    end

    private

    def eof?
      @buffer.empty? && input_finished?
    end

    def input_finished?
      !@bytes_remaining.positive?
    end

    def produce_input
      chunk_size = [@bytes_remaining, CHUNK_SIZE].min
      return '' unless chunk_size.positive?

      @bytes_remaining -= chunk_size
      @decrypter.decrypt(@io.read(chunk_size))
    end
  end
end
