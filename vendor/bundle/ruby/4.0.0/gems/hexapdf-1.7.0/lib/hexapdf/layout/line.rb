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
require 'hexapdf/layout/text_fragment'

module HexaPDF
  module Layout

    # A Line describes a line of text and can contain TextFragment objects or InlineBox objects.
    #
    # The items of a line fragment are aligned along the x-axis which coincides with the text
    # baseline. The vertical alignment is determined by the value of the #valign method:
    #
    # :text_top::
    #     Align the top of the box with the top of the text of the Line.
    #
    # :text_bottom::
    #     Align the bottom of the box with the bottom of the text of the Line.
    #
    # :baseline::
    #     Align the bottom of the box with the baseline of the Line.
    #
    # :top::
    #     Align the top of the box with the top of the Line.
    #
    # :bottom::
    #     Align the bottom of the box with the bottom of the Line.
    #
    # :text::
    #     This is a special alignment value for text fragment objects. The text fragment is aligned
    #     on the baseline and its minimum and maximum y-coordinates are used when calculating the
    #     line's #text_y_min and #text_y_max.
    #
    #     This value may be used by other objects if they should be handled similar to text
    #     fragments, e.g. graphical representation of characters (think: emoji fonts).
    #
    # == Item Requirements
    #
    # Each item of a line fragment has to respond to the following methods:
    #
    # #x_min:: The minimum x-coordinate of the item.
    # #x_max:: The maximum x-coordinate of the item.
    # #width:: The width of the item.
    # #valign:: The vertical alignment of the item (see above).
    # #draw(canvas, x, y):: Should draw the item onto the canvas at the position (x, y).
    #
    # If an item has a vertical alignment of :text, it additionally has to respond to the following
    # methods:
    #
    # #y_min:: The minimum y-coordinate of the item.
    # #y_max:: The maximum y-coordinate of the item.
    #
    # Otherwise (i.e. a vertical alignment different from :text), the following method must be
    # implemented:
    #
    # #height:: The height of the item.
    class Line

      # Helper class for calculating the needed vertical dimensions of a line.
      class HeightCalculator

        # Creates a new calculator with the given initial items.
        def initialize(items = [])
          reset
          items.each {|item| add(item) }
        end

        # Adds a new item to be considered when calculating the various dimensions.
        def add(item)
          case item.valign
          when :text
            @text_y_min = item.y_min if item.y_min < @text_y_min
            @text_y_max = item.y_max if item.y_max > @text_y_max
          when :baseline
            @max_base_height = item.height if @max_base_height < item.height
          when :top
            @max_top_height = item.height if @max_top_height < item.height
          when :text_top
            @max_text_top_height = item.height if @max_text_top_height < item.height
          when :bottom
            @max_bottom_height = item.height if @max_bottom_height < item.height
          when :text_bottom
            @max_text_bottom_height = item.height if @max_text_bottom_height < item.height
          else
            raise HexaPDF::Error, "Unknown inline box alignment #{item.valign}"
          end
          self
        end
        alias << add

        # Returns the result of the calculations, the array [y_min, y_max, text_y_min, text_y_max].
        #
        # See Line for their meaning.
        def result
          y_min = [@text_y_max - @max_text_top_height, @text_y_min].min
          y_max = [@text_y_min + @max_text_bottom_height, @max_base_height, @text_y_max].max
          y_min = [y_max - @max_top_height, y_min].min
          y_max = [y_min + @max_bottom_height, y_max].max

          [y_min, y_max, @text_y_min, @text_y_max]
        end

        # Resets the calculation.
        def reset
          @text_y_min = 0
          @text_y_max = 0
          @max_base_height = 0
          @max_top_height = 0
          @max_text_top_height = 0
          @max_bottom_height = 0
          @max_text_bottom_height = 0
        end

        # Returns the height of the line as if +item+ was part of it but doesn't change the internal
        # state.
        def simulate_height(item)
          text_y_min = @text_y_min
          text_y_max = @text_y_max
          max_base_height = @max_base_height
          max_top_height = @max_top_height
          max_text_top_height = @max_text_top_height
          max_bottom_height = @max_bottom_height
          max_text_bottom_height = @max_text_bottom_height
          y_min, y_max, = add(item).result
          [y_min, y_max, y_max - y_min]
        ensure
          @text_y_min = text_y_min
          @text_y_max = text_y_max
          @max_base_height = max_base_height
          @max_top_height = max_top_height
          @max_text_top_height = max_text_top_height
          @max_bottom_height = max_bottom_height
          @max_text_bottom_height = max_text_bottom_height
        end

      end

      # The items: TextFragment and InlineBox objects
      attr_accessor :items

      # An optional horizontal offset that should be taken into account when positioning the line.
      #
      # This offset always describes the offset from the left side (and not, for example, the offset
      # from the right side of another line even if those two lines are actually on the same
      # horizontal level).
      attr_accessor :x_offset

      # An optional vertical offset that should be taken into account when positioning the line.
      #
      # For the first line in a paragraph this describes the offset from the top of the box to the
      # baseline of the line. For all other lines it describes the offset from the previous baseline
      # to the baseline of this line.
      attr_accessor :y_offset

      # Creates a new Line object, adding all given items to it.
      def initialize(items = [])
        @items = []
        items.each {|i| add(i) }
        @x_offset = 0
        @y_offset = 0
      end

      # Adds the given item at the end of the item list.
      #
      # If both the item and the last item in the item list are TextFragment objects with the same
      # attributes, they are combined.
      #
      # Note: The cache is not cleared!
      def add(item)
        last = @items.last
        if last.instance_of?(item.class) && item.kind_of?(TextFragment) &&
            last.attributes_hash == item.attributes_hash
          if last.items.frozen?
            @items[-1] = last = last.dup
            last.items = last.items.dup
          end
          last.items[last.items.length, 0] = item.items
          last.clear_cache
        else
          @items << item
        end
        self
      end
      alias << add

      # :call-seq:
      #   line.each {|item, x, y| block }
      #
      # Yields each item together with its horizontal offset from 0 and vertical offset from the
      # baseline.
      def each
        x = 0
        @items.each do |item|
          y = case item.valign
              when :text, :baseline then 0
              when :top then y_max - item.height
              when :text_top then text_y_max - item.height
              when :text_bottom then text_y_min
              when :bottom then y_min
              else
                raise HexaPDF::Error, "Unknown inline box alignment #{item.valign}"
              end
          yield(item, x, y)
          x += item.width
        end
      end

      # The minimum x-coordinate of the whole line.
      def x_min
        @items[0].x_min
      end

      # The maximum x-coordinate of the whole line.
      def x_max
        @x_max ||= width + (items[-1].x_max - items[-1].width)
      end

      # The minimum y-coordinate of any item of the line.
      #
      # It is always lower than or equal to zero.
      def y_min
        @y_min ||= calculate_y_dimensions[0]
      end

      # The minimum y-coordinate of any TextFragment item of the line.
      def text_y_min
        @text_y_min ||= calculate_y_dimensions[2]
      end

      # The maximum y-coordinate of any item of the line.
      #
      # It is always greater than or equal to zero.
      def y_max
        @y_max ||= calculate_y_dimensions[1]
      end

      # The maximum y-coordinate of any TextFragment item of the line.
      def text_y_max
        @text_y_max ||= calculate_y_dimensions[3]
      end

      # The width of the line fragment.
      def width
        @width ||= @items.sum(&:width)
      end

      # The height of the line fragment.
      def height
        y_max - y_min
      end

      # Specifies that this line should not be justified if line justification is used.
      def ignore_justification!
        @ignore_justification = true
      end

      # Returns +true+ if justification should be ignored for this line.
      def ignore_justification?
        defined?(@ignore_justification) && @ignore_justification
      end

      # :call-seq:
      #   line.clear_cache   -> line
      #
      # Clears all cached values.
      #
      # This method needs to be called if the line's items are changed!
      def clear_cache
        @x_max = @y_min = @y_max = @text_y_min = @text_y_max = @width = nil
        self
      end

      private

      # :call-seq:
      #    line.calculate_y_dimensions     -> [y_min, y_max, text_y_min, text_y_max]
      #
      # Calculates all y-values and returns them as array.
      #
      # The following algorithm is used for the calculations:
      #
      # 1. Calculate #text_y_min and #text_y_max by using only the items with valign :text.
      #
      # 2. Calculate the temporary #y_min by using either the maximum height of all items with
      #    valign :text_top subtraced from #text_y_max, or #text_y_min, whichever is smaller.
      #
      #    For the temporary #y_max, use either the maximum height of all items with valign equal to
      #    :text_bottom added to #text_y_min, or the maximum height of all items with valign
      #    :baseline, or #text_y_max, whichever is larger.
      #
      # 3. Calculate the final #y_min by using either the maximum height of all items with valign
      #    :top subtracted from the temporary #y_min, or the temporary #y_min, whichever is smaller.
      #
      #    Calculate the final #y_max by using either the maximum height of all items with valign
      #    :bottom added to #y_min, or the temporary #y_max, whichever is larger.
      #
      # In certain cases there is no unique solution to the values of #y_min and #y_max, for
      # example, it depends on the order of the calculations in part 3.
      def calculate_y_dimensions
        @y_min, @y_max, @text_y_min, @text_y_max = HeightCalculator.new(@items).result
      end

    end

  end
end
