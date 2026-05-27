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
require 'hexapdf/layout/box'
require 'hexapdf/layout/text_layouter'

module HexaPDF
  module Layout

    # A TextBox is used for drawing text, either inside a rectangular box or by flowing it around
    # objects of a Frame.
    #
    # The standard usage is through the helper methods Document::Layout#text and
    # Document::Layout#formatted_text.
    #
    # This class uses TextLayouter behind the scenes to do the hard work.
    #
    # == Used Box Properties
    #
    # The spacing after the last line can be controlled via the style property +last_line_gap+. Also
    # see TextLayouter#style for other style properties taken into account.
    #
    # == Limitations
    #
    # When setting the style property 'position' to +:flow+, padding and border to the left and
    # right as well as a predefined fixed width are not respected and the result will look wrong.
    #
    # == Examples
    #
    # Showing some text:
    #
    #   #>pdf-composer
    #   composer.box(:text, items: layout.text_fragments("This is some text."))
    #   # Or easier with the provided convenience method
    #   composer.text("This is also some text")
    #
    # It is possible to flow the text around other objects by using the style property
    # 'position' with the value +:flow+:
    #
    #   #>pdf-composer
    #   composer.box(:base, width: 30, height: 30,
    #                style: {margin: 5, position: :float, background_color: "hp-blue-light"})
    #   composer.text("This is some text. " * 20, position: :flow)
    #
    # While top and bottom padding and border can be used with flow positioning, left and right
    # padding and border are not supported and the result will look wrong:
    #
    #   #>pdf-composer
    #   composer.box(:base, width: 30, height: 30,
    #                style: {margin: 5, position: :float, background_color: "hp-blue-light"})
    #   composer.text("This is some text. " * 20, padding: 10, position: :flow,
    #                 text_align: :justify)
    class TextBox < Box

      # Creates a new TextBox object with the given inline items (e.g. TextFragment and InlineBox
      # objects).
      def initialize(items:, **kwargs)
        super(**kwargs)
        @tl = TextLayouter.new(style)
        @items = items
        @result = nil
        @x_offset = 0
      end

      # Returns the text that will be drawn.
      #
      # This will ignore any inline boxes or kerning values.
      def text
        @items.map {|item| item.kind_of?(TextFragment) ? item.text : '' }.join
      end

      # Returns +true+ as the 'position' style property value :flow is supported.
      def supports_position_flow?
        true
      end

      # :nodoc:
      def empty?
        super && (!@result || @result.lines.empty?)
      end

      private

      # Fits the text box into the Frame.
      #
      # Depending on the 'position' style property, the text is either fit into the current region
      # of the frame using +available_width+ and +available_height+, or fit to the shape of the
      # frame starting from the top (when 'position' is set to :flow).
      def fit_content(_available_width, _available_height, frame)
        frame = frame.child_frame(box: self)
        @x_offset = 0

        if style.position == :flow
          height = (@initial_height > 0 ? @initial_height : frame.shape.bbox.height) - reserved_height
          @result = @tl.fit(@items, frame.width_specification(reserved_height_top), height,
                            apply_first_text_indent: !split_box?, frame: frame)
          min_x = +Float::INFINITY
          max_x = -Float::INFINITY
          @result.lines.each do |line|
            min_x = [min_x, line.x_offset].min
            max_x = [max_x, line.x_offset + line.width].max
          end
          @width = (min_x.finite? ? max_x - min_x : 0) + reserved_width
          fit_result.x = @x_offset = min_x
          @height = @initial_height > 0 ? @initial_height : @result.height + reserved_height
        else
          @result = @tl.fit(@items, @width - reserved_width, @height - reserved_height,
                            apply_first_text_indent: !split_box?, frame: frame)
          if style.text_align == :left && @initial_width == 0
            @width = (@result.lines.max_by(&:width)&.width || 0) + reserved_width
          end
          if style.text_valign == :top && @initial_height == 0
            @height = @result.height + reserved_height
          end
        end

        if style.last_line_gap && @result.lines.last && @initial_height == 0
          @height += style.line_spacing.gap(@result.lines.last, @result.lines.last)
        end

        if @result.status == :success
          fit_result.success!
        elsif @result.status == :height && !@result.lines.empty?
          fit_result.overflow!
        end
      end

      # Splits the text box into two.
      def split_content
        [self, create_box_for_remaining_items]
      end

      # Draws the text into the box.
      def draw_content(canvas, x, y)
        return if @result.lines.empty?
        @result.draw(canvas, x - @x_offset, y + content_height)
      end

      # Creates a new TextBox instance for the items remaining after fitting the box.
      def create_box_for_remaining_items
        box = create_split_box
        box.instance_variable_set(:@result, nil)
        box.instance_variable_set(:@items, @result.remaining_items)
        box
      end

    end

  end
end
