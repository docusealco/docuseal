# frozen_string_literal: true

module RQRCodeCore
  class QR8bitByte
    def initialize(data)
      @data = data
    end

    def write(buffer)
      buffer.byte_encoding_start(@data.bytesize)

      @data.each_byte do |b|
        buffer.put(b, 8)
      end
    end
  end
end
