require 'digest'

module Digest
  #
  # Base class for all CRC algorithms.
  #
  class CRC < Digest::Class

    include Digest::Instance

    # The initial value of the CRC checksum
    INIT_CRC = 0x00

    # The XOR mask to apply to the resulting CRC checksum
    XOR_MASK = 0x00

    # The bit width of the CRC checksum
    WIDTH = 0

    # Define true or false whether the input direction is bit reversed or not of the CRC checksum
    REFLECT_INPUT = nil

    # Default place holder CRC table
    TABLE = [].freeze

    #
    # Calculates the CRC checksum.
    #
    # @param [String] data
    #   The given data.
    #
    # @return [Integer]
    #   The CRC checksum.
    #
    def self.checksum(data)
      crc = self.new
      crc << data

      return crc.checksum
    end

    #
    # Packs the given CRC checksum.
    #
    # @param [Integer] crc
    #   The raw CRC checksum.
    #
    # @return [String]
    #   The packed CRC checksum.
    #
    def self.pack(crc)
      unless (width = self::WIDTH) > 0
        raise(NotImplementedError, "#{self} is incompleted as CRC")
      end

      bitclass   = width + (-width & 0x07)
      byte_count = bitclass / 8

      crc &= ~(-1 << width)

      result = [crc].pack("Q>")
      result[0, result.bytesize - byte_count] = ""
      result
    end

    #
    # Determines whether the library is using the optimized C extensions
    # implementation, or the pure-Ruby implementation.
    #
    # @return [:c_ext, :pure]
    #
    # @since 0.7.0
    #
    def self.implementation
      if instance_method(:update).source_location.nil?
        :c_ext
      else
        :pure
      end
    end

    #
    # Initializes the CRC checksum.
    #
    def initialize
      @init_crc      = self.class.const_get(:INIT_CRC)
      @xor_mask      = self.class.const_get(:XOR_MASK)
      @width         = self.class.const_get(:WIDTH)
      @reflect_input = self.class.const_get(:REFLECT_INPUT)
      @table         = self.class.const_get(:TABLE)

      reset
    end

    #
    # The input block length.
    #
    # @return [1]
    #
    def block_length
      1
    end

    #
    # The length of the digest.
    #
    # @return [Integer]
    #   The length in bytes.
    #
    def digest_length
      (@width / 8.0).ceil
    end

    #
    # Updates the CRC checksum with the given data.
    #
    # @param [String] data
    #   The data to update the CRC checksum with.
    #
    # @raise [NotImplementedError]
    #   If WIDTH, TABLE, or REFLECT_INPUT constants are not set properly.
    #
    def update(data)
      unless @width >= 1
        raise(NotImplementedError, "incompleted #{self.class} as CRC (expected WIDTH to be 1 or more)")
      end

      if @table.empty?
        raise(NotImplementedError, "incompleted #{self.class} as CRC (expected TABLE to be not empty)")
      end

      if @reflect_input.nil?
        raise(NotImplementedError, "incompleted #{self.class} as CRC (expected REFLECT_INPUT to be not nil)")
      end

      table = @table
      crc   = @crc

      if @reflect_input
        if @width > 8
          data.each_byte do |b|
            crc = table[b ^ (0xff & crc)] ^ (crc >> 8)
          end
        else
          data.each_byte do |b|
            # Omit (crc >> 8) since bits upper than the lower 8 bits are always 0
            crc = table[b ^ (0xff & crc)]
          end
        end
      else
        if @width > 8
          higher_bit_off = @width - 8
          remain_mask    = ~(-1 << higher_bit_off)

          data.each_byte do |b|
            crc = table[b ^ (0xff & (crc >> higher_bit_off))] ^ ((remain_mask & crc) << 8)
          end
        else
          padding = 8 - @width

          data.each_byte do |b|
            # Omit (crc << 8) since bits lower than the upper 8 bits are always 0
            crc = table[b ^ (0xff & (crc << padding))]
          end
        end
      end

      @crc = crc

      self
    end

    #
    # @see #update
    #
    def <<(data)
      update(data)
      return self
    end

    #
    # Resets the CRC checksum.
    #
    # @return [Integer]
    #   The default value of the CRC checksum.
    #
    def reset
      @crc = @init_crc
    end

    #
    # The resulting CRC checksum.
    #
    # @return [Integer]
    #   The resulting CRC checksum.
    #
    def checksum
      @crc ^ @xor_mask
    end

    #
    # Finishes the CRC checksum calculation.
    #
    # @see pack
    #
    def finish
      self.class.pack(checksum)
    end

  end
end
