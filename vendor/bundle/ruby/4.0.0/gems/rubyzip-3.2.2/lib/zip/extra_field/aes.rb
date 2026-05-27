# frozen_string_literal: true

module Zip
  # Info-ZIP Extra for AES encryption
  class ExtraField::AES < ExtraField::Generic # :nodoc:
    attr_reader :vendor_version, :vendor_id, :encryption_strength, :compression_method

    HEADER_ID = [0x9901].pack('v')
    register_map

    def initialize(binstr = nil)
      @vendor_version = nil
      @vendor_id = nil
      @encryption_strength = nil
      @compression_method = nil
      binstr && merge(binstr)
    end

    def ==(other)
      @vendor_version == other.vendor_version &&
        @vendor_id == other.vendor_id &&
        @encryption_strength == other.encryption_strength &&
        @compression_method == other.compression_method
    end

    def merge(binstr)
      return if binstr.empty?

      size, content = initial_parse(binstr)
      (size && content) || return

      @vendor_version, @vendor_id,
        @encryption_strength, @compression_method = content.unpack('va2Cv')
    end

    # We can never suppress the AES extra field as it is needed to read the file.
    def suppress?
      false
    end

    def pack_for_local
      [@vendor_version, @vendor_id,
       @encryption_strength, @compression_method].pack('va2Cv')
    end

    def pack_for_c_dir
      pack_for_local
    end
  end
end
