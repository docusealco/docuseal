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
require 'hexapdf/layout/text_box'
require 'hexapdf/layout/text_fragment'

module HexaPDF
  module Layout

    # A ListBox arranges its children as unordered or ordered list items.
    #
    # The indentation of the contents from the left (#content_indentation) as well as the marker
    # type of the items (#marker_type) can be specified. Additionally, it is possible to define the
    # start number for ordered lists (#start_number) and the amount of spacing between items
    # (#item_spacing).
    #
    # If the list box has padding and/or borders specified, they are handled like with any other
    # box. This means they are around all items and their contents and are not used separately for
    # each item.
    #
    # The following style properties are used (additionally to those used by the parent class):
    #
    # Style#position::
    #    If this is set to :flow, the frames created for the list items will take the shape of the
    #    frame into account. This also means that the +available_width+ and +available_height+
    #    arguments are ignored.
    class ListBox < Box

      # Stores the information when fitting an item of the list box.
      ItemResult = Struct.new(:box_fitter, :height, :marker, :marker_pos_x)

      # The child boxes of this ListBox. They need to be finalized before #fit is called.
      attr_reader :children

      # The type of list item marker to be rendered before the list item contents.
      #
      # The following values are supported (and :disc is the default):
      #
      # :disc::
      #
      #     Draws a filled disc for the items of the unordered list.
      #
      #       #>pdf-composer100
      #       composer.box(:list, marker_type: :disc) do |list|
      #         list.lorem_ipsum_box(sentences: 1)
      #       end
      #
      # :circle::
      #
      #     Draws an unfilled circle for the items of the unordered list.
      #
      #       #>pdf-composer100
      #       composer.box(:list, marker_type: :circle) do |list|
      #         list.lorem_ipsum_box(sentences: 1)
      #       end
      #
      # :square::
      #
      #     Draws a filled square for the items of the unordered list.
      #
      #       #>pdf-composer100
      #       composer.box(:list, marker_type: :square) do |list|
      #         list.lorem_ipsum_box(sentences: 1)
      #       end
      #
      # :decimal::
      #
      #     Draws the numbers in decimal form, starting from #start_number) for the items of
      #     the ordered list.
      #
      #       #>pdf-composer100
      #       composer.box(:list, marker_type: :decimal) do |list|
      #         5.times { list.lorem_ipsum_box(sentences: 1) }
      #       end
      #
      # custom marker::
      #
      #    Additionally, it is possible to specify an object as value that responds to
      #    #call(document, box, index) where +document+ is the HexaPDF::Document, +box+ is the list
      #    box, and +index+ is the current item index, starting at 0. The return value needs to be a
      #    Box object which is then fit into the content indentation area and drawn.
      #
      #      #>pdf-composer100
      #      image = lambda do |document, box, index|
      #        document.layout.image_box(machu_picchu, height: box.style.font_size)
      #      end
      #      composer.box(:list, marker_type: image) do |list|
      #        2.times { list.lorem_ipsum_box(sentences: 1) }
      #      end
      attr_reader :marker_type

      # The start number when using a #marker_type that represents an ordered list.
      #
      # The default value for this is 1.
      #
      # Example:
      #
      #   #>pdf-composer100
      #   composer.box(:list, marker_type: :decimal, start_number: 3) do |list|
      #     2.times { list.lorem_ipsum_box(sentences: 1) }
      #   end
      attr_reader :start_number

      # The indentation of the list content in PDF points. The item marker will be inside this
      # indentation.
      #
      # The default value is two times the font size.
      #
      # Example:
      #
      #   #>pdf-composer100
      #   composer.box(:list) {|list| list.lorem_ipsum_box(sentences: 1) }
      #   composer.box(:list, content_indentation: 50) do |list|
      #     list.lorem_ipsum_box(sentences: 1)
      #   end
      attr_reader :content_indentation

      # The spacing between two consecutive list items.
      #
      # The default value is zero.
      #
      # Example:
      #
      #   #>pdf-composer
      #   composer.box(:list, item_spacing: 10) do |list|
      #     3.times { list.lorem_ipsum_box(sentences: 1) }
      #   end
      attr_reader :item_spacing

      # Creates a new ListBox object for the given child boxes in +children+.
      def initialize(children: [], marker_type: :disc, content_indentation: nil, start_number: 1,
                     item_spacing: 0, **kwargs)
        super(**kwargs)
        @children = children
        @marker_type = marker_type
        @content_indentation = content_indentation || 2 * style.font_size
        @start_number = start_number
        @item_spacing = item_spacing

        @results = nil
        @results_item_marker_x = nil
      end

      # Returns +true+ as the 'position' style property value :flow is supported.
      def supports_position_flow?
        true
      end

      # Returns +true+ if no box was fitted into the list box.
      def empty?
        super && (!@results || @results.all? {|result| result.box_fitter.fit_results.empty? })
      end

      private

      # Fits the list box into the current region of the frame.
      def fit_content(_available_width, _available_height, frame)
        width = @width - reserved_width
        height = @height - reserved_height
        left = (style.position == :flow ? frame.left : frame.x) + reserved_width_left
        top = frame.y - reserved_height_top

        # The left side of the frame of an item is always indented, regardless of style.position
        item_frame_left = left + @content_indentation
        item_frame_width = width - @content_indentation

        # We can remove the content indentation for a rectangle by just modifying left and width
        unless style.position == :flow
          left = item_frame_left
          width = item_frame_width
        end

        @results = []

        @children.each_with_index do |child, index|
          item_result = ItemResult.new

          shape = Geom2D::Polygon([left, top - height],
                                  [left + width, top - height],
                                  [left + width, top],
                                  [left, top])
          if style.position == :flow
            shape = Geom2D::Algorithms::PolygonOperation.run(frame.shape, shape, :intersection)
            remove_indent_from_frame_shape(shape) unless shape.polygons.empty?
          end

          item_frame = frame.child_frame(item_frame_left, top - height, item_frame_width, height,
                                         shape: shape, box: self)

          if index != 0 || !split_box? || @split_box == :show_first_marker
            box = item_marker_box(frame.document, index)
            marker_frame = frame.child_frame(0, 0, content_indentation, height, box: self)
            break unless box.fit(content_indentation, height, marker_frame)
            item_result.marker = box
            item_result.marker_pos_x = item_frame.x - content_indentation
            item_result.height = box.height
          end

          box_fitter = BoxFitter.new([item_frame])
          Array(child).each {|ibox| box_fitter.fit(ibox) }
          item_result.box_fitter = box_fitter
          item_result.height = [item_result.height.to_i, box_fitter.content_heights[0]].max
          @results << item_result unless box_fitter.fit_results.empty?

          top -= item_result.height + item_spacing
          height -= item_result.height + item_spacing

          break if !box_fitter.success? || height <= 0
        end

        update_content_height { @results.sum(&:height) + (@results.count - 1) * item_spacing }

        if @results.size == @children.size && @results.all? {|r| r.box_fitter.success? }
          fit_result.success!
        elsif !@results.empty? && !@results[0].box_fitter.fit_results.empty?
          fit_result.overflow!
        end
      end

      # Removes the +content_indentation+ from the left side of the given shape (a Geom2D::PolygonSet).
      def remove_indent_from_frame_shape(shape)
        polygon_index = 0
        data = []

        # Determine the lower-left-most and upper-left-most vertices and their indices, together
        # with the polygon index that holds them and the direction wrt to the indices from
        # upper-left-most to lower-left-most.
        shape.polygons.each_with_index do |polygon, pindex|
          lower_vertex = upper_vertex = polygon[0]
          lower_index = upper_index = 0
          1.upto(polygon.nr_of_vertices - 1) do |i|
            v = polygon[i]
            if v.y < lower_vertex.y || (v.y == lower_vertex.y && v.x <= lower_vertex.x)
              lower_vertex = v
              lower_index = i
            elsif v.y > upper_vertex.y || (v.y == upper_vertex.y && v.x <= upper_vertex.x)
              upper_vertex = v
              upper_index = i
            end
          end
          direction = upper_vertex.x == polygon[(upper_index + 1) % polygon.nr_of_vertices].x ? 1 : -1
          if data.empty? || data[0].x > lower_vertex.x
            polygon_index = pindex
            data = [lower_vertex, lower_index, upper_vertex, upper_index, direction]
          end
        end

        # Now we have all the data to remove the indentation on the left side of the polygon. This
        # is done by shifting all vertices between and including the lower-left-most and
        # upper-left-most vertices to the right.
        vertices = shape.polygons[polygon_index].to_a
        point = data[2]
        index = data[3]
        while point != data[0]
          vertices[index] = Geom2D::Point(point.x + content_indentation, point.y)
          index = (index + data[4]) % vertices.size
          point = vertices[index]
        end
        vertices[data[1]] = Geom2D::Point(data[0].x + content_indentation, data[0].y)

        shape.polygons[polygon_index] = Geom2D::Polygon(*vertices)
      end

      # Splits the content of the list box. This method is called from Box#split.
      def split_content
        remaining_boxes = @results[-1].box_fitter.remaining_boxes
        first_is_split_box = !remaining_boxes.empty?
        children = (remaining_boxes.empty? ? [] : [remaining_boxes]) + @children[@results.size..-1]

        box = create_split_box(split_box_value: first_is_split_box ? :hide_first_marker : :show_first_marker)
        box.instance_variable_set(:@children, children)
        box.instance_variable_set(:@start_number,
                                  @start_number + @results.size + (first_is_split_box ? -1 : 0))
        box.instance_variable_set(:@results, [])

        [self, box]
      end

      # Creates a box for the item marker at the given item index, using #item_style to decide on
      # its contents.
      def item_marker_box(document, index)
        return @marker_type.call(document, self, index) if @marker_type.kind_of?(Proc)

        unless (items = @item_marker_items)
          marker_style = {
            font_size: style.font_size || 10,
            fill_color: style.fill_color,
          }
          marker_style[:font] = style.font if style.font?
          items = case @marker_type
                  when :disc
                    document.layout.text_fragments("•", style: marker_style)
                  when :circle
                    document.layout.text_fragments("❍", style: marker_style,
                                                   font_size: style.font_size / 2.0,
                                                   text_rise: -style.font_size / 1.8)
                  when :square
                    document.layout.text_fragments("■", style: marker_style,
                                                   font_size: style.font_size / 2.0,
                                                   text_rise: -style.font_size / 1.8)
                  when :decimal
                    text = (@start_number + index).to_s << "."
                    document.layout.text_fragments(text, style: marker_style)
                  else
                    raise HexaPDF::Error, "Unknown list marker type #{@marker_type.inspect}"
                  end
          @item_marker_items = items unless @marker_type == :decimal
        end
        TextBox.new(items: items, style: {text_align: :right, padding: [0, 5, 0, 0]})
      end

      # Draws the list items onto the canvas at position [x, y].
      def draw_content(canvas, x, y)
        translate = style.position != :flow && (x != @fit_x || y != @fit_y)

        canvas.save_graphics_state.translate(x - @fit_x, y - @fit_y) if translate

        @results.each do |item_result|
          box_fitter = item_result.box_fitter
          if (marker = item_result.marker)
            marker.draw(canvas, item_result.marker_pos_x,
                        box_fitter.frames[0].bottom + box_fitter.frames[0].height - marker.height)
          end
          box_fitter.fit_results.each {|result| result.draw(canvas) }
        end

        canvas.restore_graphics_state if translate
      end

    end

  end
end
