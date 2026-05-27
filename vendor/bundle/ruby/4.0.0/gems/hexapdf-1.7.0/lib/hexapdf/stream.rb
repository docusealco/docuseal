# -*- encoding: utf-8; frozen_string_literal: true -*-
#
#--
# This file is part of HexaPDF.
#
# HexaPDF - A Versatile PDF Creation and Manipulation Library For Ruby
# Copyright (C) 2014-2025 Thomas Leitner
#
# HexaPDF is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License version 3 as
# published by the Free Software Foundation with the addition of the
# following permission added to Section 15 as permitted in Section 7(a):
# FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
# THOMAS LEITNER, THOMAS LEITNER DISCLAIMS THE WARRANTY OF NON
# INFRINGEMENT OF THIRD PARTY RIGHTS.
#
# HexaPDF is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public
# License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with HexaPDF. If not, see <http://www.gnu.org/licenses/>.
#
# The interactive user interfaces in modified source and object code
# versions of HexaPDF must display Appropriate Legal Notices, as required
# under Section 5 of the GNU Affero General Public License version 3.
#
# In accordance with Section 7(b) of the GNU Affero General Public
# License, a covered work must retain the producer line in every PDF that
# is created or manipulated using HexaPDF.
#
# If the GNU Affero General Public License doesn't fit your need,
# commercial licenses are available at <https://gettalong.at/hexapdf/>.
#++

require 'hexapdf/error'
require 'hexapdf/dictionary'
require 'hexapdf/filter'

