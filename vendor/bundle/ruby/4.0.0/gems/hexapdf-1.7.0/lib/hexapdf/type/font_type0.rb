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
require 'hexapdf/stream'
require 'hexapdf/font/cmap'

module HexaPDF
  module Type

    # Represents a composite PDF font.
    #
    # Composites fonts wrap a descendant CIDFont and use CIDs to identify glyphs. A CID can be
    # encoded in one or more bytes and an associated CMap specifies how this encoding is done.
    # Composite fonts also allow for vertical writing mode and support TrueType as well as OpenType
    # fonts.
    #
    # See: PDF2.0 s9.7, s9.7.6.1
    class FontType0 < Font

      define_field :Subtype, type: Symbol, required: true, default: :Type0
      define_field :BaseFont, type: Symbol, required: true
      define_field :Encoding, type: [Stream, Symbol], required: true
      define_field :DescendantFonts, type: PDFArray, required: true

      # Returns the CID font of this type 0 font.
      def descendant_font
        cache(:descendant_font) do
          document.wrap(self[:DescendantFonts][0])
        end
      end

      # Returns the font descriptor of the descendant font.
      def font_descriptor
        descendant_font[:FontDescriptor]
      end

      # Returns the writing mode which is either :horizontal or :vertical.
      def writing_mode
        cmap.wmode == 0 ? :horizontal : :vertical
      end

      # Decodes the given string into an array of CIDs.
      def decode(string)
        cmap.read_codes(string)
      end

      # Returns the UTF-8 string for the given code, or calls the configuration option
      # 'font.on_missing_unicode_mapping' if no mapping was found.
      def to_utf8(code)
        to_unicode_cmap&.to_unicode(code) || ucs2_cmap&.to_unicode(code) ||
          missing_unicode_mapping(code)
      end

      # Returns the unscaled width of the given CID in glyph units, or 0 if the width for the code
      # point is missing.
      def width(code)
        descendant_font.width(cmap.to_cid(code))
      end

      # Returns the bounding box of the font or +nil+ if it is not found.
      def bounding_box
        descendant_font.bounding_box
      end

      # Returns +true+ if the font is embedded.
      def embedded?
        descendant_font.embedded?
      end

      # Returns the embeeded font file object or +nil+ if the font is not embedded.
      def font_file
        descendant_font.font_file
      end

      # Returns whether word spacing is applicable when using this font.
      #
      # Note that the return value is cached when accessed the first time.
      #
      # See: PDF2.0 s9.3.3
      def word_spacing_applicable?
        @word_spacing_applicable ||= (cmap.read_codes("\x20") && true rescue false)
      end

      private

      # Returns the CMap used for decoding strings for this font.
      #
      # Note that the CMap is cached internally when accessed the first time.
      def cmap
        cache(:cmap) do
          val = self[:Encoding]
          if val.kind_of?(Symbol)
            HexaPDF::Font::CMap.for_name(val.to_s)
          elsif val.kind_of?(HexaPDF::Stream)
            HexaPDF::Font::CMap.parse(val.stream)
          else
            raise HexaPDF::Error, "Unknown value for font's encoding: #{self[:Encoding]}"
          end
        end
      end

      # Returns the UCS-2 CMap used for extracting text when no ToUnicode CMap is available, or
      # +nil+ if the UCS-2 CMap could not be determined.
      #
      # Note that the CMap is cached internally when accessed the first time.
      #
      # See: PDF2.0 s9.10.2
      def ucs2_cmap
        cache(:ucs2_cmap) do
          encoding = self[:Encoding]
          system_info = descendant_font[:CIDSystemInfo]
          registry = system_info[:Registry]
          ordering = system_info[:Ordering]
          if (encoding.kind_of?(Symbol) && HexaPDF::Font::CMap.predefined?(encoding.to_s) &&
            encoding != :'Identity-H' && encoding != :'Identity-V') ||
              (registry == "Adobe" && ['GB1', 'CNS1', 'Japan1', 'Korea1'].include?(ordering))
            HexaPDF::Font::CMap.for_name("#{registry}-#{ordering}-UCS2")
          end
        end
      end

    end

  end
end
