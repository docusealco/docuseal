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

require 'hexapdf/font/type1/character_metrics'

module HexaPDF
  module Font
    module Type1

      # Represents the information stored in an AFM font metrics file for a Type1 font that is
      # needed for working with that font in context of the PDF format.
      class FontMetrics

        # PostScript name of the font.
        attr_accessor :font_name

        # Full text name of the font.
        attr_accessor :full_name

        # Name of the typeface family to which the font belongs.
        attr_accessor :family_name

        # A string describing the character set of the font.
        attr_accessor :character_set

        # A string indicating the default encoding used for the font.
        attr_accessor :encoding_scheme

        # A string describing the weight of the font.
        attr_accessor :weight

        # The font bounding box as array of four numbers, specifying the x- and y-coordinates of the
        # bottom-left corner and the x- and y-coordinates of the top-right corner.
        attr_accessor :bounding_box

        # The y-value of the top of the capital H (or 0 or nil if the font doesn't contain a capital
        # H).
        attr_accessor :cap_height

        # The y-value of the top of the lowercase x (or 0 or nil if the font doesnt' contain a
        # lowercase x)
        attr_accessor :x_height

        # Ascender of the font.
        attr_accessor :ascender

        # Descender of the font.
        attr_accessor :descender

        # Dominant width of horizontal stems.
        attr_accessor :dominant_horizontal_stem_width

        # Dominant width of vertical stems.
        attr_accessor :dominant_vertical_stem_width

        # Distance from the baseline for centering underlining strokes.
        attr_accessor :underline_position

        # Stroke width for underlining.
        attr_accessor :underline_thickness

        # Angle (in degrees counter-clockwise from the vertical) of the dominant vertical strokes of
        # the font.
        attr_accessor :italic_angle

        # Boolean specifying if the font is a fixed pitch (monospaced) font.
        attr_accessor :is_fixed_pitch

        # Mapping of character codes and names to CharacterMetrics objects.
        attr_accessor :character_metrics

        # Nested mapping of kerning pairs, ie. each key is a character name and each value is a
        # mapping from the second character name to the kerning amount.
        attr_accessor :kerning_pairs

        # Nested mapping of ligature pairs, ie. each key is a character name and each value is a
        # mapping from the second character name to the ligature name.
        attr_accessor :ligature_pairs

        def initialize #:nodoc:
          @character_metrics = {}
          @kerning_pairs = {}
          @ligature_pairs = {}
        end

        WEIGHT_NAME_TO_NUMBER = {'Bold' => 700, 'Medium' => 500, 'Roman' => 400}.freeze #:nodoc:

        # Returns the weight of the font as a number.
        #
        # The return value 0 is used if the weight class cannot be determined.
        def weight_class
          WEIGHT_NAME_TO_NUMBER.fetch(weight, 0)
        end

      end

    end
  end
end
