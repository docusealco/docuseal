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
require 'geom2d/utils'
require 'hexapdf/utils'

module HexaPDF
  module Layout

    # The base class for all layout boxes.
    #
    # == Box Model
    #
    # HexaPDF uses the following box model:
    #
    # * Each box can specify a width and height. Padding and border are inside, the margin outside
    #   of this rectangle.
    #
    # * The #content_width and #content_height accessors can be used to get the width and height of
    #   the content box without padding and the border.
    #
    # * If width or height is set to zero, they are determined automatically during layouting.
    #
    #
    # == Subclasses
    #
    # Each subclass should only take keyword arguments on initialization so that the boxes can be
    # instantiated from the common convenience method HexaPDF::Document::Layout#box. To use this
    # facility subclasses need to be registered with the configuration option 'layout.boxes.map'.
    #
    # The methods #supports_position_flow?, #empty?, #fit_content, #split_content, and #draw_content
    # need to be customized according to the subclass's use case (also see the documentation of the
    # methods besides the information below):
    #
    # #supports_position_flow?::
    #     If the subclass supports the value :flow of the 'position' style property, this method
    #     needs to be overridden to return +true+.
    #
    #     Additionally, if a box object uses flow positioning, #fit_result.x should be set to the
    #     correct value since Frame#fit can't determine this and uses Frame#left in the absence of a
    #     set value.
    #
    # #empty?::
    #     This method should return +true+ if the subclass won't draw anything when #draw is called.
    #
    # #fit_content::
    #     This method determines whether the box fits into the available region and should set the
    #     status of #fit_result appropriately.
    #
    #     It is called from the #fit method which should not be overridden in most cases. The
    #     default implementations of both methods provide code common to all use-cases and delegates
    #     the specifics to the subclass-specific #fit_content method.
    #
    # #split_content::
    #     This method is called from #split which handles the common cases based on the status of
    #     the #fit_result. It needs to handle the case when only some part of the box fits. The
    #     method #create_split_box should be used for getting a basic cloned box.
    #
    # #draw_content::
    #     This method draws the box specific content and is called from #draw which already handles
    #     things like drawing the border and background. So #draw should usually not be overridden.
    #
    # This base class also provides various protected helper methods for use in the above methods:
    #
    # * #reserved_width, #reserved_height
    # * #reserved_width_left, #reserved_width_right, #reserved_height_top,
    #   #reserved_height_bottom
    # * #update_content_width, #update_content_height
    # * #create_split_box
    class Box

      include HexaPDF::Utils

      # Stores the result of fitting a box in a frame.
      class FitResult

        # The box that was fitted into the frame.
        attr_accessor :box

        # The frame into which the box was fitted.
        attr_accessor :frame

        # The horizontal position where the box will be drawn.
        attr_accessor :x

        # The vertical position where the box will be drawn.
        attr_accessor :y

        # The rectangle (a Geom2D::Rectangle object) that will be removed from the frame when
        # drawing the box.
        attr_accessor :mask

        # The status result of fitting the box in the frame.
        #
        # Allowed values are:
        #
        # +:failure+:: (default) Indicates fitting the box has failed.
        # +:success+:: Indicates that the box was completely fitted.
        # +:overflow+:: Indicates that only a part of the box was fitted.
        attr_reader :status

        # Initializes the result object for the given box and, optionally, frame.
        def initialize(box, frame: nil)
          @box = box
          reset(frame)
        end

        # Resets the result object.
        def reset(frame)
          @frame = frame
          @x = @y = @mask = nil
          @status = :failure
          self
        end

        # Sets the result status to success.
        def success!
          @status = :success
        end

        # Returns +true+ if fitting was successful.
        def success?
          @status == :success
        end

        # Sets the result status to overflow.
        def overflow!
          @status = :overflow
        end

        # Returns +true+ if only parts of the box were fitted.
        def overflow?
          @status == :overflow
        end

        # Sets the result status to failure.
        def failure!
          @status = :failure
        end

        # Returns +true+ if fitting was a failure.
        def failure?
          @status == :failure
        end

        # Draws the #box onto the canvas at (#x + *dx*, #y + *dy*).
        #
        # The relative offset (dx, dy) is useful when rendering results that were accumulated and
        # then need to be moved because the container holding them changes its position.
        #
        # The configuration option "debug" can be used to add visual debug output with respect to
        # box placement.
        def draw(canvas, dx: 0, dy: 0)
          return if box.height == 0 || box.width == 0
          doc = canvas.context.document
          if doc.config['debug']
            name = (frame.parent_boxes + [box]).map do |box|
              box.class.to_s.sub(/.*::/, '')
            end.join('-') << "##{box.object_id}"
            name = "#{name} (#{(x + dx).to_i},#{(y + dy).to_i}-#{mask.width.to_i}x#{mask.height.to_i})"
            ocg = doc.optional_content.ocg(name)
            canvas.optional_content(ocg) do
              canvas.translate(dx, dy) do
                canvas.fill_color("green").stroke_color("darkgreen").
                  opacity(fill_alpha: 0.1, stroke_alpha: 0.2).
                  draw(:geom2d, object: mask, path_only: true).fill_stroke
              end
            end
            page = "Page #{canvas.context.index + 1}" rescue "XObject"
            doc.optional_content.default_configuration.add_ocg_to_ui(ocg, path: ['Debug', page])
          end
          box.draw(canvas, x + dx, y + dy)
        end

      end

      # Creates a new Box object, using the provided block as drawing block (see ::new).
      #
      # If +content_box+ is +true+, the width and height are taken to mean the content width and
      # height and the style's padding and border are added to them appropriately.
      #
      # The +style+ argument defines the Style object (see Style::create for details) for the box.
      # Any additional keyword arguments have to be style properties and are applied to the style
      # object.
      def self.create(width: 0, height: 0, content_box: false, style: nil, **style_properties, &block)
        style = Style.create(style).update(**style_properties)
        if content_box
          width += style.padding.left + style.padding.right +
            style.border.width.left + style.border.width.right
          height += style.padding.top + style.padding.bottom +
            style.border.width.top + style.border.width.bottom
        end
        new(width: width, height: height, style: style, &block)
      end

      # The width of the box, including padding and/or borders.
      attr_reader :width

      # The height of the box, including padding and/or borders.
      attr_reader :height

      # The FitResult instance holding the result after a call to #fit.
      attr_reader :fit_result

      # The style to be applied.
      #
      # Only the following properties are used:
      #
      # * Style#position
      # * Style#overflow
      # * Style#background_color
      # * Style#background_alpha
      # * Style#padding
      # * Style#border
      # * Style#overlays
      # * Style#underlays
      attr_reader :style

      # Hash with custom properties. The keys should be strings and can be arbitrary.
      #
      # This can be used to store arbitrary information on boxes for later use. For example, a
      # generic style layer could use one or more custom properties for its work.
      #
      # The Box class itself uses the following properties:
      #
      # optional_content::
      #
      #       If this property is set, it needs to be an optional content group dictionary, a String
      #       defining an (optionally existing) optional content group dictionary, or an optional
      #       content membership dictionary.
      #
      #       The whole content of the box, i.e. including padding, border, background..., is
      #       wrapped with the appropriate commands so that the optional content group or membership
      #       dictionary specifies whether the content is shown or not.
      #
      #       See: HexaPDF::Type::OptionalContentProperties
      attr_reader :properties

      # :call-seq:
      #    Box.new(width: 0, height: 0, style: nil, properties: nil) {|canv, box| block} -> box
      #
      # Creates a new Box object with the given width and height that uses the provided block when
      # it is asked to draw itself on a canvas (see #draw).
      #
      # Since the final location of the box is not known beforehand, the drawing operations inside
      # the block should draw inside the rectangle (0, 0, content_width, content_height) - note that
      # the width and height of the box may not be known beforehand.
      def initialize(width: 0, height: 0, style: nil, properties: nil, &block)
        @width = @initial_width = width
        @height = @initial_height = height
        @style = Style.create(style)
        @properties = properties || {}
        @draw_block = block
        @fit_result = FitResult.new(self)
        @split_box = false
      end

      # Returns the set truthy value if this is a split box, i.e. the rest of another box after it
      # was split.
      def split_box?
        @split_box
      end

      # Returns +false+ since a basic box doesn't support the 'position' style property value :flow.
      def supports_position_flow?
        false
      end

      # The width of the content box, i.e. without padding and/or borders.
      def content_width
        width = @width - reserved_width
        width < 0 ? 0 : width
      end

      # The height of the content box, i.e. without padding and/or borders.
      def content_height
        height = @height - reserved_height
        height < 0 ? 0 : height
      end

      # Fits the box into the *frame* and returns the #fit_result.
      #
      # The arguments +available_width+ and +available_height+ are the width and height of the
      # current region of the frame, adjusted for this box. The frame itself is provided as third
      # argument.
      #
      # If the box uses flow positioning, the width is set to the frame's width and the height to
      # the remaining height in the frame. Otherwise the given available width and height are used
      # for the width and height if they were initially set to 0. Otherwise the intially specified
      # dimensions are used. The method returns early if the thus configured box already doesn't
      # fit. Otherwise, the #fit_content method is called which allows sub-classes to fit their
      # content.
      #
      # The following variables are set that may later be used during splitting or drawing:
      #
      # * (@fit_x, @fit_y): The lower-left corner of the content box where fitting was done. Can be
      #   used to adjust the drawing position in #draw_content if necessary.
      def fit(available_width, available_height, frame)
        @fit_result.reset(frame)
        position_flow = supports_position_flow? && style.position == :flow
        @width = if @initial_width > 0
                   @initial_width
                 elsif position_flow
                   frame.width
                 else
                   available_width
                 end
        @height = if @initial_height > 0
                    @initial_height
                  elsif position_flow
                    frame.y - frame.bottom
                  else
                    available_height
                  end
        return @fit_result if !position_flow && (float_compare(@width, available_width) > 0 ||
                                                 float_compare(@height, available_height) > 0 ||
                                                 @width - reserved_width < 0 ||
                                                 @height - reserved_height < 0)

        fit_content(available_width, available_height, frame)

        @fit_x = frame.x + reserved_width_left
        @fit_y = frame.y - @height + reserved_height_bottom

        @fit_result
      end

      # Tries to split the box into two, the first of which needs to fit into the current region of
      # the frame, and returns the parts as array. The method #fit needs to be called before this
      # method to correctly set-up the #fit_result.
      #
      # If the first item in the result array is not +nil+, it needs to be this box and it means
      # that even when #fit fails, a part of the box may still fit. Note that #fit should not be
      # called again before #draw on the first box since it is already fitted. If not even a part of
      # this box fits into the current region, +nil+ should be returned as the first array element.
      #
      # Possible return values:
      #
      # [self, nil]:: The box fully fits into the current region.
      # [nil, self]:: The box can't be split or no part of the box fits into the current region.
      # [self, new_box]:: A part of the box fits and a new box is returned for the rest.
      #
      # This default implementation provides the basic functionality based on the status of the
      # #fit_result that should be sufficient for most subclasses; only #split_content needs to be
      # implemented if necessary.
      def split
        case @fit_result.status
        when :overflow then (@initial_height > 0 ? [self, nil] : split_content)
        when :failure  then [nil, self]
        when :success  then [self, nil]
        end
      end

      # Draws the content of the box onto the canvas at the position (x, y).
      #
      # When +@draw_block+ is used (the block specified when creating the box), the coordinate
      # system is translated so that the origin is at the bottom left corner of the **content box**.
      #
      # Subclasses should not rely on the +@draw_block+ but implement the #draw_content method. The
      # coordinates passed to it are also modified to represent the bottom-left corner of the
      # content box but the coordinate system is not translated.
      def draw(canvas, x, y)
        if @fit_result.overflow? && @initial_height > 0 && style.overflow == :error
          raise HexaPDF::Error, "Box with limited height doesn't completely fit and " \
            "style property overflow is set to :error"
        end

        if (oc = properties['optional_content'])
          canvas.optional_content(oc)
        end

        if style.background_color? && style.background_color
          canvas.save_graphics_state do
            canvas.opacity(fill_alpha: style.background_alpha).
              fill_color(style.background_color).rectangle(x, y, width, height).fill
          end
        end

        style.underlays.draw(canvas, x, y, self) if style.underlays?
        style.border.draw(canvas, x, y, width, height) if style.border?

        draw_content(canvas, x + reserved_width_left, y + reserved_height_bottom)

        style.overlays.draw(canvas, x, y, self) if style.overlays?

        canvas.end_optional_content if oc
      end

      # Returns +true+ if no drawing operations are performed.
      def empty?
        !(@draw_block ||
          (style.background_color? && style.background_color) ||
          (style.underlays? && !style.underlays.none?) ||
          (style.border? && !style.border.none?) ||
          (style.overlays? && !style.overlays.none?))
      end

      protected

      # Returns the width that is reserved by the padding and border style properties.
      def reserved_width
        reserved_width_left + reserved_width_right
      end

      # Returns the height that is reserved by the padding and border style properties.
      def reserved_height
        reserved_height_top + reserved_height_bottom
      end

      # Returns the width that is reserved by the padding and the border style properties on the
      # left side of the box.
      def reserved_width_left
        result = 0
        result += style.padding.left if style.padding?
        result += style.border.width.left if style.border?
        result
      end

      # Returns the width that is reserved by the padding and the border style properties on the
      # right side of the box.
      def reserved_width_right
        result = 0
        result += style.padding.right if style.padding?
        result += style.border.width.right if style.border?
        result
      end

      # Returns the height that is reserved by the padding and the border style properties on the
      # top side of the box.
      def reserved_height_top
        result = 0
        result += style.padding.top if style.padding?
        result += style.border.width.top if style.border?
        result
      end

      # Returns the height that is reserved by the padding and the border style properties on the
      # bottom side of the box.
      def reserved_height_bottom
        result = 0
        result += style.padding.bottom if style.padding?
        result += style.border.width.bottom if style.border?
        result
      end

      # :call-seq:
      #   update_content_width { block }
      #
      # Updates the width of the box using the content width returned by the block.
      def update_content_width
        return if @initial_width > 0
        @width = yield + reserved_width
      end

      # :call-seq:
      #   update_content_height { block }
      #
      # Updates the height of the box using the content height returned by the block.
      def update_content_height
        return if @initial_height > 0
        @height = yield + reserved_height
      end

      # Fits the content of the box and returns whether fitting was successful.
      #
      # This is just a stub implementation that sets the #fit_result status to success. Subclasses
      # should override it to provide the box specific behaviour.
      #
      # See #fit for details.
      def fit_content(_available_width, _available_height, _frame)
        fit_result.success!
      end

      # Splits the content of the box.
      #
      # This is just a stub implementation, returning [nil, self] since we can't know how to split
      # the content when it didn't fit.
      #
      # Subclasses that support splitting content need to provide an appropriate implementation and
      # use #create_split_box to create a cloned box to supply as the second return argument.
      def split_content
        [nil, self]
      end

      # Draws the content of the box at position [x, y] which is the bottom left corner of the
      # content box.
      #
      # This implementation uses the drawing block provided on initialization, if set, to draw the
      # contents. Subclasses should override it to provide box specific behaviour.
      def draw_content(canvas, x, y)
        if @draw_block
          canvas.translate(x, y) { @draw_block.call(canvas, self) }
        end
      end

      # Creates a new box based on this one and resets the internal data back to their original
      # values.
      #
      # The variable +@split_box+ is set to +split_box_value+ (defaults to +true+) to make the new
      # box aware that it is a split box. If needed, subclasses can set the variable to other truthy
      # values to convey more meaning.
      #
      # This method should be used by subclasses to create their split box.
      def create_split_box(split_box_value: true)
        box = clone
        box.instance_variable_set(:@width, @initial_width)
        box.instance_variable_set(:@height, @initial_height)
        box.instance_variable_set(:@fit_result, FitResult.new(box))
        box.instance_variable_set(:@split_box, split_box_value)
        box
      end

    end

  end
end
