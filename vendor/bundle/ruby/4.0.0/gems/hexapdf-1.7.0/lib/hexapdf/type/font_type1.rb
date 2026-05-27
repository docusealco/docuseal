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
require 'hexapdf/type/font_simple'
require 'hexapdf/font/type1'
require 'hexapdf/font/type1_wrapper'

module HexaPDF
  module Type

    # Represents a Type1 font.
    #
    # PDF provides 14 built-in fonts that all PDF readers must understand. These 14 fonts are
    # known as the "Standard 14 Fonts" and are all Type1 fonts. HexaPDF supports these fonts.
    class FontType1 < FontSimple

      # Provides the names and additional mappings of the Standard 14 Fonts.
      module StandardFonts

        # The mapping from font name to Standard 14 Font name, since Adobe allows some
        # additional names for the the Standard 14 Fonts.
        #
        # See: ADB1.7 sH.5.5.1
        @mapping = {
          %s(CourierNew) => %s(Courier),
          %s(CourierNew,Italic) => %s(Courier-Oblique),
          %s(CourierNew,Bold) => %s(Courier-Bold),
          %s(CourierNew,BoldItalic) => %s(Courier-BoldOblique),
          %s(Arial) => %s(Helvetica),
          %s(Arial,Italic) => %s(Helvetica-Oblique),
          %s(Arial,Bold) => %s(Helvetica-Bold),
          %s(Arial,BoldItalic) => %s(Helvetica-BoldOblique),
          %s(TimesNewRoman) => %s(Times-Roman),
          %s(TimesNewRoman,Italic) => %s(Times-Italic),
          %s(TimesNewRoman,Bold) => %s(Times-Bold),
          %s(TimesNewRoman,BoldItalic) => %s(Times-BoldItalic),
        }
        %i[Times-Roman Times-Bold Times-Italic Times-BoldItalic
           Helvetica Helvetica-Bold Helvetica-Oblique Helvetica-BoldOblique
           Courier Courier-Bold Courier-Oblique Courier-BoldOblique
           Symbol ZapfDingbats].each {|name| @mapping[name] = name }

        # Returns +true+ if the given name is the name of a standard font.
        def self.standard_font?(name)
          @mapping.include?(name)
        end

        # Returns the standard name of the font in case an additional name is used, or +nil+ if
        # the given name doesn't belong to a standard font.
        def self.standard_name(name)
          @mapping[name]
        end

        @cache = {}

        # Returns the Type1 font object for the given standard font name, or +nil+ if the given name
        # doesn't belong to a standard font.
        def self.font(name)
          name = @mapping[name]
          if !standard_font?(name)
            nil
          elsif @cache.key?(name)
            @cache[name]
          else
            file = File.join(HexaPDF.data_dir, 'afm', "#{name}.afm")
            @cache[name] = HexaPDF::Font::Type1::Font.from_afm(file)
          end
        end

      end

      define_field :Subtype, type: Symbol, required: true, default: :Type1
      define_field :BaseFont, type: Symbol, required: true

      # Overrides the default to provide a font wrapper in case none is set and the font is one of
      # the standard fonts.
      #
      # See: Font#font_wrapper
      def font_wrapper
        if (tmp = super)
          tmp
        elsif StandardFonts.standard_font?(self[:BaseFont])
          self.font_wrapper = HexaPDF::Font::Type1Wrapper.new(document,
                                                              StandardFonts.font(self[:BaseFont]),
                                                              pdf_object: self)
        end
      end

      # Returns the unscaled width of the given code point in glyph units, or 0 if the width for the
      # code point is missing.
      def width(code)
        if StandardFonts.standard_font?(self[:BaseFont])
          StandardFonts.font(self[:BaseFont]).width(encoding.name(code)) || 0
        else
          super
        end
      end

      # Returns the bounding box of the font or +nil+ if it is not found.
      def bounding_box
        bbox = super
        if bbox
          bbox
        elsif StandardFonts.standard_font?(self[:BaseFont])
          StandardFonts.font(self[:BaseFont]).bounding_box
        else
          nil
        end
      end

      # Returns +true+ if the font is a symbolic font, +false+ if it is not, and +nil+ if it is
      # not known.
      def symbolic?
        symbolic = super
        if !symbolic.nil?
          symbolic
        elsif StandardFonts.standard_font?(self[:BaseFont])
          name = StandardFonts.standard_name(self[:BaseFont])
          name == :ZapfDingbats || name == :Symbol
        else
          nil
        end
      end

      private

      # Reads the encoding from an embedded font file and handles the special case of the Standard
      # 14 fonts.
      def encoding_from_font
        if StandardFonts.standard_font?(self[:BaseFont])
          StandardFonts.font(self[:BaseFont]).encoding
        elsif (obj = self[:FontDescriptor][:FontFile])
          HexaPDF::Font::Type1::PFBParser.encoding(obj.stream)
        else
          raise HexaPDF::Error, "Can't read encoding because Type1 font is not embedded"
        end
      end

      PREDEFINED_ENCODING = [:MacRomanEncoding, :MacExpertEncoding, :WinAnsiEncoding] #:nodoc:

      # Validates the Type1 font dictionary.
      def perform_validation
        std_font = StandardFonts.standard_font?(self[:BaseFont])
        super(ignore_missing_font_fields: std_font)

        if !std_font && self[:FontDescriptor].nil?
          yield("Required field FontDescriptor is not set", false)
        end

        encoding = self[:Encoding]
        if encoding.kind_of?(Symbol) && !PREDEFINED_ENCODING.include?(encoding)
          correctable = (self[:BaseFont] == :Symbol && encoding == :SymbolEncoding) ||
                        (!symbolic? && encoding == :StandardEncoding)
          yield("The /Encoding value '#{encoding}' is invalid", correctable)
          if correctable
            if encoding == :SymbolEncoding
              delete(:Encoding)
            else
              diffs = HexaPDF::Font::Encoding.for_name(:StandardEncoding).
                to_compact_array(base_encoding: HexaPDF::Font::Encoding.for_name(:WinAnsiEncoding))
              self[:Encoding] = {BaseEncoding: :WinAnsiEncoding, Differences: diffs}
            end
          end
        end
      end

    end

  end
end
