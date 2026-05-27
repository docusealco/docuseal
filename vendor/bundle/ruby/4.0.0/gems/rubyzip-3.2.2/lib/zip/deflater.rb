# frozen_string_literal: true

module Zip
  class Deflater < Compressor # :nodoc:all
    def initialize(output_stream, level = Zip.default_compression, encrypter = NullEncrypter.new)
      super()
      @output_stream = output_stream
      @zlib_deflater = ::Zlib::Deflate.new(level, -::Zlib::MAX_WBITS)
      @size          = 0
      @crc           = ::Zlib.crc32
      @encrypter     = encrypter
    end

    def <<(data)
      val   = data.to_s
      @crc  = Zlib.crc32(val, @crc)
      @size += val.bytesize

      # When JRuby#3962 is fixed, we can remove the flushing parameter here.
      buffer = @zlib_deflater.deflate(data, Zip::ZLIB_FLUSHING_STRATEGY)
      return @output_stream if buffer.empty?

      @output_stream << @encrypter.encrypt(buffer)
    end

    def finish
      buffer = @zlib_deflater.finish
      @output_stream << @encrypter.encrypt(buffer) unless buffer.empty?
      @zlib_deflater.close
    end

    attr_reader :size, :crc
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
