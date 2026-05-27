# frozen_string_literal: true

require 'bigdecimal'

module Aws
  module Cbor
    # Pure ruby implementation of CBOR encoder.
    class Encoder
      def initialize
        @buffer = String.new
      end

      # @return the encoded bytes in CBOR format for all added data
      def bytes
        @buffer
      end

      # generic method for adding generic Ruby data based on its type
      def add(value)
        case value
        when BigDecimal then add_big_decimal(value)
        when Integer then add_auto_integer(value)
        when Numeric then add_auto_float(value)
        when Symbol then add_string(value.to_s)
        when true, false then add_boolean(value)
        when nil then add_nil
        when Tagged
          add_tag(value.tag)
          add(value.value)
        when String
          if value.encoding == Encoding::BINARY
            add_byte_string(value)
          else
            add_string(value)
          end
        when Array
          start_array(value.size)
          value.each { |di| add(di) }
        when Hash
          start_map(value.size)
          value.each do |k, v|
            add(k)
            add(v)
          end
        when Time
          add_time(value)
        else
          raise UnknownTypeError, value
        end
        self
      end

      private

      MAJOR_TYPE_UNSIGNED_INT = 0x00 # 000_00000 - Major Type 0 - unsigned int
      MAJOR_TYPE_NEGATIVE_INT = 0x20 # 001_00000 - Major Type 1 - negative int
      MAJOR_TYPE_BYTE_STR = 0x40 # 010_00000 - Major Type 2 (Byte String)
      MAJOR_TYPE_STR = 0x60 # 011_00000 - Major Type 3 (Text String)
      MAJOR_TYPE_ARRAY = 0x80 # 100_00000 - Major Type 4 (Array)
      MAJOR_TYPE_MAP = 0xa0 # 101_00000 - Major Type 5 (Map)
      MAJOR_TYPE_TAG = 0xc0 # 110_00000 - Major type 6 (Tag)
      MAJOR_TYPE_SIMPLE = 0xe0 # 111_00000 - Major type 7 (111) + 5 bit 0

      FLOAT_BYTES = 0xfa # 111_11010 - Major type 7 (Float) + value: 26
      DOUBLE_BYTES = 0xfb # 111_ 11011 - Major type 7 (Float) + value: 26

      # https://www.rfc-editor.org/rfc/rfc8949.html#tags
      TAG_TYPE_EPOCH = 1
      TAG_BIGNUM_BASE = 2
      TAG_TYPE_BIGDEC = 4

      MAX_INTEGER = 18_446_744_073_709_551_616 # 2^64

      def head(major_type, value)
        @buffer <<
          case value
          when 0...24
            [major_type + value].pack('C') # 8-bit unsigned
          when 0...256
            [major_type + 24, value].pack('CC')
          when 0...65_536
            [major_type + 25, value].pack('Cn')
          when 0...4_294_967_296
            [major_type + 26, value].pack('CN')
          when 0...MAX_INTEGER
            [major_type + 27, value].pack('CQ>')
          else
            raise Error, "Value is too large to encode: #{value}"
          end
      end

      # streaming style, lower level interface
      def add_integer(value)
        major_type =
          if value.negative?
            value = -1 - value
            MAJOR_TYPE_NEGATIVE_INT
          else
            MAJOR_TYPE_UNSIGNED_INT
          end
        head(major_type, value)
      end

      def add_bignum(value)
        major_type =
          if value.negative?
            value = -1 - value
            MAJOR_TYPE_NEGATIVE_INT
          else
            MAJOR_TYPE_UNSIGNED_INT
          end
        s = bignum_to_bytes(value)
        head(MAJOR_TYPE_TAG, TAG_BIGNUM_BASE + (major_type >> 5))
        head(MAJOR_TYPE_BYTE_STR, s.bytesize)
        @buffer << s
      end

      # A decimal fraction or a bigfloat is represented as a tagged array
      # that contains exactly two integer numbers:
      # an exponent e and a mantissa m
      # decimal fractions are always represented with a base of 10
      # See: https://www.rfc-editor.org/rfc/rfc8949.html#name-decimal-fractions-and-bigfl
      def add_big_decimal(value)
        if value.infinite? == 1
          return add_float(value.infinite? * Float::INFINITY)
        elsif value.nan?
          return add_float(Float::NAN)
        end

        head(MAJOR_TYPE_TAG, TAG_TYPE_BIGDEC)
        sign, digits, base, exp = value.split
        # Ruby BigDecimal digits of XXX are used as 0.XXX, convert
        exp = exp - digits.size
        digits = sign * digits.to_i
        start_array(2)
        add_auto_integer(exp)
        add_auto_integer(digits)
      end

      def add_auto_integer(value)
        major_type =
          if value.negative?
            value = -1 - value
            MAJOR_TYPE_NEGATIVE_INT
          else
            MAJOR_TYPE_UNSIGNED_INT
          end

        if value >= MAX_INTEGER
          s = bignum_to_bytes(value)
          head(MAJOR_TYPE_TAG, TAG_BIGNUM_BASE + (major_type >> 5))
          head(MAJOR_TYPE_BYTE_STR, s.bytesize)
          @buffer << s
        else
          head(major_type, value)
        end
      end

      def add_float(value)
        @buffer << [FLOAT_BYTES, value].pack('Cg') # single-precision
      end

      def add_double(value)
        @buffer << [DOUBLE_BYTES, value].pack('CG') # double-precision
      end

      def add_auto_float(value)
        if value.nan?
          @buffer << FLOAT_BYTES << [value].pack('g')
        else
          ss = [value].pack('g') # single-precision
          if ss.unpack1('g') == value
            @buffer << FLOAT_BYTES << ss
          else
            @buffer << [DOUBLE_BYTES, value].pack('CG') # double-precision
          end
        end
      end

      def add_nil
        head(MAJOR_TYPE_SIMPLE, 22)
      end

      def add_boolean(value)
        value ? head(MAJOR_TYPE_SIMPLE, 21) : head(MAJOR_TYPE_SIMPLE, 20)
      end

      # Encoding MUST already be Encoding::BINARY
      def add_byte_string(value)
        head(MAJOR_TYPE_BYTE_STR, value.bytesize)
        @buffer << value
      end

      def add_string(value)
        value = value.encode(Encoding::UTF_8).force_encoding(Encoding::BINARY)
        head(MAJOR_TYPE_STR, value.bytesize)
        @buffer << value
      end

      # caller is responsible for adding length values
      def start_array(length)
        head(MAJOR_TYPE_ARRAY, length)
      end

      def start_indefinite_array
        head(MAJOR_TYPE_ARRAY + 31, 0)
      end

      # caller is responsible for adding length key/value pairs
      def start_map(length)
        head(MAJOR_TYPE_MAP, length)
      end

      def start_indefinite_map
        head(MAJOR_TYPE_MAP + 31, 0)
      end

      def end_indefinite_collection
        # write the stop sequence
        head(MAJOR_TYPE_SIMPLE + 31, 0)
      end

      def add_tag(tag)
        head(MAJOR_TYPE_TAG, tag)
      end

      def add_time(value)
        head(MAJOR_TYPE_TAG, TAG_TYPE_EPOCH)
        epoch = value.to_f
        add_double(epoch)
      end

      def bignum_to_bytes(value)
        s = String.new
        while value != 0
          s << (value & 0xFF)
          value >>= 8
        end
        s.reverse!
      end
    end
  end
end
