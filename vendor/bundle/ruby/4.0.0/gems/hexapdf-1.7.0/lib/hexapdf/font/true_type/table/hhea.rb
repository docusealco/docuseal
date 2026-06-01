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

        # The 'hhea' (horizontal header) table contains information for layouting fonts whose
        # characters are written horizontally.
        #
        # See: https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6hhea.html
        class Hhea < Table

          # The version of the table (a Rational).
          attr_accessor :version

          # The distance from the baseline of the highest ascender (as intended by the font
          # designer).
          attr_accessor :ascent

          # The distance from the baseline of the lowest descender (as intended by the font
          # designer).
          attr_accessor :descent

          # The typographic line gap (as intended by the font designer).
          attr_accessor :line_gap

          # The maxium advance width (computed value).
          attr_accessor :advance_width_max

          # The minimum left side bearing (computed value).
          attr_accessor :min_left_side_bearing

          # The minimum right side bearing (computed value).
          attr_accessor :min_right_side_bearing

          # The maximum horizontal glyph extent.
          attr_accessor :x_max_extent

          # Defines together with #caret_slope_run the mathematical slope of the angle for the
          # caret.
          #
          # The slope is actually the ratio caret_slope_rise/caret_slope_run
          attr_accessor :caret_slope_rise

          # See #caret_slope_rise.
          attr_accessor :caret_slope_run

          # The amount by which a slanted highlight on a glyph needs (0 for non-slanted fonts).
          attr_accessor :caret_offset

          # The number of horizontal metrics defined in the 'hmtx' table.
          attr_accessor :num_of_long_hor_metrics

          private

          def parse_table #:nodoc:
            @version = read_fixed
            @ascent, @descent, @line_gap, @advance_width_max, @min_left_side_bearing,
              @min_right_side_bearing, @x_max_extent, @caret_slope_rise, @caret_slope_run,
              @caret_offset, @num_of_long_hor_metrics = read_formatted(32, 's>3ns>6x10n')
          end

        end

      end
    end
  end
end
