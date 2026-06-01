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

require 'hexapdf/content/operator'
require 'hexapdf/content/graphics_state'

module HexaPDF
  module Content

    # This class is used for processing content operators extracted from a content stream.
    #
    # == General Information
    #
    # When a content stream is read, operators and their operands are extracted. After extracting
    # these operators are usually processed with a Processor instance that ensures that the needed
    # setup (like modifying the graphics state) is done before further processing.
    #
    # == How Processing Works
    #
    # The operator implementations (see the Operator module) are called first and they ensure that
    # the processing state is consistent. For example, operators that modify the graphics state do
    # actually modify the #graphics_state object. However, operator implementations are *only* used
    # for this task and not more, so they are very specific and normally don't need to be changed.
    #
    # After that methods corresponding to the operator names are invoked on the processor object (if
    # they exist). Each PDF operator name is mapped to a nicer message name via the
    # OPERATOR_MESSAGE_NAME_MAP constant. For example, the operator 'q' is mapped to
    # 'save_graphics_state".
    #
    # The task of these methods is to do something useful with the content itself, it doesn't need
    # to concern itself with ensuring the consistency of the processing state. For example, the
    # processor could use the processing state to extract the text. Or paint the content on a
    # canvas.
    #
    # For inline images only the 'BI' operator mapped to 'inline_image' is used. Although also the
    # operators 'ID' and 'EI' exist for inline images, they are not used because they are consumed
    # while parsing inline images and do not reflect separate operators.
    #
    # == Text Processing
    #
    # Two utility methods #decode_text and #decode_text_with_positioning for extracting text are
    # provided. Both can directly be invoked from the 'show_text' and 'show_text_with_positioning'
    # methods.
    #
    class Processor

      # Represents an (immutable) glyph box with positioning information.
      #
      # Since the glyph may have been transformed by an affine matrix, the bounding box may not be a
      # rectangle in all cases but it is always a parallelogram.
      class GlyphBox

        # The code point representing the glyph.
        attr_reader :code_point

        # The Unicode value of the code point.
        attr_reader :string

        # Creates a new glyph box for the given code point/Unicode value pair with the lower left
        # coordinate [llx, lly], the lower right coordinate [lrx, lry], and the upper left
        # coordinate [ulx, uly].
        def initialize(code_point, string, llx, lly, lrx, lry, ulx, uly)
          @code_point = code_point
          @string = string.freeze
          @llx = llx
          @lly = lly
          @lrx = lrx
          @lry = lry
          @ulx = ulx
          @uly = uly
          freeze
        end

        # :call-seq:
        #   glyph_box.lower_left    -> [llx, lly]
        #
        # Returns the lower left coordinate
        def lower_left
          [@llx, @lly]
        end

        # :call-seq:
        #    glyph_box.lower_right   -> [lrx, lry]
        #
        # Returns the lower right coordinate
        def lower_right
          [@lrx, @lry]
        end

        # :call-seq:
        #    glyph_box.upper_left    -> [ulx, uly]
        #
        # Returns the upper left coordinate
        def upper_left
          [@ulx, @uly]
        end

        # :call-seq:
        #    glyph_box.upper_right    -> [urx, ury]
        #
        # Returns the upper right coordinate which is computed by using the other three points of
        # the parallelogram.
        def upper_right
          [@ulx + (@lrx - @llx), @uly + (@lry - @lly)]
        end

        # :call-seq:
        #    glyph_box.points         -> [llx, lly, lrx, lry, urx, ury, ulx, uly]
        #
        # Returns the four corners of the box as an array of coordinates, starting with the lower
        # left corner and going counterclockwise.
        def points
          [@llx, @lly, @lrx, @lry, @ulx + (@lrx - @llx), @uly + (@lry - @lly), @ulx, @uly]
        end

      end

      # Represents a box composed of GlyphBox objects.
      #
      # The bounding box methods #lower_left, #lower_right, #upper_left, #upper_right are computed
      # by just using the first and last boxes, assuming the boxes are arranged from left to right
      # in a straight line.
      class CompositeBox

        # The glyph boxes contained in this composite box object.
        attr_reader :boxes

        # Creates an empty object.
        def initialize
          @boxes = []
        end

        # Appends the given text glyph box.
        def <<(glyph_box)
          @boxes << glyph_box
          self
        end

        # Returns the glyph box at the given index, or +nil+ if the index is out of range.
        def [](index)
          @boxes[index]
        end

        # :call-seq:
        #   composite.each {|glyph_box| block}       -> composite
        #   composite.each                           -> Enumerator
        #
        # Iterates over all contained glyph boxes.
        def each(&block)
          return to_enum(__method__) unless block_given?
          @boxes.each(&block)
          self
        end

        # Returns the concatenated text of all the glyph boxes.
        def string
          @boxes.map(&:string).join
        end

        # :call-seq:
        #   text.lower_left    -> [llx, lly]
        #
        # Returns the lower left coordinate
        def lower_left
          @boxes[0].lower_left
        end

        # :call-seq:
        #    text.lower_right   -> [lrx, lry]
        #
        # Returns the lower right coordinate
        def lower_right
          @boxes[-1].lower_right
        end

        # :call-seq:
        #    text.upper_left    -> [ulx, uly]
        #
        # Returns the upper left coordinate
        def upper_left
          @boxes[0].upper_left
        end

        # :call-seq:
        #    text.upper_right    -> [urx, ury]
        #
        # Returns the upper right coordinate.
        def upper_right
          @boxes[-1].upper_right
        end

      end

      # Mapping of PDF operator names to message names that are sent to renderer implementations.
      OPERATOR_MESSAGE_NAME_MAP = {
        q: :save_graphics_state,
        Q: :restore_graphics_state,
        cm: :concatenate_matrix,
        w: :set_line_width,
        J: :set_line_cap_style,
        j: :set_line_join_style,
        M: :set_miter_limit,
        d: :set_line_dash_pattern,
        ri: :set_rendering_intent,
        i: :set_flatness_tolerance,
        gs: :set_graphics_state_parameters,
        CS: :set_stroking_color_space,
        cs: :set_non_stroking_color_space,
        SC: :set_stroking_color,
        SCN: :set_stroking_color,
        sc: :set_non_stroking_color,
        scn: :set_non_stroking_color,
        G: :set_device_gray_stroking_color,
        g: :set_device_gray_non_stroking_color,
        RG: :set_device_rgb_stroking_color,
        rg: :set_device_rgb_non_stroking_color,
        K: :set_device_cmyk_stroking_color,
        k: :set_device_cmyk_non_stroking_color,
        m: :move_to,
        l: :line_to,
        c: :curve_to,
        v: :curve_to_no_first_control_point,
        y: :curve_to_no_second_control_point,
        h: :close_subpath,
        re: :append_rectangle,
        S: :stroke_path,
        s: :close_and_stroke_path,
        f: :fill_path_non_zero,
        F: :fill_path_non_zero,
        'f*': :fill_path_even_odd,
        B: :fill_and_stroke_path_non_zero,
        'B*': :fill_and_stroke_path_even_odd,
        b: :close_fill_and_stroke_path_non_zero,
        'b*': :close_fill_and_stroke_path_even_odd,
        n: :end_path,
        W: :clip_path_non_zero,
        'W*': :clip_path_even_odd,
        BT: :begin_text,
        ET: :end_text,
        Tc: :set_character_spacing,
        Tw: :set_word_spacing,
        Tz: :set_horizontal_scaling,
        TL: :set_leading,
        Tf: :set_font_and_size,
        Tr: :set_text_rendering_mode,
        Ts: :set_text_rise,
        Td: :move_text,
        TD: :move_text_and_set_leading,
        Tm: :set_text_matrix,
        'T*': :move_text_next_line,
        Tj: :show_text,
        "'": :move_text_next_line_and_show_text,
        '"': :set_spacing_move_text_next_line_and_show_text,
        TJ: :show_text_with_positioning,
        d0: :set_glyph_width, # only for Type 3 fonts
        d1: :set_glyph_width_and_bounding_box, # only for Type 3 fonts
        sh: :paint_shading,
        BI: :inline_image, # ID and EI are not sent because the complete image has been read
        Do: :paint_xobject,
        MP: :designate_marked_content_point,
        DP: :designate_marked_content_point_with_property_list,
        BMC: :begin_marked_content,
        BDC: :begin_marked_content_with_property_list,
        EMC: :end_marked_content,
        BX: :begin_compatibility_section,
        EX: :end_compatibility_section,
      }.freeze

      # Mapping from operator name (Symbol) to a callable object.
      #
      # This hash is prepopulated with the default operator implementations (see
      # Operator::DEFAULT_OPERATORS). If a default operator implementation is not satisfactory, it
      # can easily be changed by modifying this hash.
      attr_reader :operators

      # The resources dictionary used during processing.
      attr_reader :resources

      # The GraphicsState object containing the current graphics state.
      #
      # It is not advised to change this attribute manually, it is automatically adjusted according
      # to the processed operators!
      attr_reader :graphics_state

      # The current graphics object.
      #
      # It is not advised to change this attribute manually, it is automatically adjusted according
      # to the processed operators!
      #
      # This attribute can have the following values:
      #
      # :none:: No current graphics object, i.e. the processor is at the page description level.
      # :path:: The current graphics object is a path.
      # :clipping_path:: The current graphics object is a clipping path.
      # :text:: The current graphics object is text.
      #
      # See: PDF2.0 s8.2
      attr_accessor :graphics_object

      # Initializes a new processor that uses the resources PDF dictionary for resolving resources
      # while processing operators.
      #
      # It is not mandatory to set the resources dictionary on initialization but it needs to be set
      # prior to processing operators!
      def initialize(resources = nil)
        @operators = Operator::DEFAULT_OPERATORS.dup
        @graphics_state = GraphicsState.new
        @graphics_object = :none
        @original_resources = nil
        self.resources = resources
      end

      # Sets the resources dictionary used during processing.
      #
      # The first time resources are set, they are also stored as the "original" resources. This is
      # needed because form XObject don't need to have a resources dictionary and can use the page's
      # resources dictionary instead.
      def resources=(res)
        @original_resources = res if @original_resources.nil?
        @resources = res
      end

      # Processes the operator with the given operands.
      #
      # The operator is first processed with an operator implementation (if any) to ensure correct
      # operations and then the corresponding method on this object is invoked.
      def process(operator, operands = [])
        @operators[operator].invoke(self, *operands) if @operators.key?(operator)
        msg = OPERATOR_MESSAGE_NAME_MAP[operator]
        send(msg, *operands) if msg && respond_to?(msg, true)
      end

      protected

      # Provides a default implementation for the 'Do' operator.
      #
      # It checks if the XObject is a Form XObject and if so, processes the contents of the Form
      # XObject.
      def paint_xobject(name)
        xobject = resources.xobject(name)
        return unless xobject[:Subtype] == :Form

        res = resources
        graphics_state.save

        graphics_state.ctm.premultiply(*xobject[:Matrix]) if xobject.key?(:Matrix)
        xobject.process_contents(self, original_resources: @original_resources)

        graphics_state.restore
        self.resources = res
      end

      # Decodes the given text object and returns it as UTF-8 string.
      #
      # The argument may either be a simple text string (+Tj+ operator) or an array that contains
      # text strings together with positioning information (+TJ+ operator).
      def decode_text(data)
        if data.kind_of?(Array)
          data = data.each_with_object(''.b) {|obj, result| result << obj if obj.kind_of?(String) }
        end
        font = graphics_state.font
        font.decode(data).map {|code_point| font.to_utf8(code_point) }.join
      end

      # Decodes the given text object and returns it as a CompositeBox object.
      #
      # The argument may either be a simple text string (+Tj+ operator) or an array that contains
      # text strings together with positioning information (+TJ+ operator).
      #
      # For each glyph a GlyphBox object is computed. For horizontal fonts the width is
      # predetermined but not the height. The latter is chosen to be the height and offset of the
      # font's bounding box.
      def decode_text_with_positioning(data)
        data = Array(data)
        if graphics_state.font.writing_mode == :horizontal
          decode_horizontal_text(data)
        else
          decode_vertical_text(data)
        end
      end

      private

      # Decodes the given array containing text and positioning information while assuming that the
      # writing direction is horizontal.
      #
      # See: PDF2.0 s9.4.4
      def decode_horizontal_text(array)
        font = graphics_state.font
        scaled_char_space = graphics_state.scaled_character_spacing
        scaled_word_space = (font.word_spacing_applicable? ? graphics_state.scaled_word_spacing : 0)
        scaled_font_size = graphics_state.scaled_font_size

        below_baseline = font.bounding_box[1] * scaled_font_size /
          graphics_state.scaled_horizontal_scaling + graphics_state.text_rise
        above_baseline = font.bounding_box[3] * scaled_font_size /
          graphics_state.scaled_horizontal_scaling + graphics_state.text_rise

        text = CompositeBox.new
        array.each do |item|
          if item.kind_of?(Numeric)
            graphics_state.tm.translate(-item * scaled_font_size, 0)
          else
            font.decode(item).each do |code_point|
              char = font.to_utf8(code_point)
              width = font.width(code_point) * scaled_font_size + scaled_char_space +
                (code_point == 32 ? scaled_word_space : 0)
              matrix = graphics_state.ctm.dup.premultiply(*graphics_state.tm)
              fragment = GlyphBox.new(code_point, char,
                                      *matrix.evaluate(0, below_baseline),
                                      *matrix.evaluate(width, below_baseline),
                                      *matrix.evaluate(0, above_baseline))
              text << fragment
              graphics_state.tm.translate(width, 0)
            end
          end
        end

        text.freeze
      end

      # Decodes the given array containing text and positioning information while assuming that the
      # writing direction is vertical.
      def decode_vertical_text(_data)
        raise "Not yet implemented"
      end

    end

  end
end
