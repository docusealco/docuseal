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

        # The 'maxp' (maximum profile) table contains the maxima for a number of parameters (e.g. to
        # establish memory requirements).
        #
        # See: https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6maxp.html
        class Maxp < Table

          # The version of the table (a Rational).
          attr_accessor :version

          # The number of glyphs in the font.
          attr_accessor :num_glyphs

          # The maximum number of points in a non-compound glyph.
          attr_accessor :max_points

          # The maximum number of contours in a non-computed glyph.
          attr_accessor :max_contours

          # The maximum number of points in a compound glyph.
          attr_accessor :max_component_points

          # The maximum number of contours in a compound glyph.
          attr_accessor :max_component_contours

          # The maximum number of points used in Twilight Zone (Z0).
          attr_accessor :max_twilight_points

          # The maximum number of storage area locations.
          attr_accessor :max_storage

          # The maximum number of FDEFs (function definitions).
          attr_accessor :max_function_defs

          # The maximum number of IDEFs (instruction defintions).
          attr_accessor :max_instruction_defs

          # The maximum number of elements on the stack, i.e. the stack depth.
          attr_accessor :max_stack_elements

          # The maximum number of bytes for glyph instructions.
          attr_accessor :max_size_of_instructions

          # The maximum number of glyphs referenced at the top level.
          attr_accessor :max_component_elements

          # The levels of recursion (0 if the font has only simple glyphs).
          attr_accessor :max_component_depth

          private

          def parse_table #:nodoc:
            @version = read_fixed
            @num_glyphs, @max_points, @max_contours, @max_component_points, @max_component_contours,
              _unuse, @max_twilight_points, @max_storage, @max_function_defs, @max_instruction_defs,
              @max_stack_elements, @max_size_of_instructions, @max_component_elements,
              @max_component_depth = read_formatted(directory_entry.length - 4, 'n14')
          end

        end

      end
    end
  end
end
