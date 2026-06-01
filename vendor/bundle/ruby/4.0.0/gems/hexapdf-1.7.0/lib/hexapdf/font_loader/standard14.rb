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

require 'hexapdf/data_dir'
require 'hexapdf/font/type1_wrapper'

module HexaPDF
  module FontLoader

    # This module is used for providing the standard 14 PDF fonts.
    module Standard14

      # Mapping of font family name and variant to font name.
      MAPPING = {
        'Times' => {
          none: 'Times-Roman',
          bold: 'Times-Bold',
          italic: 'Times-Italic',
          bold_italic: 'Times-BoldItalic',
        },
        'Helvetica' => {
          none: 'Helvetica',
          bold: 'Helvetica-Bold',
          italic: 'Helvetica-Oblique',
          bold_italic: 'Helvetica-BoldOblique',
        },
        'Courier' => {
          none: 'Courier',
          bold: 'Courier-Bold',
          italic: 'Courier-Oblique',
          bold_italic: 'Courier-BoldOblique',
        },
        'Symbol' => {
          none: 'Symbol',
        },
        'ZapfDingbats' => {
          none: 'ZapfDingbats',
        },
      }.freeze

      # Returns a font wrapper for the named Standard PDF font.
      #
      # +document+::
      #     The PDF document to associate the font wrapper with.
      #
      # +name+::
      #     The name of the built-in font. One of Times, Helvetica, Courier, Symbol or ZapfDingbats.
      #
      # +variant+::
      #     The font variant. Can be :none, :bold, :italic, :bold_italic for Times, Helvetica and
      #     Courier; and must be :none for Symbol and ZapfDingbats.
      #
      # +custom_encoding+::
      #     For Times, Helvetica and Courier the standard encoding WinAnsiEncoding is used. If this
      #     is not wanted because access to other glyphs is needed, set this to +true+
      def self.call(document, name, variant: :none, custom_encoding: false, **)
        name = MAPPING[name] && MAPPING[name][variant]
        return nil if name.nil?

        file = File.join(HexaPDF.data_dir, 'afm', "#{name}.afm")
        font = (@afm_font_cache ||= {})[file] ||= HexaPDF::Font::Type1::Font.from_afm(file)
        HexaPDF::Font::Type1Wrapper.new(document, font, custom_encoding: custom_encoding)
      end

      # Returns a hash of the form 'font_name => [variants, ...]' of the standard 14 PDF fonts.
      def self.available_fonts(_document)
        MAPPING.transform_values(&:keys)
      end

    end

  end
end
