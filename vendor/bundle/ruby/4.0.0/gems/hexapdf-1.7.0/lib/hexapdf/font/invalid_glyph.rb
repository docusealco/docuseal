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

require 'set'

module HexaPDF
  module Font

    # Represents an invalid glyph, i.e. a Unicode character that has no representation in the used
    # font.
    class InvalidGlyph

      # The associated font wrapper object, either a Type1Wrapper or a TrueTypeWrapper.
      attr_reader :font_wrapper

      # The string that could not be represented as a glyph.
      attr_reader :str

      # Creates a new Glyph object.
      def initialize(font_wrapper, str)
        @font_wrapper = font_wrapper
        @str = str
      end

      # Returns the appropriate missing glyph id based on the used font.
      def id
        @font_wrapper.wrapped_font.missing_glyph_id
      end
      alias name id

      # Returns 0.
      def x_min
        0
      end
      alias x_max x_min
      alias y_min x_min
      alias y_max x_min
      alias width x_min

      # Word spacing is never applied for the invalid glyph, so +false+ is returned.
      def apply_word_spacing?
        false
      end

      # Returns +false+ since this is an invalid glyph.
      def valid?
        false
      end

      # Set of codepoints for text control characters, like tabulator, line separators, non-breaking
      # space etc.
      CONTROL_CHARS = Set.new([9, 10, 11, 12, 13, 133, 8232, 8233, 8203, 173, 160]) #:nodoc:

      # Returns +true+ if this glyph represents a control character like tabulator or newline.
      def control_char?
        CONTROL_CHARS.include?(str.ord)
      end

      #:nodoc:
      def inspect
        "#<#{self.class.name} font=#{@font_wrapper.wrapped_font.full_name.inspect} id=#{id} #{@str.inspect}>"
      end

    end

  end
end
