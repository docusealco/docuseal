# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'base64'

module TwitterCldr
  module Segmentation
    class StateTable
      PACK_FMT_16 = 's!*'.freeze
      BOF_REQUIRED_FLAG = 2

      class << self
        def load16(hash)
          new(
            Base64.decode64(hash[:table]).unpack(PACK_FMT_16),
            hash[:flags]
          )
        end
      end

      attr_reader :values, :flags

      def initialize(values, flags)
        @values = values
        @flags = flags
      end

      def [](idx)
        values[idx]
      end

      def bof_required?
        flags & BOF_REQUIRED_FLAG != 0
      end

      def dump16
        {
          table: Base64.encode64(values.pack(PACK_FMT_16)).strip,
          flags: flags
        }
      end
    end
  end
end
