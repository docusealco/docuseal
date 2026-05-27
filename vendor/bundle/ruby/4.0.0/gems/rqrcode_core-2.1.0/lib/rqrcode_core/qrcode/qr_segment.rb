# frozen_string_literal: true

module RQRCodeCore
  class QRSegment
    attr_reader :data, :mode

    def initialize(data:, mode: nil)
      @data = data
      @mode = QRMODE_NAME.dig(mode&.to_sym)

      # If mode is not explicitly found choose mode according to data type
      @mode ||= if RQRCodeCore::QRNumeric.valid_data?(@data)
        QRMODE_NAME[:number]
      elsif QRAlphanumeric.valid_data?(@data)
        QRMODE_NAME[:alphanumeric]
      else
        QRMODE_NAME[:byte_8bit]
      end
    end

    def size(version)
      4 + header_size(version) + content_size
    end

    def header_size(version)
      QRUtil.get_length_in_bits(QRMODE[mode], version)
    end

    def content_size
      chunk_size, bit_length, extra = case mode
      when :mode_number
        [3, QRNumeric::NUMBER_LENGTH[3], QRNumeric::NUMBER_LENGTH[data_length % 3] || 0]
      when :mode_alpha_numk
        [2, 11, 6]
      when :mode_8bit_byte
        [1, 8, 0]
      end

      (data_length / chunk_size) * bit_length + (((data_length % chunk_size) == 0) ? 0 : extra)
    end

    def writer
      case mode
      when :mode_number
        QRNumeric.new(data)
      when :mode_alpha_numk
        QRAlphanumeric.new(data)
      when :mode_multi
        QRMulti.new(data)
      else
        QR8bitByte.new(data)
      end
    end

    private

    def data_length
      data.bytesize
    end
  end
end
