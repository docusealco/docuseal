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

        # The 'glyf' table contains the instructions for rendering glyphs and some additional glyph
        # information.
        #
        # This is probably always the largest table in a TrueType font, so care is taken to perform
        # operations lazily.
        #
        # See: https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6glyf.html
        class Glyf < Table

          # Represents the definition of a glyph. Since the purpose of this implementation is not
          # editing or rendering glyphs, the raw glyph data is only decoded so far as to get general
          # information about the glyph.
          class Glyph

            # Contains the raw byte data of the glyph.
            attr_reader :raw_data

            # The number of contours in the glyph. A zero or positive number implies a simple glyph,
            # a negative number a glyph made up from multiple components
            attr_reader :number_of_contours

            # The minimum x value for coordinate data.
            attr_reader :x_min

            # The minimum y value for coordinate data.
            attr_reader :y_min

            # The maximum x value for coordinate data.
            attr_reader :x_max

            # The maximum y value for coordinate data.
            attr_reader :y_max

            # The array with the component glyph IDs, or +nil+ if this is not a compound glyph.
            attr_reader :components

            # The array with the component glyph offsets, or +nil+ if this is not a compound glyph.
            attr_reader :component_offsets

            # Creates a new glyph from the given raw data.
            def initialize(raw_data)
              @raw_data = raw_data
              @number_of_contours, @x_min, @y_min, @x_max, @y_max = @raw_data.unpack('s>5')
              @number_of_contours ||= 0
              @x_min ||= 0
              @y_min ||= 0
              @x_max ||= 0
              @y_max ||= 0
              @components = nil
              @component_offsets = nil
              parse_compound_glyph if compound?
            end

            # Returns +true+ if this a compound glyph.
            def compound?
              number_of_contours < 0
            end

            private

            FLAG_ARG_1_AND_2_ARE_WORDS =    1 << 0 #:nodoc:
            FLAG_MORE_COMPONENTS =          1 << 5 #:nodoc:
            FLAG_WE_HAVE_A_SCALE =          1 << 3 #:nodoc:
            FLAG_WE_HAVE_AN_X_AND_Y_SCALE = 1 << 6 #:nodoc:
            FLAG_WE_HAVE_A_TWO_BY_TWO =     1 << 7 #:nodoc:

            # Parses the raw data to get the component glyphs.
            #
            # This is needed because the component glyphs are referenced by their glyph IDs and
            # those may change when subsetting the font.
            def parse_compound_glyph
              @components = []
              @component_offsets = []
              index = 10
              while true
                flags, glyph_id = raw_data[index, 4].unpack('n2')
                @components << glyph_id
                @component_offsets << (index + 2)
                break if flags & FLAG_MORE_COMPONENTS == 0

                index += 4 # fields flags and glyphIndex
                index += (flags & FLAG_ARG_1_AND_2_ARE_WORDS == 0 ? 2 : 4) # arguments
                if flags & FLAG_WE_HAVE_A_TWO_BY_TWO != 0 # transformation
                  index += 8
                elsif flags & FLAG_WE_HAVE_AN_X_AND_Y_SCALE != 0
                  index += 4
                elsif flags & FLAG_WE_HAVE_A_SCALE != 0
                  index += 2
                end
              end
            end

          end

          # The mapping from glyph ID to Glyph object or +nil+ (if the glyph has no outline).
          attr_accessor :glyphs

          # Returns the Glyph object for the given glyph ID. If the glyph has no outline (e.g. the
          # space character), an empty Glyph object is returned.
          def [](glyph_id)
            return @glyphs[glyph_id] if @glyphs.key?(glyph_id)

            offset = font[:loca].offset(glyph_id)
            length = font[:loca].length(glyph_id)

            if length == 0
              @glyphs[glyph_id] = Glyph.new('')
            else
              raw_data = with_io_pos(directory_entry.offset + offset) { io.read(length) }
              @glyphs[glyph_id] = Glyph.new(raw_data)
            end
          end

          private

          # Nothing to parse here since we lazily parse glyphs.
          def parse_table
            @glyphs = {}
          end

        end

      end
    end
  end
end
