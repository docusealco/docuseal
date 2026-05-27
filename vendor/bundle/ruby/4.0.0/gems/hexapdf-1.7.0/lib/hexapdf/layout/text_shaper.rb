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

require 'hexapdf/layout/numeric_refinements'

module HexaPDF
  module Layout

    using NumericRefinements

    # This class is used to perform text shaping, i.e. changing the position of glyphs (e.g. for
    # kerning) or substituting one or more glyphs for other glyphs (e.g. for ligatures).
    #
    # Status of the implementation:
    #
    # * All text shaping functionality possible for Type1 fonts is implemented, i.e. kerning and
    #   ligature substitution.
    #
    # * For TrueType fonts only kerning via the 'kern' table is implemented.
    class TextShaper

      # Shapes the given text fragment in-place.
      #
      # The following shaping options, retrieved from the text fragment's Style#font_features, are
      # supported:
      #
      # :kern:: Pair-wise kerning.
      # :liga:: Ligature substitution.
      def shape_text(text_fragment)
        font = text_fragment.style.font
        if text_fragment.style.font_features[:liga] && font.wrapped_font.features.include?(:liga)
          if font.font_type == :Type1
            process_type1_ligatures(text_fragment)
          end
          text_fragment.clear_cache
        end
        if text_fragment.style.font_features[:kern] && font.wrapped_font.features.include?(:kern)
          case font.font_type
          when :TrueType
            process_true_type_kerning(text_fragment)
          when :Type1
            process_type1_kerning(text_fragment)
          end
          text_fragment.clear_cache
        end
        text_fragment
      end

      private

      # Processes the text fragment and substitutes ligatures.
      def process_type1_ligatures(text_fragment)
        items = text_fragment.items
        font = text_fragment.style.font
        pairs = font.wrapped_font.metrics.ligature_pairs
        each_glyph_pair(items) do |left_item, right_item, left, right|
          if (ligature = pairs.dig(left_item.id, right_item.id))
            items[left..right] = font.glyph(ligature)
            left
          else
            right
          end
        end
      end

      # Processes the text fragment and does pair-wise kerning.
      def process_type1_kerning(text_fragment)
        pairs = text_fragment.style.font.wrapped_font.metrics.kerning_pairs
        items = text_fragment.items
        each_glyph_pair(items) do |left_item, right_item, left, right|
          if (left + 1 == right) && (kerning = pairs.dig(left_item.id, right_item.id))
            items.insert(right, -kerning)
            right + 1
          else
            right
          end
        end
      end

      # Processes the text fragment and does pair-wise kerning.
      def process_true_type_kerning(text_fragment)
        font = text_fragment.style.font
        table = font.wrapped_font[:kern].horizontal_kerning_subtable
        items = text_fragment.items
        each_glyph_pair(items) do |left_item, right_item, left, right|
          if (left + 1 == right) && (kerning = table.kern(left_item.id, right_item.id))
            items.insert(right, -kerning * font.scaling_factor)
            right + 1
          else
            right
          end
        end
      end

      # :call-seq:
      #    each_glyph_pair(items) {|left_item, right_item, left, right}
      #
      # Yields each pair of glyphs of the items array (so left must not be right + 1 if between two
      # glyphs are one or more kerning values).
      #
      # The return value of the block is taken as the next *left* item position.
      def each_glyph_pair(items)
        left = 0
        left_item = items[left]
        right = 1
        right_item = items[right]
        while left_item && right_item
          if left_item.kind_of?(Numeric)
            left += 1
            left_item = items[left]
            right = left + 1
          elsif right_item.kind_of?(Numeric)
            right += 1
          else
            left = yield(left_item, right_item, left, right)
            left_item = items[left]
            right = left + 1
          end
          right_item = items[right]
        end
      end

    end

  end
end
