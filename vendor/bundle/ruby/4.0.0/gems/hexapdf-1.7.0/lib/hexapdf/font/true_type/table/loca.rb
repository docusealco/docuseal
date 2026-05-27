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

        # The 'loca' (location) table contains the offsets of the glyphs relative to the start of
        # the 'glyf' table.
        #
        # See: https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6loca.html
        class Loca < Table

          # The array containing the byte offsets for each glyph relative to the start of the 'glyf'
          # table.
          attr_accessor :offsets

          # Returns the byte offset for the given glyph ID relative to the start of the 'glyf'
          # table.
          def offset(glyph_id)
            @offsets[glyph_id]
          end

          # Returns the length of the 'glyf' entry for the given glyph ID.
          def length(glyph_id)
            @offsets[glyph_id + 1] - @offsets[glyph_id]
          end

          private

          def parse_table #:nodoc:
            entry_size = font[:head].index_to_loc_format
            @offsets = read_formatted(directory_entry.length, (entry_size == 0 ? 'n*' : 'N*'))
            @offsets.map! {|offset| offset * 2 } if entry_size == 0
          end

        end

      end
    end
  end
end
