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
require 'hexapdf/data_dir'

module HexaPDF
  module Font

    # Represents a CMap, a mapping from character codes to CIDs (character IDs) or to their Unicode
    # value.
    #
    # See: PDF2.0 s9.7.5, s9.10.3; Adobe Technical Notes #5014 and #5411
    class CMap

      autoload(:Parser, 'hexapdf/font/cmap/parser')
      autoload(:Writer, 'hexapdf/font/cmap/writer')

      CMAP_DIR = File.join(HexaPDF.data_dir, 'cmap') #:nodoc:

      @cmap_cache = {}

      # Returns +true+ if the given name specifies a predefined CMap.
      def self.predefined?(name)
        File.exist?(File.join(CMAP_DIR, name))
      end

      # Creates a new CMap object by parsing a predefined CMap with the given name.
      #
      # Raises an error if the given CMap is not found.
      def self.for_name(name)
        return @cmap_cache[name] if @cmap_cache.key?(name)

        file = File.join(CMAP_DIR, name)
        if File.exist?(file)
          @cmap_cache[name] = parse(File.read(file, encoding: ::Encoding::UTF_8))
        else
          raise HexaPDF::Error, "No CMap named '#{name}' found"
        end
      end

      # Creates a new CMap object from the given string which needs to contain a valid CMap file.
      def self.parse(string)
        Parser.new.parse(string)
      end

      # Returns a string containing a ToUnicode CMap that represents the given code to Unicode
      # codepoint mapping.
      #
      # See: Writer#create_to_unicode_cmap
      def self.create_to_unicode_cmap(mapping)
        Writer.new.create_to_unicode_cmap(mapping)
      end

      # Returns a string containing a CID CMap that represents the given code to CID mapping.
      #
      # See: Writer#create_cid_cmap
      def self.create_cid_cmap(mapping)
        Writer.new.create_cid_cmap(mapping)
      end

      # The registry part of the CMap version.
      attr_accessor :registry

      # The ordering part of the CMap version.
      attr_accessor :ordering

      # The supplement part of the CMap version.
      attr_accessor :supplement

      # The name of the CMap.
      attr_accessor :name

      # The writing mode of the CMap: 0 for horizontal, 1 for vertical writing.
      attr_accessor :wmode

      attr_reader :codespace_ranges, :cid_mapping, :cid_range_mappings, :unicode_mapping,
                  :unicode_range_mappings # :nodoc:
      protected :codespace_ranges, :cid_mapping, :cid_range_mappings, :unicode_mapping,
                :unicode_range_mappings

      # Creates a new CMap object.
      def initialize
        @codespace_ranges = []
        @cid_mapping = {}
        @cid_range_mappings = []
        @unicode_mapping = {}
        @unicode_range_mappings = []
      end

      # Add all mappings from the given CMap to this CMap.
      def use_cmap(cmap)
        @codespace_ranges.concat(cmap.codespace_ranges)
        @cid_mapping.merge!(cmap.cid_mapping)
        @cid_range_mappings.concat(cmap.cid_range_mappings)
        @unicode_mapping.merge!(cmap.unicode_mapping)
        @unicode_range_mappings.concat(cmap.unicode_range_mappings)
      end

      # Add a codespace range using an array of ranges for the individual bytes.
      #
      # This means that the first range is checked against the first byte, the second range against
      # the second byte and so on.
      def add_codespace_range(first, *rest)
        @codespace_ranges << [first, rest]
      end

      # Parses the string and returns all character codes.
      #
      # An error is raised if the string contains invalid bytes.
      def read_codes(string)
        codes = []
        bytes = string.bytes
        length = bytes.length
        i = 0

        while i < length
          byte = bytes[i]
          i += 1
          code = 0

          found = @codespace_ranges.any? do |first_byte_range, rest_ranges|
            next unless first_byte_range.cover?(byte)

            code = (code << 8) + byte
            valid = rest_ranges.all? do |range|
              if i < length
                byte = bytes[i]
                i += 1
              else
                raise HexaPDF::Error, "Missing bytes while reading codes via CMap"
              end
              code = (code << 8) + byte
              range.cover?(byte)
            end

            codes << code if valid
          end

          unless found
            raise HexaPDF::Error, "Invalid byte while reading codes via CMap: #{byte}"
          end
        end

        codes
      end

      # Adds an individual mapping from character code to CID.
      def add_cid_mapping(code, cid)
        @cid_mapping[code] = cid
      end

      # Adds a CID range, mapping characters codes from +start_code+ to +end_code+ to CIDs starting
      # with +start_cid+.
      def add_cid_range(start_code, end_code, start_cid)
        @cid_range_mappings << [start_code..end_code, start_cid]
      end

      # Returns the CID for the given character code, or 0 if no mapping was found.
      def to_cid(code)
        cid = @cid_mapping.fetch(code, -1)
        if cid == -1
          @cid_range_mappings.reverse_each do |range, start_cid|
            if range.cover?(code)
              cid = start_cid + code - range.first
              break
            end
          end
        end
        (cid == -1 ? 0 : cid)
      end

      # Adds a mapping from character code to Unicode string in UTF-8 encoding.
      def add_unicode_mapping(code, string)
        @unicode_mapping[code] = string
      end

      # Adds a mapping from a range of character codes to strings starting with the given 16-bit
      # integer values (representing the raw UTF-16BE characters).
      def add_unicode_range_mapping(start_code, end_code, start_values)
        @unicode_range_mappings << [start_code..end_code, start_values]
      end

      # Returns the Unicode string in UTF-8 encoding for the given character code, or +nil+ if no
      # mapping was found.
      def to_unicode(code)
        @unicode_mapping.fetch(code) do
          @unicode_range_mappings.reverse_each do |range, start_values|
            if range.cover?(code)
              str = start_values[0..-2].append(start_values[-1] + code - range.first).
                pack('n*').encode(::Encoding::UTF_8, ::Encoding::UTF_16BE)
              return @unicode_mapping[code] = str
            end
          end
          nil
        end
      end

    end

  end
end
