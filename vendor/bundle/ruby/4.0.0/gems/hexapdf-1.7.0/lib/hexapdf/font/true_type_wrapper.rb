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

require 'hexapdf/font/true_type'
require 'hexapdf/font/cmap'
require 'hexapdf/font/invalid_glyph'
require 'hexapdf/error'

module HexaPDF
  module Font

    # This class wraps a generic TrueType font object and provides the methods needed for working
    # with the font in a PDF context.
    #
    # TrueType fonts can be represented in two ways in PDF: As a simple font with Subtype TrueType
    # or as a composite font using a Type2 CIDFont. The wrapper only supports the composite font
    # case because:
    #
    # * By using a composite font more than 256 characters can be encoded with one font object.
    # * Fonts for vertical writing can potentially be used.
    # * The PDF specification recommends using a composite font (see PDF2.0 s9.9.1 at the end).
    #
    # Additionally, TrueType fonts are *always* embedded.
    class TrueTypeWrapper

      # Represents a single glyph of the wrapped font.
      #
      # Since some characters/strings may be mapped to the same glyph id by the font's builtin cmap
      # table, it is possible that different Glyph instances with the same #id but different #str
      # exist.
      class Glyph

        # The associated TrueTypeWrapper object.
        attr_reader :font_wrapper

        # The glyph ID.
        attr_reader :id

        # The string representation of the glyph.
        attr_reader :str

        # Creates a new Glyph object.
        def initialize(font_wrapper, id, str)
          @font_wrapper = font_wrapper
          @id = id
          @str = str
        end

        # Returns the glyph's minimum x coordinate.
        def x_min
          @x_min ||= @font_wrapper.wrapped_font[:glyf][id].x_min * 1000.0 /
            @font_wrapper.wrapped_font[:head].units_per_em
        end

        # Returns the glyph's maximum x coordinate.
        def x_max
          @x_max ||= @font_wrapper.wrapped_font[:glyf][id].x_max * 1000.0 /
            @font_wrapper.wrapped_font[:head].units_per_em
        end

        # Returns the glyph's minimum y coordinate.
        def y_min
          @y_min ||= @font_wrapper.wrapped_font[:glyf][id].y_min * 1000.0 /
            @font_wrapper.wrapped_font[:head].units_per_em
        end

        # Returns the glyph's maximum y coordinate.
        def y_max
          @y_max ||= @font_wrapper.wrapped_font[:glyf][id].y_max * 1000.0 /
            @font_wrapper.wrapped_font[:head].units_per_em
        end

        # Returns the width of the glyph.
        def width
          @width ||= @font_wrapper.wrapped_font[:hmtx][id].advance_width * 1000.0 /
            @font_wrapper.wrapped_font[:head].units_per_em
        end

        # Returns +false+ since the word spacing parameter is never applied for multibyte font
        # encodings where each glyph is encoded using two bytes.
        def apply_word_spacing?
          false
        end

        # Returns +true+ since this is a valid glyph.
        def valid?
          true
        end

        #:nodoc:
        def inspect
          "#<#{self.class.name} font=#{@font_wrapper.wrapped_font.full_name.inspect} id=#{id} #{str.inspect}>"
        end

      end

      private_constant :Glyph

      # Returns the wrapped TrueType font object.
      attr_reader :wrapped_font

      # Returns the PDF object associated with the wrapper.
      attr_reader :pdf_object

      # Creates a new object wrapping the TrueType font for the PDF document.
      #
      # The optional argument +pdf_object+ can be used to set the PDF font object that this wrapper
      # should be associated with. If no object is set, a suitable one is automatically created.
      #
      # If +subset+ is true, the font is subset.
      def initialize(document, font, pdf_object: nil, subset: true)
        @wrapped_font = font

        @subsetter = (subset ? HexaPDF::Font::TrueType::Subsetter.new(font) : nil)

        @cmap = font[:cmap].preferred_table
        if @cmap.nil?
          raise HexaPDF::Error, "No mapping table for Unicode characters found for TTF " \
            "font #{font.full_name}"
        end
        @pdf_object = pdf_object || create_pdf_object(document)

        @id_to_glyph = {}
        @codepoint_to_glyph = {}
        @encoded_glyphs = {}
        @last_char_code = 0
      end

      # Returns the type of the font, i.e. :TrueType.
      def font_type
        :TrueType
      end

      # Returns the scaling factor for converting font units into PDF units.
      def scaling_factor
        @scaling_factor ||= 1000.0 / @wrapped_font[:head].units_per_em
      end

      # Returns +true+ if the font contains bold glyphs.
      def bold?
        @wrapped_font.weight > 500
      end

      # Returns +true+ if the font contains glyphs with an incline (italic or slant).
      def italic?
        @wrapped_font.italic_angle.to_i != 0
      end

      # Returns +true+ if the wrapped TrueType font will be subset.
      def subset?
        !@subsetter.nil?
      end

      # Returns a Glyph object for the given glyph ID and +str+ pair.
      #
      # The optional argument +str+ should be the string representation of the glyph. It is possible
      # that multiple strings map to the same glyph (e.g. hyphen and soft-hyphen could be
      # represented by the same glyph).
      #
      # Note: Although this method is public, it should normally not be used by application code!
      def glyph(id, str = nil)
        @id_to_glyph[[id, str]] ||=
          if id >= 0 && id < @wrapped_font[:maxp].num_glyphs
            Glyph.new(self, id, str || (+'' << (@cmap.gid_to_code(id) || 0xFFFD)))
          else
            @pdf_object.document.config['font.on_missing_glyph'].call("\u{FFFD}", self)
          end
      end

      # Returns a custom Glyph object which represents the given +string+ via the given glyph +id+.
      #
      # This functionality can be used to associate a single glyph id with multiple, different
      # strings for replacement glyph purposes. When used in such a way, the used glyph id is often
      # 0 which represents the missing glyph.
      def custom_glyph(id, string)
        if id < 0 || id >= @wrapped_font[:maxp].num_glyphs
          raise HexaPDF::Error, "Glyph ID #{id} is invalid for font '#{@wrapped_font.full_name}'"
        end
        Glyph.new(self, id, string)
      end

      # Returns an array of glyph objects representing the characters in the UTF-8 encoded string.
      #
      # See #decode_codepoint for details.
      def decode_utf8(str)
        str.codepoints.map! {|c| @codepoint_to_glyph[c] || decode_codepoint(c) }
      end

      # Returns a glyph object for the given Unicode codepoint.
      #
      # The configuration option 'font.on_missing_glyph' is invoked if no glyph for a given
      # codepoint is available.
      def decode_codepoint(codepoint)
        @codepoint_to_glyph[codepoint] ||=
          if (gid = @cmap[codepoint])
            glyph(gid, +'' << codepoint)
          else
            @pdf_object.document.config['font.on_missing_glyph'].call(+'' << codepoint, self)
          end
      end

      # Encodes the glyph and returns the code string.
      def encode(glyph)
        (@encoded_glyphs[glyph] ||=
          begin
            raise HexaPDF::MissingGlyphError.new(glyph) if glyph.kind_of?(InvalidGlyph)
            @subsetter.use_glyph(glyph.id) if @subsetter
            @last_char_code += 1
            # Handle codes for ASCII characters \r (13), (, ) (40, 41) and \ (92) specially so that
            # they never appear in the output (PDF serialization would need to escape them)
            if @last_char_code == 13 || @last_char_code == 40 || @last_char_code == 92
              @last_char_code += (@last_char_code == 40 ? 2 : 1)
            end
            [[@last_char_code].pack('n'), @last_char_code]
          end)[0]
      end

      private

      # Creates a Type0 font object representing the TrueType font.
      #
      # The returned font object contains only information available at creation time, so no
      # information about glyph specific attributes like width. The missing information is added
      # before the PDF document gets written.
      def create_pdf_object(document)
        fd = document.add({Type: :FontDescriptor,
                           FontName: @wrapped_font.font_name.intern,
                           FontWeight: @wrapped_font.weight,
                           Flags: 0,
                           FontBBox: @wrapped_font.bounding_box.map {|m| m * scaling_factor },
                           ItalicAngle: @wrapped_font.italic_angle || 0,
                           Ascent: @wrapped_font.ascender * scaling_factor,
                           Descent: @wrapped_font.descender * scaling_factor,
                           StemV: @wrapped_font.dominant_vertical_stem_width})
        if @wrapped_font[:'OS/2'].version >= 2
          fd[:CapHeight] = @wrapped_font.cap_height * scaling_factor
          fd[:XHeight] = @wrapped_font.x_height * scaling_factor
        else # estimate values
          # Estimate as per https://www.microsoft.com/typography/otspec/os2.htm#ch
          fd[:CapHeight] = if @cmap[0x0048] # H
                             @wrapped_font[:glyf][@cmap[0x0048]].y_max * scaling_factor
                           else
                             @wrapped_font.ascender * 0.8 * scaling_factor
                           end
          # Estimate as per https://www.microsoft.com/typography/otspec/os2.htm#xh
          fd[:XHeight] = if @cmap[0x0078] # x
                           @wrapped_font[:glyf][@cmap[0x0078]].y_max * scaling_factor
                         else
                           @wrapped_font.ascender * 0.5 * scaling_factor
                         end
        end

        fd.flag(:fixed_pitch) if @wrapped_font[:post].is_fixed_pitch? ||
          @wrapped_font[:hhea].num_of_long_hor_metrics == 1
        fd.flag(:italic) if @wrapped_font[:'OS/2'].selection_include?(:italic) ||
          @wrapped_font[:'OS/2'].selection_include?(:oblique)
        fd.flag(:symbolic)

        cid_font = document.add({Type: :Font, Subtype: :CIDFontType2,
                                 BaseFont: fd[:FontName], FontDescriptor: fd,
                                 CIDSystemInfo: {Registry: "Adobe", Ordering: "Identity",
                                                 Supplement: 0},
                                 CIDToGIDMap: :Identity})
        dict = document.add({Type: :Font, Subtype: :Type0, BaseFont: cid_font[:BaseFont],
                             DescendantFonts: [cid_font]})
        dict.font_wrapper = self

        document.register_listener(:complete_objects) do
          next if dict.null?
          update_font_name(dict)
          embed_font(dict, document)
          complete_width_information(dict)
          create_to_unicode_cmap(dict, document)
          add_encoding_information_cmap(dict, document)
        end

        dict
      end

      UPPERCASE_LETTERS = ('A'..'Z').to_a.freeze #:nodoc:

      # Updates the font name with a unique tag if the font is subset.
      def update_font_name(dict)
        return unless @subsetter

        tag = +''
        data = @encoded_glyphs.each_with_object(''.b) {|(g, v), s| s << g.id.to_s << v[0] }
        hash = Digest::MD5.hexdigest(data << @wrapped_font.font_name).to_i(16)
        while hash != 0 && tag.length < 6
          hash, mod = hash.divmod(UPPERCASE_LETTERS.length)
          tag << UPPERCASE_LETTERS[mod]
        end

        name = (tag << "+" << @wrapped_font.font_name).intern
        dict[:BaseFont] = name
        dict[:DescendantFonts].first[:BaseFont] = name
        dict[:DescendantFonts].first[:FontDescriptor][:FontName] = name
      end

      # Embeds the font.
      def embed_font(dict, document)
        if @subsetter
          data = @subsetter.build_font
          length = data.size
          stream = HexaPDF::StreamData.new(length: length) { data }
        else
          length = @wrapped_font.io.size
          stream = HexaPDF::StreamData.new(@wrapped_font.io, length: length)
        end
        font = document.add({Length1: length, Filter: :FlateDecode}, stream: stream)
        dict[:DescendantFonts].first[:FontDescriptor][:FontFile2] = font
      end

      # Adds the /DW and /W fields to the CIDFont dictionary.
      def complete_width_information(dict)
        default_width = glyph(3, " ").width.to_i
        widths = @encoded_glyphs.reject {|g, _| g.width == default_width }.map do |g, _|
          [(@subsetter ? @subsetter.subset_glyph_id(g.id) : g.id), g.width]
        end.sort!
        dict[:DescendantFonts].first.set_widths(widths, default_width: default_width)
      end

      # Creates the /ToUnicode CMap and updates the font dictionary so that text extraction works
      # correctly.
      def create_to_unicode_cmap(dict, document)
        stream = HexaPDF::StreamData.new do
          mapping = @encoded_glyphs.map do |glyph, (_, char_code)|
            # Using 0xFFFD as mentioned in Adobe #5411, last line before section 1.5
            # TODO: glyph.str assumed to consist of single char, No support for multiple chars
            [char_code, glyph.str.ord || 0xFFFD]
          end.sort_by!(&:first)
          HexaPDF::Font::CMap.create_to_unicode_cmap(mapping)
        end
        stream_obj = document.add({}, stream: stream)
        stream_obj.set_filter(:FlateDecode)
        dict[:ToUnicode] = stream_obj
      end

      # Adds the /Encoding entry to the +dict+.
      #
      # This can either be the identity mapping or, if some Unicode codepoints are mapped to the
      # same glyph, a custom CMap.
      def add_encoding_information_cmap(dict, document)
        mapping = @encoded_glyphs.map do |glyph, (_, char_code)|
          # Using 0xFFFD as mentioned in Adobe #5411, last line before section 1.5
          [char_code, (@subsetter ? @subsetter.subset_glyph_id(glyph.id) : glyph.id)]
        end.sort_by!(&:first)
        if mapping.all? {|char_code, cid| char_code == cid }
          dict[:Encoding] = :'Identity-H'
        else
          stream = HexaPDF::StreamData.new { HexaPDF::Font::CMap.create_cid_cmap(mapping) }
          stream_obj = document.add({Type: :CMap,
                                     CMapName: :Custom,
                                     CIDSystemInfo: {Registry: "Adobe", Ordering: "Identity",
                                                     Supplement: 0},
                                    }, stream: stream)
          stream_obj.set_filter(:FlateDecode)
          dict[:Encoding] = stream_obj
        end
      end

    end

  end
end
