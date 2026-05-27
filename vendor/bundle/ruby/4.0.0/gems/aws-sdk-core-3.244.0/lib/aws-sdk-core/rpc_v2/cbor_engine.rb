# frozen_string_literal: true

require_relative '../cbor'

module Aws
  module RpcV2
    # Pure Ruby implementation of CBOR encode and decode
    module CborEngine
      def self.encode(data)
        Cbor::Encoder.new.add(data).bytes
      end

      def self.decode(bytes)
        Cbor::Decoder.new(bytes.force_encoding(Encoding::BINARY)).decode
      end
    end
  end
end
