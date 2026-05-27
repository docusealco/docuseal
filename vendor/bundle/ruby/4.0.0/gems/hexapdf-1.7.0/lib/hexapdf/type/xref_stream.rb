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
require 'hexapdf/stream'
require 'hexapdf/xref_section'
require 'hexapdf/type/trailer'

module HexaPDF
  module Type

    # Represents PDF type XRef, cross-reference streams.
    #
    # A cross-reference stream is used as a more compact representation for an cross-reference
    # section and trailer dictionary. The trailer dictionary is incorporated into the stream
    # dictionary and the cross-reference section entries are stored in the stream itself,
    # compressed to save space.
    #
    # == How are Cross-reference Streams Used?
    #
    # Cross-reference stream objects are only used when parsing or writing a PDF document.
    #
    # When a file is read and a cross-reference stream is found, it is loaded and its information is
    # stored in a HexaPDF::Revision object. So from a user's perspective nothing changes when a
    # cross-reference stream instead of a cross-reference section and trailer is encountered.
    #
    # This also means that all information stored in a cross-reference stream between parsing and
    # writing is discarded when the PDF document gets written!
    #
    # Upon writing a revision it is checked whether that revision contains a cross-reference
    # stream object. If it does the cross-reference stream object is updated with the
    # cross-reference section and trailer information and then written. Otherwise a normal
    # cross-reference section plus trailer are written.
    #
    # See: PDF2.0 s7.5.8
    class XRefStream < HexaPDF::Stream

      define_type :XRef

      define_field :Type,  type: Symbol, default: type, required: true, indirect: false,
                           version: '1.5'
      define_field :Size,  type: Integer, indirect: false, required: true
      define_field :Index, type: PDFArray, indirect: false
      define_field :Prev,  type: Integer, indirect: false
      define_field :W,     type: PDFArray, indirect: false, required: true

      # Returns an XRefSection that represents the content of this cross-reference stream.
      #
      # Each invocation returns a new XRefSection object based on the current data in the
      # associated stream and dictionary.
      def xref_section
        index = self[:Index] || [0, self[:Size]]
        parse_xref_section(index, self[:W])
      end

      # Returns a hash with the entries that represent the file trailer part of the
      # cross-reference stream's dictionary.
      #
      # See: Type::Trailer
      def trailer
        trailer = {Type: :XRef}
        Trailer.each_field.with_object(trailer) do |(name, _data), hash|
          hash[name] = value[name] if key?(name)
        end
      end

      # Makes this cross-reference stream represent the data in the given HexaPDF::XRefSection and
      # Type::Trailer.
      #
      # The +xref_section+ needs to contain an entry for this cross-reference stream and it is
      # necessary that this entry is the one with the highest byte position (for calculating the
      # correct /W entry).
      #
      # The given cross-reference section is *not* stored but only used to rewrite the associated
      # stream to reflect the cross-reference section. The dictionary is updated with the
      # information from the trailer and the needed entries for the cross-reference section.
      #
      # If there are changes to the cross-reference section or trailer, this method has to be
      # invoked again.
      def update_with_xref_section_and_trailer(xref_section, trailer)
        value.replace(trailer)
        value[:Type] = :XRef
        write_xref_section_to_stream(xref_section)
        set_filter(:FlateDecode, Columns: value[:W].inject(:+), Predictor: 12)
      end

      private

      TYPE_FREE       = 0 #:nodoc:
      TYPE_IN_USE     = 1 #:nodoc:
      TYPE_COMPRESSED = 2 #:nodoc:

      # Parses the stream and returns the resulting HexaPDF::XRefSection object.
      def parse_xref_section(index, w)
        xref = XRefSection.new

        data = stream
        start_pos = end_pos = 0

        w0 = w[0]
        w1 = w[1]
        w2 = w[2]

        needed_bytes = (w0 + w1 + w2) * index.each_slice(2).sum(&:last)

        if needed_bytes > data.size
          raise HexaPDF::MalformedPDFError, "Cross-reference stream is missing data " \
            "(#{needed_bytes} bytes needed, got #{data.size})"
        end

        index.each_slice(2) do |first_oid, number_of_entries|
          first_oid.upto(first_oid + number_of_entries - 1) do |oid|
            # Default for first field: type 1
            end_pos = start_pos + w0
            type_field = (w0 == 0 ? TYPE_IN_USE : bytes_to_int(data, start_pos, end_pos))
            # No default available for second field
            start_pos = end_pos + w1
            field2 = bytes_to_int(data, end_pos, start_pos)
            # Default for third field is 0 for type 1, otherwise it needs to be specified!
            end_pos = start_pos + w2
            field3 = (w2 == 0 ? 0 : bytes_to_int(data, start_pos, end_pos))

            case type_field
            when TYPE_IN_USE
              xref.add_in_use_entry(oid, field3, field2)
            when TYPE_FREE
              xref.add_free_entry(oid, field3)
            when TYPE_COMPRESSED
              xref.add_compressed_entry(oid, field2, field3)
            else
              nil # Ignore entry as per PDF2.0 s7.5.8.3
            end
            start_pos = end_pos
          end
        end

        xref
      end

      # Converts the bytes of the string from the start index to the end index to an integer.
      #
      # The bytes are converted in the big-endian way.
      def bytes_to_int(string, start_index, end_index)
        result = string.getbyte(start_index)
        start_index += 1
        while start_index < end_index
          result = (result << 8) | string.getbyte(start_index)
          start_index += 1
        end
        result
      end

      # Writes the given cross-reference section to the stream and sets the correct /W and /Index
      # entries for the written data.
      def write_xref_section_to_stream(xref_section)
        value[:W], pack_string = calculate_w_entry_and_pack_string(xref_section[oid, gen].pos)
        value[:Index] = []

        stream = ''.b
        xref_section.each_subsection do |entries|
          value[:Index] << entries.first.oid << entries.length
          entries.each do |entry|
            data = if entry.in_use?
                     [TYPE_IN_USE, entry.pos, entry.gen]
                   elsif entry.free?
                     [TYPE_FREE, 0, 65535]
                   elsif entry.compressed?
                     [TYPE_COMPRESSED, entry.objstm, entry.pos]
                   else
                     raise HexaPDF::Error, "Unsupported cross-reference entry #{entry}"
                   end
            stream << data.pack(pack_string)
          end
        end
        self.stream = stream
      end

      # Returns the /W entry depending on the given maximal number for the second field as well as
      # the appropriate entry packing string.
      def calculate_w_entry_and_pack_string(max_number)
        middle = Math.log(max_number, 255).ceil
        middle = 4 if middle == 3
        pack_string = "C#{'-CnNN'[middle]}n"
        [[1, middle, 2], pack_string]
      end

      def perform_validation #:nodoc
        # Size is not required because it will be auto-filled before the object is written
        # W is not required because it will be auto-filled on #update_with_xref_section_and_trailer
        # Set both here to dummy values to make validation work for the required values
        self[:Size] ||= 1
        self[:W] ||= [1, 1, 1]
        super
      end

    end

  end
end
