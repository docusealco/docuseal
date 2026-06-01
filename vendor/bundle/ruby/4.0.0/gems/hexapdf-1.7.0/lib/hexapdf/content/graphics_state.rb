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

require 'hexapdf/error'
require 'hexapdf/configuration'
require 'hexapdf/content/color_space'
require 'hexapdf/content/transformation_matrix'

module HexaPDF
  module Content

    # Associates a name with a value, used by various graphics state parameters.
    #
    # See LineCapStyle, LineJoinStyle, TextRenderingMode
    class NamedValue

      # The value itself.
      attr_reader :value

      # The name for the value.
      attr_reader :name

      # Creates a new NamedValue object and freezes it.
      def initialize(name, value)
        @name = name
        @value = value
        freeze
      end

      # The object is equal to +other+ if either the name or the value is equal to +other+, or if
      # the other object is a NamedValue object with the same name and value.
      def ==(other)
        @name == other || @value == other ||
          (other.kind_of?(NamedValue) && @name == other.name && @value == other.value)
      end

      # Returns the value.
      def to_operands
        @value
      end

    end

    # Defines all available line cap styles as constants. Each line cap style is an instance of
    # NamedValue, see ::normalize. For use with e.g. Canvas#line_cap_style.
    #
    # See: PDF2.0 s8.4.3.3
    module LineCapStyle

      # Returns the argument normalized to a valid line cap style, i.e. a NamedValue instance.
      #
      # * 0 or +:butt+ can be used for the BUTT_CAP style.
      # * 1 or +:round+ can be used for the ROUND_CAP style.
      # * 2 or +:projecting_square+ can be used for the PROJECTING_SQUARE_CAP style.
      # * Otherwise an error is raised.
      def self.normalize(style)
        case style
        when :butt, 0 then BUTT_CAP
        when :round, 1 then ROUND_CAP
        when :projecting_square, 2 then PROJECTING_SQUARE_CAP
        else
          raise ArgumentError, "Unknown line cap style: #{style}"
        end
      end

      # Stroke is squared off at the endpoint of a path.
      #
      # Specify as 0 or +:butt+.
      #
      #   #>pdf-small-hide
      #   canvas.line_cap_style(:butt)
      #   canvas.line_width(10).line(50, 20, 50, 80).stroke
      #   canvas.stroke_color("white").line_width(1).line(50, 20, 50, 80).stroke
      BUTT_CAP = NamedValue.new(:butt, 0)

      # A semicircular arc is drawn at the endpoint of a path.
      #
      # Specify as 1 or +:round+.
      #
      #   #>pdf-small-hide
      #   canvas.line_cap_style(:round)
      #   canvas.line_width(10).line(50, 20, 50, 80).stroke
      #   canvas.stroke_color("white").line_width(1).line(50, 20, 50, 80).stroke
      ROUND_CAP = NamedValue.new(:round, 1)

      # The stroke continues half the line width beyond the endpoint of a path.
      #
      # Specify as 2 or +:projecting_square+.
      #
      #   #>pdf-small-hide
      #   canvas.line_cap_style(:projecting_square)
      #   canvas.line_width(10).line(50, 20, 50, 80).stroke
      #   canvas.stroke_color("white").line_width(1).line(50, 20, 50, 80).stroke
      PROJECTING_SQUARE_CAP = NamedValue.new(:projecting_square, 2)

    end

    # Defines all available line join styles as constants. Each line join style is an instance of
    # NamedValue, see ::normalize For use with e.g. Canvas#line_join_style.
    #
    # See: PDF2.0 s8.4.3.4
    module LineJoinStyle

      # Returns the argument normalized to a valid line join style, i.e. a NamedValue instance.
      #
      # * 0 or +:miter+ can be used for the MITER_JOIN style.
      # * 1 or +:round+ can be used for the ROUND_JOIN style.
      # * 2 or +:bevel+ can be used for the BEVEL_JOIN style.
      # * Otherwise an error is raised.
      def self.normalize(style)
        case style
        when :miter, 0 then MITER_JOIN
        when :round, 1 then ROUND_JOIN
        when :bevel, 2 then BEVEL_JOIN
        else
          raise ArgumentError, "Unknown line join style: #{style}"
        end
      end

      # The outer lines of the two segments continue until they meet at an angle.
      #
      # Specify as 0 or +:miter+.
      #
      #   #>pdf-small-hide
      #   canvas.line_join_style(:miter)
      #   canvas.line_width(10).
      #     polyline(20, 20, 50, 80, 80, 20).stroke
      #   canvas.stroke_color("white").line_width(1).line_join_style(:bevel).
      #     polyline(20, 20, 50, 80, 80, 20).stroke
      MITER_JOIN = NamedValue.new(:miter, 0)

      # An arc of a circle is drawn around the point where the segments meet.
      #
      # Specify as 1 or +:round+.
      #
      #   #>pdf-small-hide
      #   canvas.line_join_style(:round)
      #   canvas.line_width(10).
      #     polyline(20, 20, 50, 80, 80, 20).stroke
      #   canvas.stroke_color("white").line_width(1).line_join_style(:bevel).
      #     polyline(20, 20, 50, 80, 80, 20).stroke
      ROUND_JOIN = NamedValue.new(:round, 1)

      # The two segments are finished with butt caps and the space between the ends is filled with a
      # triangle.
      #
      # Specify as 2 or +:bevel+.
      #
      #   #>pdf-small-hide
      #   canvas.line_join_style(:bevel)
      #   canvas.line_width(10).
      #     polyline(20, 20, 50, 80, 80, 20).stroke
      #   canvas.stroke_color("white").line_width(1).line_join_style(:bevel).
      #     polyline(20, 20, 50, 80, 80, 20).stroke
      BEVEL_JOIN = NamedValue.new(:bevel, 2)

    end

    # The line dash pattern defines how a line should be dashed. For use with e.g.
    # Canvas#line_dash_pattern.
    #
    # A dash pattern consists of two parts: the dash array and the dash phase. The dash array
    # defines the length of alternating dashes and gaps (important: starting with dashes). And the
    # dash phase defines the distance into the dash array at which to start.
    #
    # It is easier to show. Following are dash arrays and dash phases and how they would be
    # interpreted:
    #
    #   [] 0                      No dash, one solid line
    #   [3] 0                     3 unit dash, 3 unit gap, 3 unit dash, 3 unit gap, ...
    #   [3] 1                     2 unit dash, 3 unit gap, 3 unit dash, 3 unit gap, ...
    #   [2 1] 0                   2 unit dash, 1 unit gap, 2 unit dash, 1 unit gap, ...
    #   [3 5] 6                   2 unit gap, 3 unit dash, 5 unit gap, 3 unit dash, ...
    #   [2 3] 6                   1 unit dash, 3 unit gap, 2 unit dash, 3 unit gap, ...
    #
    # And visualized it looks like this:
    #
    #   #>pdf-canvas-hide
    #   canvas.line_width(2)
    #   [[[], 0], [[3], 0], [[3], 1], [[2, 1], 0],
    #    [[3, 5], 6], [[2, 3], 6]].each_with_index do |(arr, phase), index|
    #     canvas.line_dash_pattern(arr, phase)
    #     canvas.line(20, 180 - index * 30, 180, 180 - index * 30).stroke
    #   end
    #
    # See: PDF2.0 s8.4.3.6
    class LineDashPattern

      # :call-seq:
      #   LineDashPattern.normalize(line_dash_pattern)         -> line_dash_pattern
      #   LineDashPattern.normalize(array, phase = 0)          -> LineDashPattern.new(array, phase)
      #   LineDashPattern.normalize(number, phase = 0)         -> LineDashPattern.new([number], phase)
      #   LineDashPattern.normalize(0)                         -> LineDashPattern.new
      #
      # Returns the arguments normalized to a valid LineDashPattern instance.
      #
      # If +array+ is 0, the default line dash pattern representing a solid line will be used. If it
      # is a single number, it will be converted into an array holding that number.
      def self.normalize(array, phase = 0)
        case array
        when LineDashPattern then array
        when Array then new(array, phase)
        when 0 then new
        when Numeric then new([array], phase)
        else
          raise ArgumentError, "Unknown line dash pattern: #{array} / #{phase}"
        end
      end

      # The dash array.
      attr_reader :array

      # The dash phase.
      attr_reader :phase

      # Inititalizes the line dash pattern with the given +array+ and +phase+.
      #
      # The argument +phase+ must be non-negative and the numbers in the +array+ must be
      # non-negative and must not all be zero.
      def initialize(array = [], phase = 0)
        if phase < 0 || (!array.empty? &&
          array.inject(0) {|m, n| m < 0 ? m : (n < 0 ? -1 : m + n) } <= 0)
          raise ArgumentError, "Invalid line dash pattern: #{array.inspect} #{phase.inspect}"
        end
        @array = array
        @phase = phase
      end

      # Returns +true+ if the other line dash pattern is the same as this one.
      def ==(other)
        other.kind_of?(self.class) && other.array == array && other.phase == phase
      end

      # Converts the LineDashPattern object to an array of operands for the associated PDF content
      # operator.
      def to_operands
        [@array, @phase]
      end

    end

    # Defines all available rendering intents as constants. For use with e.g.
    # Canvas#rendering_intent.
    #
    # See: PDF2.0 s8.6.5.8
    module RenderingIntent

      # Returns the argument normalized to a valid rendering intent.
      #
      # * If the argument is a valid symbol, it is just returned.
      # * Otherwise an error is raised.
      def self.normalize(intent)
        case intent
        when ABSOLUTE_COLORIMETRIC, RELATIVE_COLORIMETRIC, SATURATION, PERCEPTUAL
          intent
        else
          raise ArgumentError, "Invalid rendering intent: #{intent}"
        end
      end

      # Colors should be represented solely with respect to the light source.
      ABSOLUTE_COLORIMETRIC = :AbsoluteColorimetric

      # Colous should be represented with respect to the combination of the light source and the
      # output medium's white point.
      RELATIVE_COLORIMETRIC = :RelativeColorimetric

      # Colors should be represented in a manner that preserves or emphasizes saturation.
      SATURATION = :Saturation

      # Colous should be represented in a manner that provides a pleasing perceptual appearance.
      PERCEPTUAL = :Perceptual

    end

    # Defines all available text rendering modes as constants. Each text rendering mode is an
    # instance of NamedValue. For use with e.g. Canvas#text_rendering_mode.
    #
    # See: PDF2.0 s9.3.6
    module TextRenderingMode

      # Returns the argument normalized to a valid text rendering mode, i.e. a NamedValue instance.
      #
      # * 0 or +:fill+ can be used for the FILL mode.
      # * 1 or +:stroke+ can be used for the STROKE mode.
      # * 2 or +:fill_stroke+ can be used for the FILL_STROKE mode.
      # * 3 or +:invisible+ can be used for the INVISIBLE mode.
      # * 4 or +:fill_clip+ can be used for the FILL_CLIP mode.
      # * 5 or +:stroke_clip+ can be used for the STROKE_CLIP mode.
      # * 6 or +:fill_stroke_clip+ can be used for the FILL_STROKE_CLIP mode.
      # * 7 or +:clip+ can be used for the CLIP mode.
      # * Otherwise an error is raised.
      def self.normalize(style)
        case style
        when :fill, 0 then FILL
        when :stroke, 1 then STROKE
        when :fill_stroke, 2 then FILL_STROKE
        when :invisible, 3 then INVISIBLE
        when :fill_clip, 4 then FILL_CLIP
        when :stroke_clip, 5 then STROKE_CLIP
        when :fill_stroke_clip, 6 then FILL_STROKE_CLIP
        when :clip, 7 then CLIP
        else
          raise ArgumentError, "Unknown text rendering mode: #{style}"
        end
      end

      # Fill text.
      #
      # Specify as 0 or +:fill+.
      #
      #   #>pdf-small-hide
      #   canvas.font("Helvetica", size: 13)
      #   canvas.text_rendering_mode(:fill)
      #   canvas.text("#{canvas.text_rendering_mode.name}", at: [10, 50])
      FILL = NamedValue.new(:fill, 0)

      # Stroke text.
      #
      # Specify as 1 or +:stroke+.
      #
      #   #>pdf-small-hide
      #   canvas.font("Helvetica", size: 13)
      #   canvas.stroke_color("hp-blue").line_width(0.5)
      #   canvas.text_rendering_mode(:stroke)
      #   canvas.text("#{canvas.text_rendering_mode.name}", at: [10, 50])
      STROKE = NamedValue.new(:stroke, 1)

      # Fill, then stroke text.
      #
      # Specify as 2 or +:fill_stroke+.
      #
      #   #>pdf-small-hide
      #   canvas.font("Helvetica", size: 13)
      #   canvas.stroke_color("hp-blue").line_width(0.5)
      #   canvas.text_rendering_mode(:fill_stroke)
      #   canvas.text("#{canvas.text_rendering_mode.name}", at: [10, 50])
      FILL_STROKE = NamedValue.new(:fill_stroke, 2)

      # Neither fill nor stroke text (invisible).
      #
      # Specify as 3 or +:invisible+.
      #
      #   #>pdf-small-hide
      #   canvas.font("Helvetica", size: 13)
      #   canvas.text_rendering_mode(:invisible)
      #   canvas.text("#{canvas.text_rendering_mode.name}", at: [10, 50])
      #   canvas.stroke_color("hp-blue").line_width(20).line(30, 20, 30, 80).stroke
      INVISIBLE = NamedValue.new(:invisible, 3)

      # Fill text and add to path for clipping.
      #
      # Specify as 4 or +:fill_clip+.
      #
      #   #>pdf-small-hide
      #   canvas.font("Helvetica", size: 13)
      #   canvas.text_rendering_mode(:fill_clip)
      #   canvas.text("#{canvas.text_rendering_mode.name}", at: [10, 50])
      #   canvas.stroke_color("hp-orange").line_width(20).line(30, 20, 30, 80).stroke
      FILL_CLIP = NamedValue.new(:fill_clip, 4)

      # Stroke text and add to path for clipping.
      #
      # Specify as 5 or +:stroke_clip+.
      #
      #   #>pdf-small-hide
      #   canvas.font("Helvetica", size: 13)
      #   canvas.stroke_color("hp-blue").line_width(0.5)
      #   canvas.text_rendering_mode(:stroke_clip)
      #   canvas.text("#{canvas.text_rendering_mode.name}", at: [10, 50])
      #   canvas.stroke_color("hp-orange").line_width(20).line(30, 20, 30, 80).stroke
      STROKE_CLIP = NamedValue.new(:stroke_clip, 5)

      # Fill, then stroke text and add to path for clipping.
      #
      # Specify as 6 or +:fill_stroke_clip+.
      #
      #   #>pdf-small-hide
      #   canvas.font("Helvetica", size: 13)
      #   canvas.stroke_color("hp-blue").line_width(0.5)
      #   canvas.text_rendering_mode(:fill_stroke_clip)
      #   canvas.text("#{canvas.text_rendering_mode.name}", at: [10, 50])
      #   canvas.stroke_color("hp-orange").line_width(20).line(30, 20, 30, 80).stroke
      FILL_STROKE_CLIP = NamedValue.new(:fill_stroke_clip, 6)

      # Add text to path for clipping.
      #
      # Specify as 7 or +:clip+.
      #
      #   #>pdf-small-hide
      #   canvas.font("Helvetica", size: 13)
      #   canvas.stroke_color("hp-blue").line_width(0.5)
      #   canvas.text_rendering_mode(:clip)
      #   canvas.text("#{canvas.text_rendering_mode.name}", at: [10, 50])
      #   canvas.stroke_color("hp-orange").line_width(20).line(30, 20, 30, 80).stroke
      CLIP = NamedValue.new(:clip, 7)

    end

    # A GraphicsState object holds all the graphic control parameters needed for correct
    # operation when parsing or creating a content stream with a Processor object.
    #
    # While a content stream is parsed/created, operations may use the current parameters or
    # modify them.
    #
    # The device-dependent graphics state parameters have not been implemented!
    #
    # See: PDF2.0 s8.4.1
    class GraphicsState

      # The current transformation matrix.
      attr_accessor :ctm

      # The current color used for stroking operations during painting.
      attr_accessor :stroke_color

      # The current color used for all other (i.e. non-stroking) painting operations.
      attr_accessor :fill_color

      # The current line width in user space units.
      attr_accessor :line_width

      # The current line cap style (for the available values see LineCapStyle).
      attr_accessor :line_cap_style

      # The current line join style (for the available values see LineJoinStyle).
      attr_accessor :line_join_style

      # The maximum line length of mitered line joins for stroked paths.
      attr_accessor :miter_limit

      # The line dash pattern (see LineDashPattern).
      attr_accessor :line_dash_pattern

      # The rendering intent (only used for CIE-based colors; for the available values see
      # RenderingIntent).
      attr_accessor :rendering_intent

      # The stroke adjustment for very small line width.
      attr_accessor :stroke_adjustment

      # The current blend mode for the transparent imaging model.
      attr_accessor :blend_mode

      # The soft mask specifying the mask shape or mask opacity value to be used in the
      # transparent imaging model.
      attr_accessor :soft_mask

      # The alpha constant for stroking operations in the transparent imaging model.
      attr_accessor :stroke_alpha

      # The alpha constant for non-stroking operations in the transparent imaging model.
      attr_accessor :fill_alpha

      # A boolean specifying whether the current soft mask and alpha parameters should be
      # interpreted as shape values or opacity values.
      attr_accessor :alpha_source

      # The text matrix.
      #
      # This attribute is non-nil only when inside a text object.
      attr_accessor :tm

      # The text line matrix which captures the state of the text matrix at the beginning of a line.
      #
      # As with the text matrix the text line matrix is non-nil only when inside a text object.
      attr_accessor :tlm

      # The character spacing in unscaled text units.
      #
      # It specifies the additional spacing used for the horizontal or vertical displacement of
      # glyphs.
      attr_reader :character_spacing

      # The word spacing in unscaled text units.
      #
      # It works like the character spacing but is only applied to the ASCII space character.
      attr_reader :word_spacing

      # The horizontal text scaling.
      #
      # The value specifies the percentage of the normal width that should be used.
      attr_reader :horizontal_scaling

      # The leading in unscaled text units.
      #
      # It specifies the distance between the baselines of adjacent lines of text.
      attr_accessor :leading

      # The font for the text.
      attr_reader :font

      # The font size.
      attr_reader :font_size

      # The text rendering mode.
      #
      # It determines if and how the glyphs of a text should be shown (for all available values
      # see TextRenderingMode).
      attr_accessor :text_rendering_mode

      # The text rise distance in unscaled text units.
      #
      # It specifies the distance that the baseline should be moved up or down from its default
      # location.
      attr_accessor :text_rise

      # The text knockout, a boolean value.
      #
      # It specifies whether each glyph should be treated as separate elementary object for the
      # purpose of color compositing in the transparent imaging model (knockout = +false+) or if
      # all glyphs together are treated as one elementary object (knockout = +true+).
      attr_accessor :text_knockout

      # The scaled character spacing used in glyph displacement calculations.
      #
      # This returns the character spacing multiplied by #scaled_horizontal_scaling.
      #
      # See PDF2.0 s9.4.4
      attr_reader :scaled_character_spacing

      # The scaled word spacing used in glyph displacement calculations.
      #
      # This returns the word spacing  multiplied by #scaled_horizontal_scaling.
      #
      # See PDF2.0 s9.4.4
      attr_reader :scaled_word_spacing

      # The scaled font size used in glyph displacement calculations.
      #
      # This returns the font size multiplied by the scaling factor from glyph space to text space
      # (0.001 for all fonts except Type3 fonts or the scaling specified in /FontMatrix for Type3
      # fonts) and multiplied by #scaled_horizontal_scaling.
      #
      # See PDF2.0 s9.4.4, HexaPDF::Type::FontType3
      attr_reader :scaled_font_size

      # The scaled horizontal scaling used in glyph displacement calculations.
      #
      # Since the horizontal scaling attribute is stored in percent of 100, this method returns the
      # correct value for calculations.
      #
      # See PDF2.0 s9.4.4
      attr_reader :scaled_horizontal_scaling

      # Initializes the graphics state parameters to their default values.
      def initialize
        @ctm = TransformationMatrix.new
        @stroke_color = @fill_color =
          GlobalConfiguration.constantize('color_space.map', :DeviceGray).new.default_color
        @line_width = 1.0
        @line_cap_style = LineCapStyle::BUTT_CAP
        @line_join_style = LineJoinStyle::MITER_JOIN
        @miter_limit = 10.0
        @line_dash_pattern = LineDashPattern.new
        @rendering_intent = RenderingIntent::RELATIVE_COLORIMETRIC
        @stroke_adjustment = false
        @blend_mode = :Normal
        @soft_mask = :None
        @stroke_alpha = @fill_alpha = 1.0
        @alpha_source = false

        @tm = nil
        @tlm = nil
        @character_spacing = 0
        @word_spacing = 0
        @horizontal_scaling = 100
        @leading = 0
        @font = nil
        @font_size = 0
        @text_rendering_mode = TextRenderingMode::FILL
        @text_rise = 0
        @text_knockout = true

        @scaled_character_spacing = 0
        @scaled_word_spacing = 0
        @scaled_font_size = 0
        @scaled_horizontal_scaling = 1

        @stack = []
      end

      # Saves the current graphics state on the internal stack.
      def save
        @stack.push([@ctm, @stroke_color, @fill_color,
                     @line_width, @line_cap_style, @line_join_style, @miter_limit,
                     @line_dash_pattern, @rendering_intent, @stroke_adjustment, @blend_mode,
                     @soft_mask, @stroke_alpha, @fill_alpha, @alpha_source,
                     @character_spacing, @word_spacing, @horizontal_scaling, @leading,
                     @font, @font_size, @text_rendering_mode, @text_rise, @text_knockout,
                     @scaled_character_spacing, @scaled_word_spacing, @scaled_font_size,
                     @scaled_horizontal_scaling])
        @ctm = @ctm.dup
      end

      # Restores the graphics state from the internal stack.
      #
      # Raises an error if the stack is empty.
      def restore
        if @stack.empty?
          raise HexaPDF::Error, "Can't restore graphics state because the stack is empty"
        end
        @ctm, @stroke_color, @fill_color,
          @line_width, @line_cap_style, @line_join_style, @miter_limit, @line_dash_pattern,
          @rendering_intent, @stroke_adjustment, @blend_mode,
          @soft_mask, @stroke_alpha, @fill_alpha, @alpha_source,
          @character_spacing, @word_spacing, @horizontal_scaling, @leading,
          @font, @font_size, @text_rendering_mode, @text_rise, @text_knockout,
          @scaled_character_spacing, @scaled_word_spacing, @scaled_font_size,
          @scaled_horizontal_scaling = @stack.pop
      end

      # Returns +true+ if the internal stack of saved graphic states contains entries.
      def saved_states?
        !@stack.empty?
      end

      ##
      # :attr_accessor: stroke_color_space
      #
      # The current color space for stroking operations during painting.

      # :nodoc:
      def stroke_color_space
        @stroke_color.color_space
      end

      def stroke_color_space=(color_space) # :nodoc:
        self.stroke_color = color_space.default_color
      end

      ##
      # :attr_accessor: fill_color_space
      #
      # The current color space for non-stroking operations during painting.

      # :nodoc:
      def fill_color_space
        @fill_color.color_space
      end

      def fill_color_space=(color_space) #:nodoc:
        self.fill_color = color_space.default_color
      end

      ##
      # :attr_writer: font
      #
      # Sets the font and updates the glyph space to text space scaling.
      def font=(font)
        @font = font
        update_scaled_font_size
      end

      ##
      # :attr_writer: character_spacing
      #
      # Sets the character spacing and updates the scaled character spacing.
      def character_spacing=(space)
        @character_spacing = space
        @scaled_character_spacing = space * @scaled_horizontal_scaling
      end

      ##
      # :attr_writer: word_spacing
      #
      # Sets the word spacing and updates the scaled word spacing.
      def word_spacing=(space)
        @word_spacing = space
        @scaled_word_spacing = space * @scaled_horizontal_scaling
      end

      ##
      # :attr_writer: font_size
      #
      # Sets the font size and updates the scaled font size.
      def font_size=(size)
        @font_size = size
        update_scaled_font_size
      end

      ##
      # :attr_writer: horizontal_scaling
      #
      # Sets the horizontal scaling and updates the scaled character spacing, scaled word spacing
      # and scaled font size.
      def horizontal_scaling=(scaling)
        @horizontal_scaling = scaling
        @scaled_horizontal_scaling = scaling / 100.0
        @scaled_character_spacing = @character_spacing * @scaled_horizontal_scaling
        @scaled_word_spacing = @word_spacing * @scaled_horizontal_scaling
        update_scaled_font_size
      end

      private

      # Updates the cached value for the scaled font size.
      def update_scaled_font_size
        @scaled_font_size = @font_size * (@font&.glyph_scaling_factor || 0.001) *
          @scaled_horizontal_scaling
      end

    end

  end
end
