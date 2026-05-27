# frozen_string_literal: true

require_relative 'cbor/encoder'
require_relative 'cbor/decoder'

module Aws
  # @api private
  module Cbor

    # CBOR Tagged data (Major type 6).
    # A Tag consists of a tag number and a value.
    # In the extended generic data model, a tag number's definition
    # describes the additional semantics conveyed with the tag number.
    # # @!method initialize(*args)
    #   @option args [Integer] :tag The tag number.
    #   @option args [Object] :value The tag's content.
    # @!attribute tag
    #   The tag number.
    #   @return [Integer]
    # @!attribute value
    #   The tag's content.
    #   @return [Object]
    Tagged = Struct.new(:tag, :value)

    class Error < StandardError; end

    class OutOfBytesError < Error
      def initialize(n, left)
        super("Out of bytes. Trying to read #{n} bytes but buffer contains only #{left}")
      end
    end

    class UnknownTypeError < Error
      def initialize(type)
        super("Unable to encode #{type}")
      end
    end

    class ExtraBytesError < Error
      def initialize(pos, size)
        super("Extra bytes follow after decoding item. Read #{pos} / #{size} bytes")
      end
    end

    class UnexpectedBreakCodeError < Error; end

    class UnexpectedAdditionalInformationError < Error
      def initialize(add_info)
        super("Unexpected additional information: #{add_info}")
      end
    end
  end
end
