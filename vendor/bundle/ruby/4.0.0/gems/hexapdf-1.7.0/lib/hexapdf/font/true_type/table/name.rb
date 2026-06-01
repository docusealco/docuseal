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

require 'hexapdf/font/true_type/table'

module HexaPDF
  module Font
    module TrueType
      class Table

        # The 'name' table contains the human-readable names for features, font names, style names,
        # copyright notices and so on.
        #
        # See: https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6name.html
        class Name < Table

          # Table for mapping symbolic names to name_id codes.
          NAME_MAP = {
            copyright: 0,
            font_family: 1,
            font_subfamily: 2,
            unique_subfamily: 3,
            font_name: 4,
            version: 5,
            postscript_name: 6,
            trademark: 7,
            manufacturer: 8,
            designer: 9,
            description: 10,
            vendor_url: 11,
            designer_url: 12,
            license: 13,
            license_url: 14,
            preferred_family: 16,
            preferred_subfamily: 17,
            compatible_full: 18,
            sample_text: 19,
            postscript_cid_name: 20,
            wws_family: 21,
            wws_subfamily: 22,
          }.freeze

          # Contains the information for a Name Record.
          #
          # The string value is converted to UTF-8 if possible, otherwise it stays in BINARY.
          class Record < String

            # Indicates Unicode version.
            PLATFORM_UNICODE = 0

            # QuickDraw Script Manager code for Macintosh.
            PLATFORM_MACINTOSH = 1

            # Microsoft encoding.
            PLATFORM_MICROSOFT = 3

            # The platform identifier code.
            attr_reader :platform_id

            # The platform specific encoding identified.
            attr_reader :encoding_id

            # The language identified.
            attr_reader :language_id

            # Create a new name record.
            def initialize(text, pid, eid, lid)
              @platform_id = pid
              @encoding_id = eid
              @language_id = lid

              if platform?(:unicode) ||
                  (platform?(:microsoft) && encoding_id == 1 || encoding_id == 10)
                text.encode!(::Encoding::UTF_8, ::Encoding::UTF_16BE)
              elsif platform?(:macintosh) && encoding_id == 0
                text.encode!(::Encoding::UTF_8, ::Encoding::MACROMAN)
              end

              super(text)
            end

            # Returns +true+ if this record has the given platform identifier which can either be
            # :unicode, :macintosh or :microsoft.
            def platform?(identifier)
              platform_id == case identifier
                             when :unicode then PLATFORM_UNICODE
                             when :macintosh then PLATFORM_MACINTOSH
                             when :microsoft then PLATFORM_MICROSOFT
                             else
                               raise ArgumentError, "Unknown platform identifier: #{identifier}"
                             end
            end

            # Returns +true+ if this record is a "preferred" one.
            #
            # The label "preferred" is set on a name if it represents the US English version of the
            # name in a decodable encoding:
            # * platform_id :macintosh, encoding_id 0 (Roman) and language_id 0 (English); or
            # * platform_id :microsoft, encoding_id 1 (Unicode) and language_id 1033 (US English).
            def preferred?
              (platform_id == PLATFORM_MACINTOSH && encoding_id == 0 && language_id == 0) ||
                (platform_id == PLATFORM_MICROSOFT && encoding_id == 1 && language_id == 1033)
            end

          end

          # Holds records for the same name type (e.g. :font_name, :postscript_name, ...).
          class Records < Array

            # Returns the preferred record in this collection.
            #
            # This is either the first record where Record#preferred? is true or else just the first
            # record in the collection.
            def preferred_record
              find(&:preferred?) || self[0]
            end

          end

          # The format of the table.
          attr_accessor :format

          # The name records.
          attr_accessor :records

          # The mapping of language IDs starting from 0x8000 to language tags conforming to IETF BCP
          # 47.
          attr_accessor :language_tags

          # Returns an array with all available entries for the given name identifier (either a
          # symbol or an ID).
          #
          # See: NAME_MAP
          def [](name_or_id)
            @records[name_or_id.kind_of?(Symbol) ? NAME_MAP[name_or_id] : name_or_id]
          end

          private

          def parse_table #:nodoc:
            @format, count, string_offset = read_formatted(6, 'n3')
            string_offset += directory_entry.offset

            @records = Hash.new {|h, k| h[k] = Records.new }
            @language_tags = {}

            record_rows = Array.new(count) { read_formatted(12, 'n6') }
            if @format == 1
              count = read_formatted(2, 'n').first
              language_rows = Array.new(count) { read_formatted(4, 'n2') }
            end

            record_rows.each do |pid, eid, lid, nid, length, offset|
              io.pos = string_offset + offset
              @records[nid] << Record.new(io.read(length), pid, eid, lid)
            end

            if @format == 1
              language_rows.each_with_index do |(length, offset), index|
                io.pos = string_offset + offset
                @language_tags[0x8000 + index] =
                  io.read(length).encode!(::Encoding::UTF_8, ::Encoding::UTF_16BE)
              end
            end
          end

        end

      end
    end
  end
end
