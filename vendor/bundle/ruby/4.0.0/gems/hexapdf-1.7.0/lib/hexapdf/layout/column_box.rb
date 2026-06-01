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

module HexaPDF
  module Layout

    # A ColumnBox arranges boxes in one or more columns.
    #
    # The number and width of the columns as well as the size of the gap between the columns can be
    # modified. Additionally, the contents can either fill the columns one after the other or the
    # columns can be made equally high.
    #
    # If the column box has padding and/or borders specified, they are handled like with any other
    # box. This means they are around all columns and their contents and are not used separately for
    # each column.
    #
    # The following style properties are used (additionally to those used by the parent class):
    #
    # Style#position::
    #    If this is set to :flow, the frames created for the columns will take the shape of the
    #    frame into account. This also means that the +available_width+ and +available_height+
    #    arguments are ignored.
    class ColumnBox < Box

      # The child boxes of this ColumnBox. They need to be finalized before #fit is called.
      attr_reader :children

      # The columns definition.
      #
      # If the value is an array, it needs to contain the widths of the columns. The size of the
      # array determines the number of columns. Otherwise, if the value is an integer, the value
      # defines the number of equally sized columns, i.e. a value of +N+ is equal to [-1]*N.
      #
      # If a negative integer is used for the width, the column is auto-sized. Such columns split
      # the remaining width (after substracting the widths of the fixed columns) proportionally
      # among them. For example, if the definition is [-1, -2, -2], the first column is a fifth of
      # the width and the other columns are each two fifth of the width.
      #
      # Examples:
      #
      #   #>pdf-composer
      #   composer.box(:column, columns: 2, gaps: 10,
      #                children: [composer.document.layout.lorem_ipsum_box])
      #
      # ---
      #
      #   #>pdf-composer
      #   composer.box(:column, columns: [50, -2, -1], gaps: [10, 5],
      #                children: [composer.document.layout.lorem_ipsum_box])
      attr_reader :columns

      # The size of the gaps between the columns.
      #
      # This is an array containing the width of the gaps. If there are more gaps than numbers in
      # the array, the array is cycled.
      #
      # Examples: see #columns
      attr_reader :gaps

      # Determines whether the columns should all be equally high or not.
      #
      # Examples:
      #
      #   #>pdf-composer
      #   composer.box(:column, children: [composer.document.layout.lorem_ipsum_box])
      #
      # ---
      #
      #   #>pdf-composer
      #   composer.box(:column, equal_height: false,
      #                children: [composer.document.layout.lorem_ipsum_box])
      attr_reader :equal_height

      # Creates a new ColumnBox object for the given child boxes in +children+.
      #
      # +columns+::
      #
      #     Can either simply integer specify the number of columns or be a full column definition
      #     (see #columns for details).
      #
      # +gaps+::
      #     Can either be a simply integer specifying the width between two columns or a full gap
      #     definition (see #gap for details).
      #
      # +equal_height+::
      #     If +true+, the #fit method tries to balance the columns in terms of their height.
      #     Otherwise the columns are filled from the left.
      def initialize(children: [], columns: 2, gaps: 36, equal_height: true, **kwargs)
        super(**kwargs)
        @children = children
        @columns = (columns.kind_of?(Array) ? columns : [-1] * columns)
        @gaps = (gaps.kind_of?(Array) ? gaps : [gaps])
        @equal_height = equal_height
      end

      # Returns +true+ as the 'position' style property value :flow is supported.
      def supports_position_flow?
        true
      end

      # Returns +true+ if no box was fitted into the columns.
      def empty?
        super && (!@box_fitter || @box_fitter.fit_results.empty?)
      end

      private

      # Fits the column box into the current region of the frame.
      #
      def fit_content(_available_width, _available_height, frame)
        initial_fit_successful = (@equal_height && @columns.size > 1 ? nil : false)
        tries = 0
        width = @width - reserved_width
        height = @height - reserved_height

        columns = calculate_columns(width)
        return if columns.empty?

        left = (style.position == :flow ? frame.left : frame.x) + reserved_width_left
        top = frame.y - reserved_height_top
        successful_height = height
        unsuccessful_height = 0

        while true
          @box_fitter = BoxFitter.new

          columns.each do |col_x, column_width|
            column_left = left + col_x
            column_bottom = top - height
            if style.position == :flow
              rect = Geom2D::Polygon([column_left, column_bottom],
                                     [column_left + column_width, column_bottom],
                                     [column_left + column_width, column_bottom + height],
                                     [column_left, column_bottom + height])
              shape = Geom2D::Algorithms::PolygonOperation.run(frame.shape, rect, :intersection)
            end
            column_frame = frame.child_frame(column_left, column_bottom, column_width, height,
                                             shape: shape, box: self)
            @box_fitter << column_frame
          end

          children.each {|box| @box_fitter.fit(box) }

          fit_successful = @box_fitter.success?
          initial_fit_successful = fit_successful if initial_fit_successful.nil?

          if fit_successful
            successful_height = height if successful_height > height
          elsif unsuccessful_height < height
            unsuccessful_height = height
          end

          break if !initial_fit_successful || tries > 40 ||
            (fit_successful && successful_height - unsuccessful_height < 10)

          height = if successful_height - unsuccessful_height <= 5
                     successful_height
                   else
                     (successful_height + unsuccessful_height) / 2.0
                   end
          tries += 1
        end

        update_content_width { columns[-1].sum }
        update_content_height { @box_fitter.content_heights.max }

        if @box_fitter.success?
          fit_result.success!
        elsif !@box_fitter.fit_results.empty?
          fit_result.overflow!
        end
      end

      # Calculates the x-coordinates and widths of all columns based on the given total available
      # width.
      #
      # If it is not possible to fit all columns into the given +width+, an empty array is returned.
      def calculate_columns(width)
        number_of_columns = @columns.size
        gaps = @gaps.cycle.take(number_of_columns - 1)
        fixed_width, variable_width = @columns.partition(&:positive?).map {|c| c.sum(&:abs) }
        rest_width = width - fixed_width - gaps.sum
        return [] if rest_width <= 0

        variable_width_unit = rest_width / variable_width.to_f
        position = 0
        @columns.map.with_index do |column, index|
          result = if column > 0
                     [position, column]
                   else
                     [position, column.abs * variable_width_unit]
                   end
          position += result[1] + (gaps[index] || 0)
          result
        end
      end

      # Splits the content of the column box. This method is called from Box#split.
      def split_content
        box = create_split_box
        box.instance_variable_set(:@children, @box_fitter.remaining_boxes)
        [self, box]
      end

      # Draws the child boxes onto the canvas at position [x, y].
      def draw_content(canvas, x, y)
        if style.position != :flow && (x != @fit_x || y != @fit_y)
          canvas.translate(x - @fit_x, y - @fit_y) do
            @box_fitter.fit_results.each {|result| result.draw(canvas) }
          end
        else
          @box_fitter.fit_results.each {|result| result.draw(canvas) }
        end
      end

    end

  end
end
