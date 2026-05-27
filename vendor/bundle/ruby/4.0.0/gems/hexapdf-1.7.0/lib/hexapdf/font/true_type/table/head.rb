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
require 'hexapdf/utils/bit_field'

module HexaPDF
  module Font
    module TrueType
      class Table

        # The 'head' table contains global information about the font.
        #
        # See: https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6head.html
        class Head < Table

          extend HexaPDF::Utils::BitField

          # The version of the font (a Rational).
          attr_accessor :version

          # The revision of the font as set by the manufacturer (a Rational).
          attr_accessor :font_revision

          # The adjustment value for the checksum.
          attr_accessor :checksum_adjustment

          # Various font flags. See Flags.
          attr_accessor :flags

          # The number of units per em for the font. Should be a power of 2 in the range from 64
          # through 16384.
          attr_accessor :units_per_em

          # The creation time of the font.
          attr_accessor :created

          # The modification time of the font.
          attr_accessor :modified

          # The bounding box for all glyphs of the font in the form [xmin, ymin, xmax, ymax].
          attr_accessor :bbox

          # Apple Mac style information.
          attr_accessor :mac_style

          bit_field(:mac_style, {bold: 0, italic: 1, underline: 2, outline: 3, shadow: 4,
                                 condensed: 5, extended: 6})

          # The smallest readable size in pixels per em for this font.
          attr_accessor :smallest_readable_size

          # Represents an indication of the direction of the glyphs of the font.
          #
          # 0:: Mixed directional font
          # 1:: Font with only left-to-right glyphs
          # -1:: Font with only right-to-left glyphs
          # 2:: Font with left-to-right and neutral (e.g. punctuation) glyphs
          # -2:: Font with right-to-left and neutral (e.g. punctuation) glyphs
          attr_accessor :font_direction_hint

          # Indicates the type of offset format used in the 'loca' table, 0 for short offsets, 1 for
          # long offsets.
          #
          # See: Loca
          attr_accessor :index_to_loc_format

          # The checksum for the head table is calculated differently because the
          # checksum_adjustment value is not used during the calculation.
          #
          # See: Table#checksum_valid?
          def checksum_valid?
            data = raw_data
            data[8, 4] = 0.chr * 4
            directory_entry.checksum == self.class.calculate_checksum(data)
          end

          private

          def parse_table #:nodoc:
            @version = read_fixed
            @font_revision = read_fixed
            data = read_formatted(46, 'N2n2q>2s>4n2s>3')
            @checksum_adjustment = data[0]
            if data[1] != 0x5F0F3CF5 # the magic number
              raise HexaPDF::Error, "Invalid magic number in 'head' table: #{data[1].to_s(16)}"
            end
            @flags, @units_per_em = data[2], data[3]
            @created, @modified = TIME_EPOCH + data[4], TIME_EPOCH + data[5]
            @bbox = data[6..9]
            @mac_style, @smallest_readable_size, @font_direction_hint, @index_to_loc_format =
              *data[10..13]
            if data[14] != 0 # glyphDataFormat
              raise HexaPDF::Error, "Invalid glyph data format value (should be 0): #{data[14]}"
            end
          end

        end

      end
    end
  end
end