module HexaPDF

  # Container for stream data that is more complex than a string.
  #
  # This helper class wraps all information necessary to read stream data by using a Fiber object
  # (see HexaPDF::Filter). The underlying data either comes from an IO object, a file represented by
  # its file name or a Fiber defined via a Proc object.
  #
  # Additionally, the #filter and #decode_parms can be set to indicate that the data returned from
  # the Fiber needs to be post-processed. The +filter+ and +decode_parms+ are automatically
  # normalized to arrays on assignment to ease further processing.
  class StreamData

    # The source.
    attr_reader :source

    # The filter(s) that need to be applied for getting the decoded stream data.
    attr_reader :filter

    # The decoding parameters associated with the +filter+(s).
    attr_reader :decode_parms

    # :call-seq:
    #   StreamData.new(io)          -> stream_data
    #   StreamData.new(str)         -> stream_data
    #   StreamData.new(proc)        -> stream_data
    #   StreamData.new { block }    -> stream_data
    #
    # Creates a new StreamData object for the given +source+ and with the given options.
    #
    # The +source+ can be:
    #
    # * An IO stream which is read starting from a specific +offset+ for a specific +length+
    #
    # * A string which is interpreted as a file name and read starting from a specific +offset+
    # * and for a specific +length+
    #
    # * A Proc object (that is converted to a Fiber when needed) in which case the +offset+ and
    #   value is ignored. The Proc object can also be passed by using a block.
    def initialize(source = nil, offset: nil, length: nil, filter: nil, decode_parms: nil, &block)
      if source.nil? && !block_given?
        raise ArgumentError, "Either a source object or a block must be given"
      end
      @source = source || block
      @offset = offset
      @length = length
      @filter = [filter].flatten.compact
      @decode_parms = [decode_parms].flatten
      freeze
    end

    # Returns a Fiber for getting at the data of the stream represented by this object.
    def fiber(chunk_size = 0)
      if @source.kind_of?(FiberDoubleForString)
        @source.dup
      elsif @source.kind_of?(Proc)
        FiberWithLength.new(@length, &@source)
      elsif @source.kind_of?(String)
        HexaPDF::Filter.source_from_file(@source, pos: @offset || 0, length: @length || -1,
                                         chunk_size: chunk_size)
      else
        HexaPDF::Filter.source_from_io(@source, pos: @offset || 0, length: @length || -1,
                                       chunk_size: chunk_size)
      end
    end

    # Returns whether this stream data object is equal to the other stream data object.
    def ==(other)
      other.kind_of?(StreamData) &&
        source == other.source && offset == other.offset && length == other.length &&
        filter == other.filter && decode_parms == other.decode_parms
    end

    protected

    # The optional offset into the bytes provided by source.
    attr_reader :offset

    # The optional number of bytes to use starting from offset.
    attr_reader :length

  end

  # Implements Stream objects of the PDF object system.
  #
  # == Stream Objects
  #
  # A stream may also be associated with a PDF object but only if the value is a PDF dictionary.
  # This associated dictionary further describes the stream, like its length or how it is encoded.
  #
  # Such a stream object in PDF contains string data but of possibly unlimited length. Therefore
  # it is used for large amounts of data like images, page descriptions or embedded files.
  #
  # The basic Object class cannot hold stream data, only this subclass contains the necessary
  # methods to conveniently work with the stream data!
  #
  # Note that support for external streams (/F, /FFilter, /FDecodeParms) is not yet implemented!
  #
  # See: PDF2.0 s7.3.8, Dictionary
  class Stream < Dictionary

    define_field :Length,       type: Integer # not required, will be auto-filled when writing
    define_field :Filter,       type: [Symbol, PDFArray]
    define_field :DecodeParms,  type: [Dictionary, PDFArray]
    define_field :F,            type: :Filespec, version: '1.2'
    define_field :FFilter,      type: [Symbol, PDFArray], version: '1.2'
    define_field :FDecodeParms, type: [Dictionary, PDFArray], version: '1.2'
    define_field :DL,           type: Integer

    # Stream objects must always be indirect.
    def must_be_indirect?
      true
    end

    # Assigns a new stream data object.
    #
    # The +stream+ argument can be a HexaPDF::StreamData object, a String object or +nil+.
    #
    # If +stream+ is +nil+, an empty binary string is used instead.
    def stream=(stream)
      data.stream = stream
      after_data_change
    end

    # Returns the (possibly decoded) stream data as string.
    #
    # Note that modifications done to the returned string are not reflected in the Stream object
    # itself. The modified string must explicitly be assigned via #stream= to take effect.
    def stream
      if data.stream.kind_of?(String)
        data.stream.dup
      else
        HexaPDF::Filter.string_from_source(stream_decoder)
      end
    end

    # Returns the raw stream object.
    #
    # The returned value can be of many different types (see #stream=). For working with the
    # decoded stream contents use #stream.
    def raw_stream
      data.stream
    end

    # Returns the Fiber representing the unprocessed content of the stream.
    def stream_source
      if data.stream.kind_of?(String)
        HexaPDF::Filter.source_from_string(data.stream)
      else
        data.stream.fiber(config['io.chunk_size'])
      end
    end

    # Returns the decoder Fiber for the stream data.
    #
    # See the Filter module for more information on how to work with the fiber.
    def stream_decoder
      source = stream_source

      if data.stream.kind_of?(StreamData)
        data.stream.filter.zip(data.stream.decode_parms) do |filter, decode_parms|
          source = filter_for_name(filter).decoder(source, decode_parms)
        end
      end

      source
    end

    # :call-seq:
    #   stream.stream_encoder
    #
    # Returns the encoder Fiber for the stream data.
    #
    # See the Filter module for more information on how to work with the fiber.
    def stream_encoder(source = stream_source)
      encoder_data = [document.unwrap(self[:Filter])].flatten.
        zip([document.unwrap(self[:DecodeParms])].flatten).
        delete_if {|f, _| f.nil? }

      if data.stream.kind_of?(StreamData)
        decoder_data = data.stream.filter.zip(data.stream.decode_parms)

        while !decoder_data.empty? && !encoder_data.empty? && decoder_data.last == encoder_data.last
          decoder_data.pop
          encoder_data.pop
        end

        decoder_data.each do |filter, decode_parms|
          source = filter_for_name(filter).decoder(source, decode_parms)
        end
      end

      encoder_data.reverse!.each do |filter, decode_parms|
        source = filter_for_name(filter).encoder(source, decode_parms)
      end

      source
    end

    # Sets the filters that should be used for encoding the stream.
    #
    # The arguments +filter+ as well as +decode_parms+ can either be a single items or arrays.
    #
    # The filters have to be specified in the *decoding order*! For example, if the filters would
    # be [:A85, :Fl], the stream would first be encoded with the Flate and then with the ASCII85
    # filter.
    def set_filter(filter, decode_parms = nil)
      if filter.nil? || (filter.kind_of?(Array) && filter.empty?)
        delete(:Filter)
      else
        self[:Filter] = filter
      end
      if decode_parms.nil? || (decode_parms.kind_of?(Array) && decode_parms.empty?) ||
          !key?(:Filter)
        delete(:DecodeParms)
      else
        self[:DecodeParms] = decode_parms
      end
    end

    private

    # Makes sure that the stream data is either a String or a HexaPDF::StreamData object.
    def after_data_change
      super
      data.stream ||= ''.b
      unless data.stream.kind_of?(StreamData) || data.stream.kind_of?(String)
        raise ArgumentError, "Object of class #{data.stream.class} cannot be used as stream value"
      end
    end

    # Returns the filter object that corresponds to the given filter name.
    #
    # See: HexaPDF::Filter
    def filter_for_name(filter_name)
      config.constantize('filter.map', filter_name) do
        raise HexaPDF::Error, "Unknown stream filter '#{filter_name}' encountered"
      end
    end

    # A mapping from short name to long name for filters.
    FILTER_MAP = {AHx: :ASCIIHexDecode, A85: :ASCII85Decode, LZW: :LZWDecode, # :nodoc:
                  Fl: :FlateDecode, RL: :RunLengthDecode, CCF: :CCITTFaxDecode,
                  DCT: :DCTDecode}.freeze

    # Validates the /Filter entry so that it contains only long-name filter names.
    def perform_validation
      super
      if value[:Filter].kind_of?(Symbol) && FILTER_MAP.key?(value[:Filter])
        yield("A stream's /Filter entry may only use long-form filter names", true)
        value[:Filter] = FILTER_MAP[value[:Filter]]
      elsif value[:Filter].kind_of?(Array)
        value[:Filter].map! do |filter|
          next filter unless FILTER_MAP.key?(filter)
          yield("A stream's /Filter entry may only use long-form filter names", true)
          FILTER_MAP[filter]
        end
      end
    end

  end

end
