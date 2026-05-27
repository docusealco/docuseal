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

require 'hexapdf/type/font_simple'
require 'hexapdf/font/true_type_wrapper'

module HexaPDF
  module Type

    # Represents a TrueType font.
    #
    # See: PDF2.0 s9.6.3
    class FontTrueType < FontSimple

      define_field :Subtype, type: Symbol, required: true, default: :TrueType
      define_field :BaseFont, type: Symbol, required: true

      # Overrides the default to provide a font wrapper in case none is set and a complete TrueType
      # is embedded.
      #
      # See: Font#font_wrapper
      def font_wrapper
        if (tmp = super)
          tmp
        elsif (font_file = self.font_file) && self[:BaseFont].to_s !~ /\A[A-Z]{6}\+/
          font = HexaPDF::Font::TrueType::Font.new(StringIO.new(font_file.stream))
          @font_wrapper = HexaPDF::Font::TrueTypeWrapper.new(document, font, subset: true)
        end
      end

      private

      def perform_validation
        std_font = FontType1::StandardFonts.standard_font?(self[:BaseFont])
        super(ignore_missing_font_fields: std_font)

        if self[:FontDescriptor].nil? && !std_font
          yield("Required field FontDescriptor is not set", false)
        end
      end

    end

  end
end
