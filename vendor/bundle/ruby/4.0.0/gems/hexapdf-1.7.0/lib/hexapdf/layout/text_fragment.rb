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

require 'hexapdf/layout/style'
require 'hexapdf/layout/text_shaper'
require 'hexapdf/layout/numeric_refinements'

module HexaPDF
  module Layout

    # A TextFragment describes an optionally kerned piece of text that shares the same font, font
    # size and other properties.
    #
    # Its items are either glyph objects of the font or numeric values describing kerning
    # information. All returned measurement values are in text space units. If the items or the
    # style are changed, the #clear_cache has to be called. Otherwise the measurements may not be
    # correct!
    #
    # The items of a text fragment may be frozen to indicate that the fragment is potentially used
    # multiple times.
    #
    # The rectangle with the bottom-left corner (#x_min, #y_min) and the top-right corner (#x_max,
    # #y_max) describes the minimum bounding box of the whole text fragment and is usually *not*
    # equal to the box (0, 0)-(#width, #height).
    #
    # *Note*: This class should not be used directly but via
    # HexaPDF::Document::Layout#text_fragments. This way the whole document layout infrastructure
    # like font fallback and such is automatically used.
    class TextFragment

      using NumericRefinements

      # Creates a new TextFragment object for the given text, shapes it and returns it.
      #
      # The needed style of the text fragment is specified by the +style+ argument (see
      # Style::create for details). Note that the resulting style object needs at least the font
      # set.
      #
      # For internal use, see the note under TextFragment for details.
      def self.create(text, style)
        style = Style.create(style)
        fragment = new(style.font.decode_utf8(text), style)
        TextShaper.new.shape_text(fragment)
      end

      # :call-seq:
      #   TextFragment.create_with_fallback_glyphs(text, style)                      -> [frag]
      #   TextFragment.create_with_fallback_glyphs(text, style) {|codepoint| block } -> [frag1, frag2, ...]
      #
      # Creates one or more TextFragment objects for the given text - possibly using glyphs from
      # fallback fonts -, shapes them and returns them.
      #
      # If no block is given, the method works like #create but returns the text fragment inside an
      # array.
      #
      # If a block is given, the text is split on codepoints for which there is no glyph in the
      # style's font. For the parts with valid glyphs TextFragment objects are created like with
      # #create. Each codepoint without a valid glyph is yielded to the given block together with
      # the associated HexaPDF::Font::InvalidGlyph object as arguments. The block needs to return an
      # array of either HexaPDF::Font::Type1Wrapper::Glyph or HexaPDF::Font::TrueTypeWrapper::Glyph
      # objects. This array is then used for creating a TextFragment object.
      #
      # The needed style of the text fragments is specified by the +style+ argument (see
      # Style::create for details). Note that the resulting style object needs at least the font
      # set.
      #
      # For internal use, see the note under TextFragment for details.
      def self.create_with_fallback_glyphs(text, style)
        return [create(text, style)] if !block_given? || text.empty?

        style = Style.create(style)
        styles = Hash.new {|h, k| h[k] = style.dup.font(k) }
        styles[style.font] = style

        result = []
        items = []
        shaper = TextShaper.new
        font = style.font
        text.each_codepoint do |codepoint|
          glyph = font.decode_codepoint(codepoint)
          if glyph.valid? || glyph.control_char?
            items << glyph
          else
            unless items.empty?
              result << shaper.shape_text(new(items, style))
              items = []
            end
            fallback = yield(codepoint, glyph)
            unless fallback.empty?
              result << shaper.shape_text(new(fallback, styles[fallback.first.font_wrapper]))
            end
          end
        end
        result << shaper.shape_text(new(items, style)) unless items.empty?
        result
      end

      # The items (glyphs and kerning values) of the text fragment.
      attr_accessor :items

      # The style to be applied.
      #
      # Only the following properties are used:
      #
      # * Style#font
      # * Style#font_size
      # * Style#horizontal_scaling
      # * Style#character_spacing
      # * Style#word_spacing
      # * Style#text_rise
      # * Style#text_rendering_mode
      # * Style#subscript
      # * Style#superscript
      # * Style#underline
      # * Style#strikeout
      # * Style#fill_color
      # * Style#fill_alpha
      # * Style#stroke_color
      # * Style#stroke_alpha
      # * Style#stroke_width
      # * Style#stroke_cap_style
      # * Style#stroke_join_style
      # * Style#stroke_miter_limit
      # * Style#stroke_dash_pattern
      # * Style#underlays
      # * Style#overlays
      attr_reader :style

      # Creates a new TextFragment object with the given items and style.
      #
      # The argument +style+ can either be a Style object or a hash of style properties, see
      # Style::create for details.
      #
      # For internal use, see the note under TextFragment for details.
      def initialize(items, style, properties: nil)
        @items = items
        @style = Style.create(style)
        @properties = properties
      end

      # Returns the text of the fragment.
      def text
        items.reject {|i| i.kind_of?(Numeric) }.map(&:str).join
      end

      # Creates a new TextFragment with the same style and custom properties as this one but with
      # the given +items+.
      def dup_attributes(items)
        self.class.new(items, @style, properties: @properties.dup)
      end

      # Returns the custom properties hash for the text fragment.
      #
      # See Box#properties for usage details.
      def properties
        @properties ||= {}
      end

      # Returns the value that should be used as hash key when only the fragment's attributes -
      # without the items - should play a role.
      def attributes_hash
        @style.hash ^ @properties.hash
      end

      # The precision used to determine whether two floats represent the same value.
      PRECISION = 0.000001 # :nodoc:

      # Draws the text onto the canvas at the given position.
      #
      # This method is the main styled text drawing facility and therefore some optimizations are
      # done:
      #
      # * The text is drawn using HexaPDF::Content;:Canvas#show_glyphs_only which means that the
      #   text matrix is *not* updated. Therefore the caller must *not* rely on it!
      #
      # * All text style properties mentioned in the description of #style are set except if
      #   +ignore_text_properties+ is set to +true+. Note that this only applies to style properties
      #   that directly affect text drawing, so, for example, underlays/overlays and
      #   underlining/strikeout is always done.
      #
      #   The caller should set +ignore_text_properties+ to +true+ if the graphics state hasn't been
      #   changed. This is the case, for example, if the last thing drawn was a text fragment with
      #   the same style.
      #
      # * It is assumed that the text matrix is not rotated, skewed, etc. so that setting the text
      #   position can be done using the optimal method.
      def draw(canvas, x, y, ignore_text_properties: false)
        style.underlays.draw(canvas, x, y + y_min, self) if style.underlays?

        # Set general font related graphics state if necessary
        unless ignore_text_properties
          canvas.font(style.font, size: style.calculated_font_size).
            horizontal_scaling(style.horizontal_scaling).
            character_spacing(style.character_spacing).
            word_spacing(style.word_spacing).
            text_rise(style.calculated_text_rise).
            text_rendering_mode(style.text_rendering_mode)

          # Set fill and/or stroke related graphics state
          canvas.opacity(fill_alpha: style.fill_alpha, stroke_alpha: style.stroke_alpha)
          trm = canvas.text_rendering_mode
          if trm.value.even? # text is filled
            canvas.fill_color(style.fill_color)
          end
          if trm == :stroke || trm == :fill_stroke || trm == :stroke_clip || trm == :fill_stroke_clip
            canvas.stroke_color(style.stroke_color).
              line_width(style.stroke_width).
              line_cap_style(style.stroke_cap_style).
              line_join_style(style.stroke_join_style).
              miter_limit(style.stroke_miter_limit).
              line_dash_pattern(style.stroke_dash_pattern)
          end
        end

        in_text_object = (canvas.graphics_object == :text)
        canvas.begin_text
        tlm = canvas.graphics_state.tlm
        tx = x - tlm.e
        ty = y - tlm.f
        if tx.abs < PRECISION
          if (ty + canvas.graphics_state.leading).abs < PRECISION
            canvas.move_text_cursor
          else
            canvas.move_text_cursor(offset: [0, ty], absolute: false)
          end
        elsif ty.abs < PRECISION
          canvas.move_text_cursor(offset: [tx, 0], absolute: false)
        else
          canvas.move_text_cursor(offset: [x, y], absolute: in_text_object)
        end
        canvas.show_glyphs_only(items)

        if style.underline? && style.underline
          y_offset = style.calculated_underline_position
          canvas.save_graphics_state do
            canvas.stroke_color(style.fill_color).
              line_width(style.calculated_underline_thickness).
              line_cap_style(:butt).
              line_dash_pattern(0).
              line(x, y + y_offset, x + width, y + y_offset).
              stroke
          end
        end

        if style.strikeout? && style.strikeout
          y_offset = style.calculated_strikeout_position
          canvas.save_graphics_state do
            canvas.stroke_color(style.fill_color).
              line_width(style.calculated_strikeout_thickness).
              line_cap_style(:butt).
              line_dash_pattern(0).
              line(x, y + y_offset, x + width, y + y_offset).
              stroke
          end
        end

        style.overlays.draw(canvas, x, y + y_min, self) if style.overlays?
      end

      # The minimum x-coordinate of the first glyph.
      def x_min
        @x_min ||= calculate_x_min
      end

      # The maximum x-coordinate of the last glyph.
      def x_max
        @x_max ||= calculate_x_max
      end

      # The minimum y-coordinate, calculated using the scaled descender of the font.
      def y_min
        style.scaled_y_min
      end

      # The maximum y-coordinate, calculated using the scaled ascender of the font.
      def y_max
        style.scaled_y_max
      end

      # The minimum y-coordinate of any item.
      def exact_y_min
        @exact_y_min ||= (@items.min_by(&:y_min)&.y_min || 0) *
          style.calculated_font_size / 1000.0 + style.calculated_text_rise
      end

      # The maximum y-coordinate of any item.
      def exact_y_max
        @exact_y_max ||= (@items.max_by(&:y_max)&.y_max || 0) *
          style.calculated_font_size / 1000.0 + style.calculated_text_rise
      end

      # The width of the text fragment.
      #
      # It is the sum of the widths of its items and is calculated by using the algorithm presented
      # in PDF2.0 s9.4.4. By using kerning values as the first and/or last items, the text contained
      # in the fragment may spill over the left and/or right boundary.
      def width
        @width ||= @items.sum {|item| style.scaled_item_width(item) }
      end

      # The height of the text fragment.
      #
      # It is calculated as the difference of the maximum of the +y_max+ values and the minimum of
      # the +y_min+ values of the items. However, the text rise value is also taken into account so
      # that the baseline is always *inside* the bounds. For example, if a large negative text rise
      # value is used, the baseline will be equal to the top boundary; if a large positive value is
      # used, it will be equal to the bottom boundary.
      def height
        @height ||= [y_max, 0].max - [y_min, 0].min
      end

      # Returns the vertical alignment inside a line which is always :text for text fragments.
      #
      # See Line for details.
      def valign
        :text
      end

      # Creates a new text fragment that repeats this fragment's items and applies the necessary
      # spacing so that the returned text fragment fills the given +width+ completely.
      #
      # If the given +width+ is less than the fragment's width, +self+ is returned.
      def fill_horizontal!(width)
        return self if width < self.width

        factor, rest = width.divmod(self.width)
        items = @items * factor
        rest = @items.inject(rest) do |available_width, item|
          new_available_width = available_width - style.scaled_item_width(item)
          break available_width if new_available_width < 0
          items << item
          new_available_width
        end

        spacing = rest / (items.size - 1)
        new_style = @style.dup.update(character_spacing: spacing)
        items << spacing / new_style.scaled_font_size # correct spacing after last item
        self.class.new(items, new_style, properties: @properties.dup)
      end

      # Clears all cached values.
      #
      # This method needs to be called if the fragment's items or attributes are changed!
      def clear_cache
        @x_min = @x_max = @exact_y_min = @exact_y_max = @width = @height = nil
        self
      end

      # :nodoc:
      def inspect
        "#<#{self.class.name} #{text.inspect} #{items.inspect}>"
      end

      private

      def calculate_x_min
        if !@items.empty? && !@items[0].kind_of?(Numeric)
          @items[0].x_min * style.scaled_font_size
        else
          @items.inject(0) do |sum, item|
            sum += item.x_min * style.scaled_font_size
            break sum unless item.kind_of?(Numeric)
            sum
          end
        end
      end

      def calculate_x_max
        if !@items.empty? && !@items[0].kind_of?(Numeric)
          width - scaled_glyph_right_side_bearing(@items[-1])
        else
          @items.reverse_each.inject(width) do |sum, item|
            if item.kind_of?(Numeric)
              sum + item * style.scaled_font_size
            else
              break sum - scaled_glyph_right_side_bearing(item)
            end
          end
        end
      end

      def scaled_glyph_right_side_bearing(glyph)
        (glyph.x_max <= 0 ? 0 : glyph.width - glyph.x_max) * style.scaled_font_size +
          style.scaled_character_spacing +
          (glyph.apply_word_spacing? ? style.scaled_word_spacing : 0)
      end

    end

  end
end
