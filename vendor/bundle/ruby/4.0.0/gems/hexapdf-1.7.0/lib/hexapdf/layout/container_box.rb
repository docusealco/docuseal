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
require 'hexapdf/layout/box_fitter'
require 'hexapdf/layout/frame'

module HexaPDF
  module Layout

    # This is a simple container box for laying out a number of boxes together. It is registered
    # under the :container name.
    #
    # The box does not support the value :flow for the style property position, so the child boxes
    # are laid out in the current region only.
    #
    # If #splitable is +false+ (the default) and if any box doesn't fit, the whole container doesn't
    # fit.
    #
    # By default the child boxes are laid out from top to bottom. By appropriately setting the style
    # properties 'mask_mode', 'align' and 'valign', it is possible to lay out the children bottom to
    # top, left to right, or right to left:
    #
    # * The standard top-to-bottom layout:
    #
    #     #>pdf-composer100
    #     composer.container do |container|
    #       container.box(height: 20, style: {background_color: "hp-blue-dark"})
    #       container.box(height: 20, style: {background_color: "hp-blue"})
    #       container.box(height: 20, style: {background_color: "hp-blue-light"})
    #     end
    #
    # * The bottom-to-top layout (using valign = :bottom to fill up from the bottom and mask_mode =
    #   :fill_horizontal to only remove the area to the left and right of the box):
    #
    #     #>pdf-composer100
    #     composer.container do |container|
    #       container.box(height: 20, style: {background_color: "hp-blue-dark",
    #                                         mask_mode: :fill_horizontal, valign: :bottom})
    #       container.box(height: 20, style: {background_color: "hp-blue",
    #                                         mask_mode: :fill_horizontal, valign: :bottom})
    #       container.box(height: 20, style: {background_color: "hp-blue-light",
    #                                         mask_mode: :fill_horizontal, valign: :bottom})
    #     end
    #
    # * The left-to-right layout (using mask_mode = :fill_vertical to fill the area to the top and
    #   bottom of the box):
    #
    #     #>pdf-composer100
    #     composer.container do |container|
    #       container.box(width: 20, style: {background_color: "hp-blue-dark",
    #                                        mask_mode: :fill_vertical})
    #       container.box(width: 20, style: {background_color: "hp-blue",
    #                                        mask_mode: :fill_vertical})
    #       container.box(width: 20, style: {background_color: "hp-blue-light",
    #                                        mask_mode: :fill_vertical})
    #     end
    #
    # * The right-to-left layout (using align = :right to fill up from the right and mask_mode =
    #   :fill_vertical to fill the area to the top and bottom of the box):
    #
    #     #>pdf-composer100
    #     composer.container do |container|
    #       container.box(width: 20, style: {background_color: "hp-blue-dark",
    #                                        mask_mode: :fill_vertical, align: :right})
    #       container.box(width: 20, style: {background_color: "hp-blue",
    #                                        mask_mode: :fill_vertical, align: :right})
    #       container.box(width: 20, style: {background_color: "hp-blue-light",
    #                                        mask_mode: :fill_vertical, align: :right})
    #     end
    class ContainerBox < Box

      # The child boxes of this ContainerBox. They need to be finalized before #fit is called.
      attr_reader :children

      # Specifies whether the container box allows splitting its content.
      #
      # If splitting is not allowed (the default), all child boxes must fit together into one
      # region.
      #
      # Examples:
      #
      #   # Fails with an error because the content of the container box is too big
      #   composer.column do |col|
      #     col.container do |container|
      #       container.lorem_ipsum
      #     end
      #   end
      #
      # ---
      #
      #   #>pdf-composer
      #   composer.column do |col|
      #     col.container(splitable: true) do |container|
      #       container.lorem_ipsum
      #     end
      #   end
      attr_reader :splitable

      # Creates a new container box, optionally accepting an array of child boxes.
      #
      # Example:
      #
      #   #>pdf-composer100
      #   composer.text("A paragraph here")
      #   composer.container(height: 40, style: {border: {width: 1}, padding: 5,
      #                                          align: :center}) do |container|
      #     container.text("Some", mask_mode: :fill_vertical)
      #     container.text("text", mask_mode: :fill_vertical, valign: :center)
      #     container.text("here", mask_mode: :fill_vertical, valign: :bottom)
      #   end
      #   composer.text("Another paragraph")
      def initialize(children: [], splitable: false, **kwargs)
        super(**kwargs)
        @children = children
        @splitable = splitable
      end

      # Returns +true+ if no box was fitted into the container.
      def empty?
        super && (!@box_fitter || @box_fitter.fit_results.empty?)
      end

      private

      # Fits the children into the container.
      def fit_content(_available_width, _available_height, frame)
        my_frame = frame.child_frame(frame.x + reserved_width_left,
                                     frame.y - @height + reserved_height_bottom,
                                     content_width, content_height, box: self)
        @box_fitter = BoxFitter.new([my_frame])
        children.each {|box| @box_fitter.fit(box) }

        if @box_fitter.success?
          update_content_width do
            result = @box_fitter.fit_results.max_by {|r| r.mask.x + r.mask.width }
            children.empty? ? 0 : result.mask.x + result.mask.width - my_frame.left
          end
          update_content_height { @box_fitter.content_heights.max }
          fit_result.success!
        elsif !@box_fitter.fit_results.empty? && @splitable
          fit_result.overflow!
        end
      end

      # Splits the content of the container box. This method is called from Box#split.
      def split_content
        box = create_split_box
        box.instance_variable_set(:@children, @box_fitter.remaining_boxes)
        [self, box]
      end

      # Draws the children onto the canvas at position [x, y].
      def draw_content(canvas, x, y)
        dx = x - @fit_x
        dy = y - @fit_y
        @box_fitter.fit_results.each {|result| result.draw(canvas, dx: dx, dy: dy) }
      end

    end

  end
end
