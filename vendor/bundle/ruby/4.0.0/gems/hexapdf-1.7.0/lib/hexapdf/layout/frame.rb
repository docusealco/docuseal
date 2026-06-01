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

require 'hexapdf/layout/width_from_polygon'
require 'geom2d/polygon'

module HexaPDF
  module Layout

    # A Frame describes the available space for placing boxes and provides additional methods for
    # calculating the needed information for the actual placement.
    #
    # == Usage
    #
    # After a Frame object is initialized, it is ready for fitting boxes in it and drawing them.
    #
    # The explicit way of drawing a box follows these steps:
    #
    # * Call #fit with the box to see if the box can fit into the currently selected region of
    #   available space. If fitting is successful, the box can be drawn using #draw.
    #
    #   The method #fit is also called for absolutely positioned boxes but since these boxes are not
    #   subject to the normal constraints, the provided available width and height are the width and
    #   height inside the frame to the right and top of the bottom-left corner of the box.
    #
    # * If the box didn't fit, call #find_next_region to determine the next region for placing the
    #   box. If a new region was found, start over with #fit. Otherwise the frame has no more space
    #   for placing boxes.
    #
    # * Alternatively to calling #find_next_region it is also possible to call #split. This method
    #   tries to split the box into two so that the first part fits into the current region. If
    #   splitting is successful, the first box can be drawn (Make sure that the second box is
    #   handled correctly). Otherwise, start over with #find_next_region.
    #
    # == Used Box Properties
    #
    # The style properties 'position', 'align', 'valign', 'margin' and 'mask_mode' are taken into
    # account when fitting, splitting or drawing a box. Note that the margin is ignored if a box's
    # side coincides with the frame's original boundary.
    #
    # == Frame Shape
    #
    # A frame's shape is used to determine the available space for laying out boxes.
    #
    # Initially, a frame has a rectangular shape. However, once boxes are added and the frame's
    # available area gets reduced, a frame may have a polygon set consisting of arbitrary
    # rectilinear polygons as shape.
    #
    # It is also possible to provide a different initial shape on initialization.
    class Frame

      include HexaPDF::Utils

      # The x-coordinate of the bottom-left corner.
      attr_reader :left

      # The y-coordinate of the bottom-left corner.
      attr_reader :bottom

      # The width of the frame.
      attr_reader :width

      # The height of the frame.
      attr_reader :height

      # The shape of the frame, either a Geom2D::Rectangle in the simple case or a
      # Geom2D::PolygonSet consisting of rectilinear polygons in the more complex case.
      attr_reader :shape

      # The x-coordinate where the next box will be placed.
      #
      # Note: Since the algorithm for drawing takes the margin of a box into account, the actual
      # x-coordinate (and y-coordinate, available width and available height) might be different.
      attr_reader :x

      # The y-coordinate where the next box will be placed.
      #
      # Also see the note in the #x documentation for further information.
      attr_reader :y

      # The available width of the current region for placing a box.
      #
      # Also see the note in the #x documentation for further information.
      attr_reader :available_width

      # The available height of the current region for placing a box.
      #
      # Also see the note in the #x documentation for further information.
      attr_reader :available_height

      # The context object (a HexaPDF::Type::Page or HexaPDF::Type::Form) for which this frame
      # should be used.
      attr_reader :context

      # An array of box objects representing the parent boxes.
      #
      # The immediate parent is the last array entry, the top-most parent the first one. All boxes
      # that are fitted into this frame have to be child boxes of the immediate parent box.
      attr_reader :parent_boxes

      # Creates a new Frame object for the given rectangular area.
      def initialize(left, bottom, width, height, shape: nil, context: nil, parent_boxes: [])
        @left = left
        @bottom = bottom
        @width = width
        @height = height
        @shape = shape || create_rectangle(left, bottom, left + width, bottom + height)
        @context = context
        @parent_boxes = parent_boxes.freeze

        @x = left
        @y = bottom + height
        @available_width = width
        @available_height = height

        find_max_width_region if shape
        @region_selection = :max_height
      end

      # Creates a new Frame object based on this one.
      #
      # If the +init_args+ arguments are provided, a new Frame is created using the constructor. The
      # optional +shape+ argument is then also passed to the constructor.
      #
      # Otherwise, this frame is duplicated. This kind of invocation is only useful if the +box+
      # argument is provided (because otherwise there would be no difference to this frame).
      #
      # The +box+ argument can be used to add the appropriate parent box to the list of
      # #parent_boxes for the newly created frame.
      def child_frame(*init_args, shape: nil, box: nil)
        parent_boxes = (box ? @parent_boxes.dup << box : @parent_boxes)
        if init_args.empty?
          dup.tap {|result| result.instance_variable_set(:@parent_boxes, parent_boxes) }
        else
          self.class.new(*init_args, shape: shape, context: @context, parent_boxes: parent_boxes)
        end
      end

      # Returns the HexaPDF::Document instance (through #context) that is associated with this Frame
      # object or +nil+ if no context object has been set.
      def document
        @context&.document
      end

      # Fits the given box into the current region of available space and returns the associated
      # Box::FitResult object.
      #
      # Fitting a box takes the style properties 'position', 'align', 'valign', 'margin', and
      # 'mask_mode' into account.
      #
      # Use the Box::FitResult#success? method to determine whether fitting was successful.
      def fit(box)
        return Box::FitResult.new(box, frame: self) if full?

        margin = box.style.margin if box.style.margin?

        position = if box.style.position != :flow || box.supports_position_flow?
                     box.style.position
                   else
                     :default
                   end

        if position.kind_of?(Array)
          x, y = box.style.position

          aw = width - x
          ah = height - y
          fit_result = box.fit(aw, ah, self)
          fit_result.success!

          x += left
          y += bottom
        else
          aw = available_width
          ah = available_height

          margin_top = margin_right = margin_left = margin_bottom = 0
          if margin
            aw -= margin_right = margin.right unless float_equal(@x + aw, @left + @width)
            aw -= margin_left = margin.left unless float_equal(@x, @left)
            ah -= margin_bottom = margin.bottom unless float_equal(@y - ah, @bottom)
            ah -= margin_top = margin.top unless float_equal(@y, @bottom + @height)
          end

          fit_result = box.fit(aw, ah, self)
          return fit_result if fit_result.failure?

          width = box.width
          height = box.height

          case position
          when :default, :float
            x = case box.style.align
                when :left
                  @x + margin_left
                when :right
                  @x + margin_left + aw - width
                when :center
                  max_margin = [margin_left, margin_right].max
                  # If we have enough space left for equal margins, we center perfectly
                  if available_width - width >= 2 * max_margin
                    @x + (available_width - width) / 2.0
                  else
                    @x + margin_left + (aw - width) / 2.0
                  end
                end
            y = case box.style.valign
                when :top
                  @y - margin_top - height
                when :bottom
                  @y - available_height + margin_bottom
                when :center
                  max_margin = [margin_top, margin_bottom].max
                  # If we have enough space left for equal margins, we center perfectly
                  if available_height - height >= 2 * max_margin
                    @y - height - (available_height - height) / 2.0
                  else
                    @y - margin_top - height - (ah - height) / 2.0
                  end
                end
          when :flow
            x = fit_result.x || left
            y = @y - height
          else
            raise HexaPDF::Error, "Invalid value '#{position}' for style property position"
          end
        end

        mask_mode = if box.style.mask_mode == :default
                      case position
                      when :default, :flow then :fill_frame_horizontal
                      else :box
                      end
                    else
                      box.style.mask_mode
                    end
        rectangle =
          case mask_mode
          when :none
            create_rectangle(x, y, x, y)
          when :box
            if margin
              create_rectangle([left, x - (margin&.left || 0)].max,
                               [bottom, y - (margin&.bottom || 0)].max,
                               [left + self.width, x + box.width + (margin&.right || 0)].min,
                               [bottom + self.height, y + box.height + (margin&.top || 0)].min)
            else
              create_rectangle(x, y, x + box.width, y + box.height)
            end
          when :fill_horizontal
            create_rectangle(@x, [bottom, y - (margin&.bottom || 0)].max,
                             @x + available_width,
                             [@y, y + box.height + (margin&.top || 0)].min)
          when :fill_frame_horizontal
            create_rectangle(left, [bottom, y - (margin&.bottom || 0)].max,
                             left + self.width, @y)
          when :fill_vertical
            create_rectangle([@x, x - (margin&.left || 0)].max, @y - available_height,
                             [@x + available_width, x + box.width + (margin&.right || 0)].min, @y)
          when :fill
            create_rectangle(@x, @y - available_height, @x + available_width, @y)
          end

        fit_result.x = x
        fit_result.y = y
        fit_result.mask = rectangle
        fit_result
      end

      # Tries to split the box of the given Box::FitResult into two parts and returns both parts.
      #
      # See Box#split for further details.
      def split(fit_result)
        fit_result.box.split
      end

      # Draws the box of the given Box::FitResult onto the canvas at the fitted position.
      #
      # After a box is successfully drawn, the frame's shape is adjusted to remove the occupied
      # area.
      def draw(canvas, fit_result)
        fit_result.draw(canvas)
        remove_area(fit_result.mask)
      end

      # Finds the next region for placing boxes. Returns +false+ if no useful region was found.
      #
      # This method should be called after fitting or drawing a box was not successful. It finds a
      # different region on each invocation. So if a box doesn't fit into the first region, this
      # method should be called again to find another region and to try again.
      #
      # The first tried region starts at the top-most, left-most vertex of the polygon and uses the
      # maximum width. The next tried region uses the maximum height. If both don't work, part of
      # the frame's shape is removed to try again.
      def find_next_region
        case @region_selection
        when :max_width
          if @shape.kind_of?(Geom2D::Rectangle)
            @x = @shape.x
            @y = @shape.y + @shape.height
            @available_width = @shape.width
            @available_height = @shape.height
            @region_selection = :trim_shape
          else
            find_max_width_region
            @region_selection = :max_height
          end
        when :max_height
          x, y, aw, ah = @x, @y, @available_width, @available_height
          find_max_height_region
          if @x == x && @y == y && @available_width == aw && @available_height == ah
            trim_shape
          else
            @region_selection = :trim_shape
          end
        else
          trim_shape
        end

        available_width != 0
      end

      # Removes the given *rectilinear* polygon from the frame's shape.
      def remove_area(polygon)
        return if polygon.kind_of?(Geom2D::Rectangle) && (polygon.width == 0 || polygon.height == 0)

        @shape = if @shape.kind_of?(Geom2D::Rectangle) && polygon.kind_of?(Geom2D::Rectangle) &&
                     float_equal(@shape.x, polygon.x) && float_equal(@shape.width, polygon.width) &&
                     float_equal(@shape.y + @shape.height, polygon.y + polygon.height)
                   if float_equal(@shape.height, polygon.height)
                     Geom2D::PolygonSet()
                   else
                     Geom2D::Rectangle(@shape.x, @shape.y, @shape.width, @shape.height - polygon.height)
                   end
                 else
                   Geom2D::Algorithms::PolygonOperation.run(@shape, polygon, :difference)
                 end
        @region_selection = :max_width
        find_next_region
      end

      # Returns +true+ if the frame has no more space left.
      def full?
        available_width == 0
      end

      # Returns a width specification for the frame's shape that can be used, for example, with
      # TextLayouter.
      #
      # Since not all text may start at the top of the frame, the offset argument can be used to
      # specify a vertical offset from the top of the frame where layouting should start.
      #
      # To be compatible with TextLayouter, the top-left corner of the bounding box of the frame's
      # shape is the origin of the coordinate system for the width specification, with positive
      # x-values to the right and positive y-values downwards.
      #
      # Depending on the complexity of the frame, the result may be any of the allowed width
      # specifications of TextLayouter#fit.
      def width_specification(offset = 0)
        WidthFromPolygon.new(shape, offset)
      end

      private

      # Creates a Geom2D::Polygon object representing the rectangle with the bottom left corner
      # (blx, bly) and the top right corner (trx, try).
      def create_rectangle(blx, bly, trx, try)
        Geom2D::Rectangle(blx, bly, trx - blx, try - bly)
      end

      # Finds the region with the maximum width.
      def find_max_width_region
        return unless (segments = find_starting_point)

        x_right = @x + @available_width

        # Available height can be determined by finding the segment with the highest y-coordinate
        # which lies (maybe only partly) between the vertical lines @x and x_right.
        segments.select! {|s| s.max.x > @x && s.min.x < x_right }
        @available_height = @y - segments.last.start_point.y
      end

      # Finds the region with the maximum height.
      def find_max_height_region
        return unless (segments = find_starting_point)

        # Find segment with maximum y-coordinate directly below (@x,@y), this determines the
        # available height
        index = segments.rindex {|s| s.min.x <= @x && @x < s.max.x }
        y1 = segments[index].start_point.y
        @available_height = @y - y1

        # Find segment with minium min.x coordinate whose y-coordinate is between y1 and @y and
        # min.x > @x, for getting the available width
        segments.select! {|s| s.min.x > @x && y1 <= s.start_point.y && s.start_point.y <= @y }
        segment = segments.min_by {|s| s.min.x }
        @available_width = segment.min.x - @x if segment
      end

      # Trims the frame's shape so that the next starting point is different.
      def trim_shape
        @x = @y = @available_width = @available_height = 0
        return if @shape.kind_of?(Geom2D::Rectangle) || !(segments = find_starting_point)

        # Just use the second top-most segment
        # TODO: not the optimal solution!
        index = segments.rindex {|s| s.start_point.y < @y }
        segment = segments[index]
        y = segment.start_point.y
        polygon = if segment.min.x == @x
                    # Trim the rectangular part from the left to the segment's length
                    Geom2D::Polygon([@x, @y], [@x, y],
                                    [@x + segment.length, y], [@x + segment.length, @y])
                  else
                    # Trim the whole slice between the two top-most segments
                    Geom2D::Polygon([left, y], [left + width, y],
                                    [left + width, @y], [left, @y])
                  end
        remove_area(polygon)
      end

      # Finds and sets the top-left point for the next region. This is always the top-most,
      # left-most vertex of the frame's shape.
      #
      # If successful, additionally sets the available width to the length of the segment containing
      # the point and returns the sorted horizontal segments except the top-most one.
      #
      # Otherwise, sets all region specific values to zero and returns +nil+.
      def find_starting_point
        segments = sorted_horizontal_segments
        if segments.empty?
          @x = @y = @available_width = @available_height = 0
          return
        end

        top_segment = segments.pop
        @x = top_segment.min.x
        @y = top_segment.start_point.y
        @available_width = top_segment.length

        segments
      end

      # Returns the horizontal segments of the frame's shape, sorted by maximum y-, then minimum
      # x-coordinate.
      def sorted_horizontal_segments
        @shape.each_segment.select(&:horizontal?).sort! do |a, b|
          if a.start_point.y == b.start_point.y
            b.start_point.x <=> a.start_point.x
          else
            a.start_point.y <=> b.start_point.y
          end
        end
      end

    end

  end
end
