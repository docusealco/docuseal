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

        # Generic base class for all cmap subtables.
        #
        # cmap format 8.0 is currently not implemented because use of the format is discouraged in
        # the specification and no font with a format 8.0 cmap subtable was available for testing.
        #
        # The preferred cmap format is 12.0 because it supports all of Unicode and allows for fast
        # and memory efficient code-to-gid as well as gid-to-code mappings.
        #
        # See:
        # * Cmap
        # * https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6cmap.html
        class CmapSubtable

          # The platform identifier for Unicode.
          PLATFORM_UNICODE = 0

          # The platform identifier for Microsoft.
          PLATFORM_MICROSOFT = 3

          # The platform identifier.
          attr_accessor :platform_id

          # The platform-specific encoding identifier.
          attr_accessor :encoding_id

          # The cmap format or +nil+ if the subtable wasn't read from a file.
          attr_reader :format

          # The language code.
          attr_accessor :language

          # The complete code map.
          #
          # Is only fully initialized for existing fonts when a mapping is first accessed via #[].
          attr_accessor :code_map

          # The complete gid map.
          #
          # Is only fully initialized for existing fonts when a mapping is first accessed via
          # #gid_to_code.
          attr_accessor :gid_map

          # Creates a new subtable.
          def initialize(platform_id, encoding_id)
            @platform_id = platform_id
            @encoding_id = encoding_id
            @supported = true
            @code_map = {}
            @gid_map = {}
            @format = nil
            @language = 0
          end

          # Returns +true+ if this subtable contains a Unicode cmap.
          def unicode?
            (platform_id == PLATFORM_MICROSOFT && (encoding_id == 1 || encoding_id == 10)) ||
              platform_id == PLATFORM_UNICODE
          end

          # Returns the glyph index for the given character code or +nil+ if the character code is
          # not mapped.
          def [](code)
            @code_map[code]
          end

          # Returns a character code for the given glyph index or +nil+ if the given glyph index
          # does not exist or is not mapped to a character code.
          #
          # Note that some fonts map multiple character codes to the same glyph (e.g. hyphen and
          # minus), i.e. the code-to-glyph mapping is surjective but not injective! In such a case
          # one of the available character codes is returned.
          def gid_to_code(gid)
            @gid_map[gid]
          end

          # :call-seq:
          #   subtable.parse!(io, offset)     => true or false
          #
          # Parses the cmap subtable from the IO at the given offset.
          #
          # If the subtable format is supported, the information is used to populate this object and
          # +true+ is returned. Otherwise nothing is done and +false+ is returned.
          def parse(io, offset)
            io.pos = offset
            @format = io.read(2).unpack1('n')
            if [8, 10, 12].include?(@format)
              io.pos += 2
              length, @language = io.read(8).unpack('N2')
            elsif [0, 2, 4, 6].include?(@format)
              length, @language = io.read(4).unpack('n2')
            end

            return false unless [0, 2, 4, 6, 10, 12].include?(@format)
            offset = io.pos
            @code_map = lambda do |code|
              parse_mapping(io, offset, length)
              @code_map[code]
            end
            @gid_map = lambda do |gid|
              parse_mapping(io, offset, length)
              @gid_map[gid]
            end
            true
          end

          def parse_mapping(io, offset, length)
            io.pos = offset
            @code_map, @gid_map = case @format
                                  when 0 then Format0.parse(io, length)
                                  when 2 then Format2.parse(io, length)
                                  when 4 then Format4.parse(io, length)
                                  when 6 then Format6.parse(io, length)
                                  when 10 then Format10.parse(io, length)
                                  when 12 then Format12.parse(io, length)
                                  end
          end
          private :parse_mapping

          def inspect #:nodoc:
            "#<#{self.class.name} (#{platform_id}, #{encoding_id}, #{language}, " \
              "#{format.inspect})>"
          end

          # Cmap format 0
          module Format0

            # :call-seq:
            #   Format0.parse(io, length)    -> code_map
            #
            # Parses the format 0 cmap subtable from the given IO at the current position and
            # returns the contained code map.
            #
            # It is assumed that the first six bytes of the subtable have already been consumed.
            def self.parse(io, length)
              raise HexaPDF::Error, "Invalid length #{length} for cmap format 0" if length != 262
              code_map = io.read(256).unpack('C*')
              gid_map = {}
              code_map.each_with_index {|glyph, index| gid_map[glyph] = index }
              [code_map, gid_map]
            end

          end

          # Cmap format 2
          module Format2

            SubHeader = Struct.new(:first_code, :entry_count, :id_delta, :first_glyph_index)

            # :call-seq:
            #   Format2.parse(io, length)    -> code_map
            #
            # Parses the format 2 cmap subtable from the given IO at the current position and
            # returns the contained code map.
            #
            # It is assumed that the first six bytes of the subtable have already been consumed.
            def self.parse(io, length)
              sub_header_keys = io.read(512).unpack('n*')
              nr_sub_headers = 0
              sub_header_keys.map! do |key|
                nr_sub_headers = key if key > nr_sub_headers
                key / 8
              end
              nr_sub_headers = 1 + nr_sub_headers / 8

              sub_headers = []
              nr_sub_headers.times do |i|
                h = SubHeader.new(*io.read(8).unpack('n2s>n'))
                # Map the currently stored id_range_offset to the corresponding glyph index by first
                # changing the offset to begin from the position of the first glyph index and then
                # halfing the value since each glyph is a UInt16.
                h.first_glyph_index = (h.first_glyph_index - 2 - 8 * (nr_sub_headers - i - 1)) / 2
                sub_headers << h
              end
              glyph_indexes = io.read(length - 6 - 512 - 8 * nr_sub_headers).unpack('n*')

              gid_map = {}
              sub_headers.each_with_index do |sub_header, i|
                sub_header.entry_count.times do |j|
                  glyph_id = glyph_indexes[sub_header.first_glyph_index + j]
                  glyph_id = (glyph_id + sub_header.id_delta) % 65536 if glyph_id != 0
                  gid_map[glyph_id] = (sub_header_keys.index(i) << 8) + j + sub_header.first_code
                end
              end

              [mapper(sub_header_keys, sub_headers, glyph_indexes), gid_map]
            end

            def self.mapper(sub_header_keys, sub_headers, glyph_indexes) #:nodoc:
              Hash.new do |h, code|
                i = code
                i, j = i.divmod(256) if code > 255
                k = sub_header_keys[i]
                if !k
                  glyph_id = 0
                elsif k > 0
                  sub_header = sub_headers[k]
                  raise HexaPDF::Error, "Second byte of character code missing" if j.nil?
                  j -= sub_header.first_code
                  if 0 <= j && j < sub_header.entry_count
                    glyph_id = glyph_indexes[sub_header.first_glyph_index + j]
                    glyph_id = (glyph_id + sub_header.id_delta) % 65536 if glyph_id != 0
                  else
                    glyph_id = 0
                  end
                else
                  glyph_id = glyph_indexes[i]
                end
                h[code] = glyph_id unless glyph_id == 0
              end
            end

          end

          # Cmap format 4
          module Format4

            # :call-seq:
            #   Format4.parse(io, length)    -> code_map
            #
            # Parses the format 4 cmap subtable from the given IO at the current position and
            # returns the contained code map.
            #
            # It is assumed that the first six bytes of the subtable have already been consumed.
            def self.parse(io, length)
              seg_count_x2 = io.read(8).unpack1('n')
              end_codes = io.read(seg_count_x2).unpack('n*')
              io.pos += 2
              start_codes = io.read(seg_count_x2).unpack('n*')
              id_deltas = io.read(seg_count_x2).unpack('n*')
              id_range_offsets = io.read(seg_count_x2).unpack('n*').map!.with_index do |offset, idx|
                # Change offsets to indexes, starting from the id_range_offsets array
                offset == 0 ? offset : offset / 2 + idx
              end
              glyph_indexes = io.read(length - 16 - seg_count_x2 * 4).unpack('n*')
              mapper(end_codes, start_codes, id_deltas, id_range_offsets, glyph_indexes)
            end

            # :nodoc:
            def self.mapper(end_codes, start_codes, id_deltas, id_range_offsets, glyph_indexes)
              compute_glyph_id = lambda do |index, code|
                offset = id_range_offsets[index]
                if offset == 0
                  glyph_id = (code + id_deltas[index]) % 65536
                else
                  glyph_id = glyph_indexes[offset - end_codes.length + (code - start_codes[index])]
                  glyph_id ||= 0 # Handle invalid subtable entries
                  glyph_id = (glyph_id + id_deltas[index]) % 65536 if glyph_id != 0
                end
                glyph_id
              end

              code_map = Hash.new do |h, code|
                i = end_codes.bsearch_index {|c| c >= code }
                glyph_id = (i && start_codes[i] <= code ? compute_glyph_id.call(i, code) : 0)
                h[code] = glyph_id unless glyph_id == 0
              end

              gid_map = {}
              end_codes.length.times do |i|
                start_codes[i].upto(end_codes[i]) do |code|
                  gid_map[compute_glyph_id.call(i, code)] = code
                end
              end
              [code_map, gid_map]
            end

          end

          # Cmap format 6
          module Format6

            # :call-seq:
            #   Format6.parse(io, length)    -> code_map
            #
            # Parses the format 6 cmap subtable from the given IO at the current position and
            # returns the contained code map.
            #
            # It is assumed that the first six bytes of the subtable have already been consumed.
            def self.parse(io, _length)
              first_code, entry_count = io.read(4).unpack('n2')
              code_map = io.read(2 * entry_count).unpack('n*')
              gid_map = {}
              code_map = code_map.each_with_index.with_object({}) do |(g, i), hash|
                hash[first_code + i] = g
                gid_map[g] = first_code + i
              end
              [code_map, gid_map]
            end

          end

          # Cmap format 10
          module Format10

            # :call-seq:
            #   Format10.parse(io, length)    -> code_map
            #
            # Parses the format 10 cmap subtable from the given IO at the current position and
            # returns the contained code map.
            #
            # It is assumed that the first twelve bytes of the subtable have already been consumed.
            def self.parse(io, _length)
              first_code, entry_count = io.read(8).unpack('N2')
              code_map = io.read(2 * entry_count).unpack('n*')
              gid_map = {}
              code_map = code_map.each_with_index.with_object({}) do |(g, i), hash|
                hash[first_code + i] = g
                gid_map[g] = first_code + i
              end
              [code_map, gid_map]
            end

          end

          # Cmap format 12
          module Format12

            # :call-seq:
            #   Format12.parse(io, length)    -> code_map
            #
            # Parses the format 12 cmap subtable from the given IO at the current position and
            # returns the contained code map.
            #
            # It is assumed that the first twelve bytes of the subtable have already been consumed.
            def self.parse(io, _length)
              mapper(Array.new(io.read(4).unpack1('N')) { io.read(12).unpack('N3') })
            end

            # The parameter +groups+ is an array containing [start_code, end_code, start_glyph_id]
            # arrays.
            def self.mapper(groups) #:nodoc:
              code_map = Hash.new do |h, code|
                group = groups.bsearch {|g| g[1] >= code }
                h[code] = group[2] + (code - group[0]) if group && group[0] <= code
              end
              groups_by_gid = groups.sort_by {|g| g[2] }
              gid_map = Hash.new do |h, gid|
                group = groups_by_gid.bsearch {|g| g[2] + g[1] - g[0] >= gid }
                h[gid] = group[0] + (gid - group[2]) if group && group[2] <= gid
              end
              [code_map, gid_map]
            end

          end

        end

      end
    end
  end
end
