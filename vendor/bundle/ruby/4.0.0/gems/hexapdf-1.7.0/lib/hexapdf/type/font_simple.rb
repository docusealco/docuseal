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

require 'hexapdf/type/font'
require 'hexapdf/font/encoding'

module HexaPDF
  module Type

    # Represents a simple PDF font.
    #
    # A simple font has only single-byte character codes and only supports horizontal metrics.
    #
    # See: PDF2.0 s9.6
    class FontSimple < Font

      # Only the common fields are defined here, the rest in FontType1, FontType3, FontTrueType
      define_field :Name, type: Symbol
      define_field :FirstChar, type: Integer
      define_field :LastChar, type: Integer
      define_field :Widths, type: PDFArray
      define_field :FontDescriptor, type: :FontDescriptor
      define_field :Encoding, type: [Dictionary, Symbol]

      # Returns the font descriptor. May be +nil+ for a standard 14 font.
      #
      # The font descriptor is required except for the standard 14 fonts in PDF version up to 1.7.
      def font_descriptor
        self[:FontDescriptor]
      end

      # Returns the encoding object used for this font.
      #
      # Note that the encoding is cached internally when accessed the first time.
      def encoding
        cache(:encoding) do
          case (val = self[:Encoding])
          when Symbol
            encoding = HexaPDF::Font::Encoding.for_name(val)
            encoding = encoding_from_font if encoding.nil?
            encoding
          when HexaPDF::Dictionary
            encoding = val[:BaseEncoding] && HexaPDF::Font::Encoding.for_name(val[:BaseEncoding])
            encoding ||= if embedded? || symbolic?
                           encoding_from_font
                         else
                           HexaPDF::Font::Encoding.for_name(:StandardEncoding)
                         end
            encoding = difference_encoding(encoding, val[:Differences]) if val.key?(:Differences)
            encoding
          when nil
            encoding_from_font
          else
            raise HexaPDF::Error, "Unknown value for font's encoding: #{self[:Encoding]}"
          end
        end
      end

      # Decodes the given string into an array of character codes.
      def decode(string)
        string.bytes
      end

      # Returns the UTF-8 string for the given character code, or calls the configuration option
      # 'font.on_missing_unicode_mapping' if no mapping was found.
      def to_utf8(code)
        to_unicode_cmap&.to_unicode(code) || (encoding.unicode(code) rescue nil) ||
          missing_unicode_mapping(code)
      end

      # Returns the unscaled width of the given code point in glyph units, or 0 if the width for
      # the code point is missing.
      def width(code)
        widths = self[:Widths]
        first_char = self[:FirstChar]
        last_char = self[:LastChar]

        if widths && code >= first_char && code <= last_char
          widths[code - first_char]
        elsif widths && key?(:FontDescriptor)
          self[:FontDescriptor][:MissingWidth]
        else
          0
        end
      end

      # Returns the writing mode which is always :horizontal for simple fonts like Type1.
      def writing_mode
        :horizontal
      end

      # Returns +true+ if the font is a symbolic font, +false+ if it is not, and +nil+ if it is
      # not known.
      def symbolic?
        self[:FontDescriptor]&.flagged?(:symbolic)
      end

      # Returns whether word spacing is applicable when using this font.
      #
      # Always returns +true+ for simple fonts.
      #
      # See: PDF2.0 s9.3.3
      def word_spacing_applicable?
        true
      end

      private

      # Tries to read the encoding from the embedded font.
      #
      # This method has to be implemented in subclasses.
      def encoding_from_font
        raise "Needs to be implemented in subclass"
      end

      # Uses the given base encoding and the differences array to create a DifferenceEncoding
      # object.
      def difference_encoding(base_encoding, differences)
        unless differences[0].kind_of?(Integer)
          raise HexaPDF::Error, "Invalid /Differences array in Encoding dict"
        end

        encoding = HexaPDF::Font::Encoding::DifferenceEncoding.new(base_encoding)
        code = nil
        differences.each do |entry|
          case entry
          when Symbol
            encoding.code_to_name[code] = entry
            code += 1
          when Integer
            code = entry
          else
            raise HexaPDF::Error, "Invalid /Differences array in Encoding dict"
          end
        end
        encoding
      end

      # Validates the simple font dictionary.
      #
      # If +ignore_missing_font_fields+ is +true+, then missing fields are ignored (should only be
      # used for backwards-compatibility regarding the Standard 14 Type1 fonts).
      def perform_validation(ignore_missing_font_fields: false)
        super()
        return if ignore_missing_font_fields

        [:FirstChar, :LastChar, :Widths].each do |field|
          yield("Required field #{field} is not set", false) if self[field].nil?
        end

        widths = self[:Widths]
        if key?(:Widths) && key?(:LastChar) && key?(:FirstChar) &&
            widths.length != (self[:LastChar] - self[:FirstChar] + 1)
          yield("Invalid number of entries in field Widths", true)
          difference = self[:LastChar] - self[:FirstChar] + 1 - widths.length
          if difference > 0
            missing_value = if widths.count(widths[0]) == widths.length
                              widths[0]
                            else
                              self[:FontDescriptor]&.[](:MissingWidth) || 0
                            end
            difference.times { widths << missing_value }
          else
            widths.slice!(difference, -difference)
          end
        end
      end

    end

  end
end
