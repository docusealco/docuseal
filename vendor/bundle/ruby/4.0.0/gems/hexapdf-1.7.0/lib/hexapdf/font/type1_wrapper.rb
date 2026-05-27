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

require 'hexapdf/font/type1'
require 'hexapdf/font/encoding'
require 'hexapdf/error'

module HexaPDF
  module Font

    # This class wraps a generic Type1 font object and provides the methods needed for working with
    # the font in a PDF context.
    class Type1Wrapper

      # Represents a single glyph of the wrapped font.
      class Glyph

        # The associated Type1Wrapper object.
        attr_reader :font_wrapper

        # The name of the glyph.
        attr_reader :name
        alias id name

        # The string representation of the glyph.
        attr_reader :str

        # Creates a new Glyph object.
        def initialize(font_wrapper, name, str)
          @font_wrapper = font_wrapper
          @name = name
          @str = str
        end

        # Returns the glyph's minimum x coordinate.
        def x_min
          @font_wrapper.wrapped_font.metrics.character_metrics[name].bbox[0]
        end

        # Returns the glyph's maximum x coordinate.
        def x_max
          @font_wrapper.wrapped_font.metrics.character_metrics[name].bbox[2]
        end

        # Returns the glyph's minimum y coordinate.
        def y_min
          @font_wrapper.wrapped_font.metrics.character_metrics[name].bbox[1]
        end

        # Returns the glyph's maximum y coordinate.
        def y_max
          @font_wrapper.wrapped_font.metrics.character_metrics[name].bbox[3]
        end

        # Returns the width of the glyph.
        def width
          @width ||= @font_wrapper.wrapped_font.width(name)
        end

        # Returns +true+ if the word spacing parameter needs to be applied for the glyph.
        def apply_word_spacing?
          @name == :space
        end

        # Returns +true+ since this is a valid glyph.
        def valid?
          true
        end

        #:nodoc:
        def inspect
          "#<#{self.class.name} font=#{@font_wrapper.wrapped_font.full_name.inspect} " \
            "id=#{name.inspect} #{str.inspect}>"
        end

      end

      private_constant :Glyph

      # Returns the wrapped Type1 font object.
      attr_reader :wrapped_font

      # Returns the PDF object associated with the wrapper.
      attr_reader :pdf_object

      # Creates a new Type1Wrapper object wrapping the Type1 font.
      #
      # The optional argument +pdf_object+ can be used to set the PDF font object that this wrapper
      # should be associated with. If no object is set, a suitable one is automatically created.
      #
      # If +pdf_object+ is provided, the PDF object's encoding is used. Otherwise, the
      # WinAnsiEncoding or, for 'Special' fonts, the font's internal encoding is used. The optional
      # argument +custom_encoding+ can be set to +true+ so that a custom encoding is used (only
      # respected if +pdf_object+ is not provided).
      def initialize(document, font, pdf_object: nil, custom_encoding: false)
        @wrapped_font = font
        @pdf_object = pdf_object || create_pdf_object(document)

        if pdf_object
          @encoding = pdf_object.encoding
          @max_code = 255 # Encoding is not modified
        elsif custom_encoding
          @encoding = Encoding::Base.new
          @encoding.code_to_name[32] = :space
          @max_code = 32 # 32 = space
        elsif @wrapped_font.metrics.character_set == 'Special'
          @encoding = @wrapped_font.encoding
          @max_code = 255 # Encoding is not modified
        else
          @encoding = Encoding.for_name(:WinAnsiEncoding)
          @max_code = 255 # Encoding is not modified
        end

        @zapf_dingbats_opt = {zapf_dingbats: (@wrapped_font.font_name == 'ZapfDingbats')}
        @name_to_glyph = {}
        @codepoint_to_glyph = {}
        @encoded_glyphs = {}
      end

      # Returns the type of the font, i.e. :Type1.
      def font_type
        :Type1
      end

      # Returns 1 since all Type1 fonts use 1000 units for the em-square.
      def scaling_factor
        1
      end

      # Returns +true+ if the font contains bold glyphs.
      def bold?
        @wrapped_font.weight_class > 500
      end

      # Returns +true+ if the font contains glyphs with an incline (italic or slant).
      def italic?
        @wrapped_font.italic_angle.to_i != 0
      end

      # Returns a Glyph object for the given glyph name.
      def glyph(name)
        @name_to_glyph[name] ||=
          begin
            str = Encoding::GlyphList.name_to_unicode(name, **@zapf_dingbats_opt)
            if @wrapped_font.metrics.character_metrics.key?(name)
              Glyph.new(self, name, str)
            else
              @pdf_object.document.config['font.on_missing_glyph'].call(str, self)
            end
          end
      end

      # Returns a custom Glyph object which represents the given +string+ via the given glyph
      # +name+.
      #
      # This functionality can be used to associate a single glyph name with multiple, different
      # strings for replacement glyph purposes. When used in such a way, the used glyph name is
      # often :question.
      def custom_glyph(name, string)
        unless @wrapped_font.metrics.character_metrics.key?(name)
          raise HexaPDF::Error, "Glyph named #{name.inspect} not found in " \
            "font '#{@wrapped_font.full_name}'"
        end
        Glyph.new(self, name, string)
      end

      # Returns an array of glyph objects representing the characters in the UTF-8 encoded string.
      #
      # See #decode_codepoint for details.
      def decode_utf8(str)
        str.codepoints.map! {|c| @codepoint_to_glyph[c] || decode_codepoint(c) }
      end

      # Returns a glyph object for the given Unicode codepoint.
      #
      # If a Unicode codepoint is not available as glyph object, it is tried to map the codepoint
      # using the font's internal encoding. This is useful, for example, for the ZapfDingbats font
      # to use ASCII characters for accessing the glyphs.
      #
      # The configuration option 'font.on_missing_glyph' is invoked if no glyph for a given
      # codepoint is available.
      def decode_codepoint(codepoint)
        @codepoint_to_glyph[codepoint] ||=
          begin
            name = Encoding::GlyphList.unicode_to_name(+'' << codepoint, **@zapf_dingbats_opt)
            if @wrapped_font.metrics.character_set == 'Special' &&
                (name == :'.notdef' || !@wrapped_font.metrics.character_metrics.key?(name))
              name = @encoding.name(codepoint)
            end
            name = +"u" << codepoint.to_s(16).rjust(6, '0').upcase if name == :'.notdef'
            glyph(name)
          end
      end

      # Encodes the glyph and returns the code string.
      def encode(glyph)
        @encoded_glyphs[glyph.name] ||=
          begin
            raise HexaPDF::MissingGlyphError.new(glyph) if glyph.kind_of?(InvalidGlyph)
            code = @encoding.code(glyph.name)
            if code
              code.chr.freeze
            elsif @max_code < 255
              @max_code += 1
              @encoding.code_to_name[@max_code] = glyph.name
              @max_code.chr.freeze
            else
              raise HexaPDF::Error, "Used Type1 encoding has no codepoint for #{glyph.name.inspect}"
            end
          end
      end

      private

      # Array of valid encoding names in PDF
      VALID_ENCODING_NAMES = [:WinAnsiEncoding, :MacRomanEncoding, :MacExpertEncoding].freeze

      # Creates a PDF object representing the wrapped font for the given PDF document.
      def create_pdf_object(document)
        fd = document.add({Type: :FontDescriptor,
                           FontName: @wrapped_font.font_name.intern,
                           FontWeight: @wrapped_font.weight_class,
                           FontBBox: @wrapped_font.bounding_box,
                           ItalicAngle: @wrapped_font.italic_angle || 0,
                           Ascent: @wrapped_font.ascender || 0,
                           Descent: @wrapped_font.descender || 0,
                           CapHeight: @wrapped_font.cap_height,
                           XHeight: @wrapped_font.x_height,
                           StemH: @wrapped_font.dominant_horizontal_stem_width,
                           StemV: @wrapped_font.dominant_vertical_stem_width || 0})
        fd.flag(:fixed_pitch) if @wrapped_font.metrics.is_fixed_pitch
        fd.flag(@wrapped_font.metrics.character_set == 'Special' ? :symbolic : :nonsymbolic)

        dict = document.add({Type: :Font, Subtype: :Type1,
                             BaseFont: @wrapped_font.font_name.intern,
                             FontDescriptor: fd})
        dict.font_wrapper = self

        document.register_listener(:complete_objects) do
          next if dict.null?
          min, max = @encoding.code_to_name.keys.minmax
          dict[:FirstChar] = min
          dict[:LastChar] = max
          dict[:Widths] = (min..max).map {|code| glyph(@encoding.name(code)).width }

          if VALID_ENCODING_NAMES.include?(@encoding.encoding_name)
            dict[:Encoding] = @encoding.encoding_name
          elsif @encoding != @wrapped_font.encoding
            dict[:Encoding] = {Differences: @encoding.to_compact_array}
          end
        end

        dict
      end

    end

  end
end
