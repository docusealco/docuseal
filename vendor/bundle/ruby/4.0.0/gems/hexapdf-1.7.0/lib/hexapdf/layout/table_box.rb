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
require 'hexapdf/layout/frame'

module HexaPDF
  module Layout

    # A TableBox allows placing boxes in a table.
    #
    # A table box instance can be fit into a rectangular area. The widths of the columns is
    # determined by the #column_widths definition. This means that there is no auto-sizing
    # supported.
    #
    # If some rows don't fit into the provided area, the table is split. The style of the original
    # table is also applied to the split box.
    #
    #
    # == Table Cell
    #
    # Each table cell is a Box instance and can have an associated style, e.g. for creating borders
    # around the cell contents. It is also possible to create cells that span more than one row or
    # column. By default a cell has a solid, black, 1pt border and a padding of 5pt on all sides.
    #
    # It is important to note that the drawing of cell borders (just the drawing, size calculations
    # are done as usual) are handled differently from standard box borders. While standard box
    # borders are drawn inside the box, cell borders are drawn on the bounds of the box. This means
    # that, visually, the borders of adjoining cells overlap, with the borders of cells to the right
    # and bottom being on top.
    #
    # To make sure that the cell borders are not outside of the table's bounds, the left and top
    # border widths of the top-left cell and the right and bottom border widths of the bottom-right
    # cell are taken into account when calculating the available space.
    #
    #
    # == Examples
    #
    # Let's start with a basic table:
    #
    #  #>pdf-composer
    #  cells = [[layout.text('A'), layout.text('B')],
    #           [layout.text('C'), layout.text('D')]]
    #  composer.table(cells)
    #
    # The HexaPDF::Document::Layout#table_box method accepts the cells as positional argument
    # instead of as keyword argument but all other arguments of ::new work the same.
    #
    # While the table box itself only allows box instances as cell contents, the layout helper
    # method also allows text which it transforms to text boxes. So this is the same as the above:
    #
    #  #>pdf-composer
    #  composer.table([['A', 'B'], ['C', 'D']])
    #
    # Each cell can hold zero or more boxes:
    #
    #  #>pdf-composer
    #  cells = [[[layout.text('A'), layout.image(machu_picchu, height: 40)], layout.text('B')],
    #           [nil, layout.text('D')]]
    #  composer.table(cells)
    #
    # The style of the cells can be customized, e.g. to avoid drawing borders:
    #
    #  #>pdf-composer
    #  cells = [[layout.text('A'), layout.text('B')],
    #           [layout.text('C'), layout.text('D')]]
    #  composer.table(cells, cell_style: {border: {width: 0}})
    #
    # If the table doesn't fit completely, it is automatically split (in this case, the last row
    # gets moved to the second column):
    #
    #  #>pdf-composer
    #  cells = [[layout.text('A'), layout.text('B')],
    #           [layout.text('C'), layout.text('D')],
    #           [layout.text('E'), layout.text('F')]]
    #  composer.column(height: 50) {|col| col.table(cells) }
    #
    # It is also possible to use row and column spans:
    #
    #  #>pdf-composer
    #  cells = [[{content: layout.text('A'), col_span: 2}, {content: layout.text("B\nB\nB"), row_span: 2}],
    #           [{content: layout.text('C'), col_span: 2, row_span: 2}],
    #           [layout.text('D')]]
    #  composer.table(cells)
    #
    # Each table can have header rows and footer rows which are shown for all split parts:
    #
    #  #>pdf-composer
    #  header = lambda {|tb| [[{content: layout.text('Header', text_align: :center), col_span: 2}]] }
    #  footer = lambda {|tb| [[layout.text('left'), layout.text('right', text_align: :right)]] }
    #  cells = [[layout.text('A'), layout.text('B')],
    #           [layout.text('C'), layout.text('D')],
    #           [layout.text('E'), layout.text('F')]]
    #  composer.column(height: 90) {|col| col.table(cells, header: header, footer: footer) }
    #
    # While the width of a cell is determined by the #column_widths array, the height is
    # automatically determined during fitting of the content. However, it is also possible to use a
    # fixed height (only if the actual content is smaller or equal than it):
    #
    #  #>pdf-composer
    #  cells = [[{content: layout.text('A'), min_height: 5}, layout.text('B')],
    #           [{content: layout.text('C'), min_height: 40}, layout.text('D')]]
    #  composer.table(cells)
    #
    # The cells can be styled using a callable object for more complex styling:
    #
    #  #>pdf-composer
    #  cells = [[layout.text('A'), layout.text('B')],
    #           [layout.text('C'), layout.text('D')]]
    #  block = lambda do |cell|
    #    cell.style.background_color =
    #      (cell.row == 0 && cell.column == 0 ? 'ffffaa' : 'ffffee')
    #  end
    #  composer.table(cells, cell_style: block)
    class TableBox < Box

      # Represents a single cell of the table.
      #
      # A cell is a container box that fits and draws its children with a BoxFitter. Its dimensions
      # (width and height) are not determined by its children but by the table layout algorithm.
      # Furthermore, its style can be used for drawing e.g. a cell border.
      #
      # Cell borders work similar to the separated borders model of CSS, i.e. each cell has its own
      # borders that do not overlap.
      class Cell < Box

        # The x-coordinate of the cell's top-left corner.
        #
        # The coordinate is relative to the table's content rectangle, with positive x-axis going to
        # the right and positive y-axis going to the bottom.
        #
        # This value is set by the parent Cells object during fitting and may therefore only be
        # relied on afterwards.
        attr_accessor :left

        # The y-coordinate of the cell's top-left corner.
        #
        # The coordinate is relative to the table's content rectangle, with positive x-axis going to
        # the right and positive y-axis going to the bottom.
        #
        # This value is set by the parent Cells object during fitting and may therefore only be
        # relied on afterwards.
        attr_accessor :top

        # The preferred width of the cell, determined during #fit.
        attr_reader :preferred_width

        # The preferred height of the cell, determined during #fit.
        attr_reader :preferred_height

        # The 0-based row number of the cell.
        attr_reader :row

        # The 0-based column number of the cell.
        attr_reader :column

        # The number of rows this cell spans.
        attr_reader :row_span

        # The number of columns this cell spans.
        attr_reader :col_span

        # The boxes to layout inside this cell.
        #
        # This may either be +nil+ (if the cell has no content), a single Box instance or an array
        # of Box instances.
        attr_accessor :children

        # Creates a new Cell instance.
        def initialize(row:, column:, children: nil, min_height: nil, row_span: nil, col_span: nil, **kwargs)
          super(**kwargs, width: 0, height: 0)
          @children = children
          @row = row
          @column = column
          @row_span = row_span || 1
          @col_span = col_span || 1
          @min_height = min_height
          style.border.width.set(1) unless style.border?
          style.border.draw_on_bounds = true
          style.padding.set(5) unless style.padding?
        end

        # Returns +true+ if the cell has no content.
        def empty?
          super && (!@fit_results || @fit_results.empty?)
        end

        # Updates the height of the box to the given value.
        #
        # The +height+ has to be greater than or equal to the fitted height.
        def update_height(height)
          if height < @height
            raise HexaPDF::Error, "Given height needs to be at least as big as fitted height"
          end
          @height = height
        end

        # :nodoc:
        def inspect
          "<Cell (#{row},#{column}) #{row_span}x#{col_span} #{Array(children).map(&:class)}>"
        end

        private

        # Fits the children of the table cell into the given rectangular area.
        def fit_content(available_width, available_height, frame)
          width = available_width - reserved_width
          height = @used_height = available_height - reserved_height
          return if width <= 0 || height <= 0

          frame = frame.child_frame(0, 0, width, height, box: self)
          case children
          when Box
            child_result = frame.fit(children)
            if child_result.success?
              @preferred_width = child_result.x + child_result.box.width + reserved_width
              @height = @preferred_height = child_result.box.height + reserved_height
              @fit_results = [child_result]
              fit_result.success!
            end
          when Array
            box_fitter = BoxFitter.new([frame])
            children.each {|box| box_fitter.fit(box) }
            if box_fitter.success?
              max_x_result = box_fitter.fit_results.max_by {|result| result.x + result.box.width }
              @preferred_width = max_x_result.x + max_x_result.box.width + reserved_width
              @height = @preferred_height = box_fitter.content_heights[0] + reserved_height
              @fit_results = box_fitter.fit_results
              fit_result.success!
            end
          else
            @preferred_width = reserved_width
            @height = @preferred_height = reserved_height
            @fit_results = []
            fit_result.success!
          end

          if @min_height && @height < @min_height
            @height = @preferred_height = @min_height
            fit_result.failure! if available_height < @height
          end
        end

        # Draws the content of the cell.
        def draw_content(canvas, x, y)
          return if @fit_results.empty?

          # available_width is always equal to content_width but we need to adjust for the
          # difference in the y direction between fitting and drawing
          y -= (@used_height - content_height)
          @fit_results.each {|fit_result| fit_result.draw(canvas, dx: x, dy: y) }
        end

      end

      # Represents the cells of a TableBox.
      #
      # This class is a wrapper around an array of arrays and provides some utility methods for
      # managing and styling the cells.
      #
      # == Table data transformation into correct form
      #
      # One of the main purposes of this class is to transform the cell data provided on
      # initialization into the representation a TableBox instance can work with.
      #
      # The +data+ argument for ::new is an array of arrays representing the rows of the table. Each
      # row array may contain one of the following items:
      #
      # * A single Box instance defining the content of the cell.
      #
      # * An array of Box instances defining the content of the cell.
      #
      # * A hash which defines the content of the cell as well as, optionally, additional
      #   information through the following keys:
      #
      #   +:content+:: The content for the cell. This may be a single Box or an array of Box
      #                instances.
      #
      #   +:row_span+:: An integer specifying the number of rows this cell should span.
      #
      #   +:col_span+:: An integer specifying the number of columsn this cell should span.
      #
      #   +:min_height+:: A number specifying the minimum height of the table cell.
      #
      #   +:properties+:: A hash of properties (see Box#properties) to be set on the cell itself.
      #
      #   All other key-value pairs are taken to be cell styling information (like
      #   +:background_color+) and assigned to the cell style.
      #
      # Additionally, the first item in the +data+ argument is treated specially if it is not an
      # array:
      #
      # * If it is a hash, it is assumed to be style properties to be set on all created cell
      #   instances.
      #
      # * If it is a callable object, it needs to accept a cell as argument and is called for all
      #   created cell instances.
      #
      # Any properties or styling information retrieved from the respective item in +data+ takes
      # precedence over the above globally specified information.
      #
      # Here is an example input data array:
      #
      #  data = [[box1, {col_span: 2, content: box2}, box3],
      #          [box4, box5, {col_span: 2, row_span: 2, content: [box6.1, box6.2]}],
      #          [box7, box8]]
      #
      # And this is what the table will look like:
      #
      #  | box1 | box2         | box 3 |
      #  | box4 | box5 | box6.1 box6.2 |
      #  | box7 | box8 |               |
      class Cells

        # Creates a new Cells instance with the given +data+ which cannot be changed afterwards.
        #
        # The optional +cell_style+ argument can either be a hash of style properties to be assigned
        # to every cell or a block accepting a cell for more control over e.g. style assignment. If
        # the +data+ has such a cell style as its first item, the +cell_style+ argument is not used.
        #
        # See the class documentation for details on the +data+ argument.
        def initialize(data, cell_style: nil)
          @cells = []
          @number_of_columns = 0
          assign_data(data, cell_style)
        end

        # Returns the cell (a Cell instance) in the given row and column.
        #
        # Note that the same cell instance may be returned for different (row, column) arguments if
        # the cell spans more than one row and/or column.
        def [](row, column)
          @cells[row]&.[](column)
        end

        # Returns the number of rows.
        def number_of_rows
          @cells.size
        end

        # Returns the number of columns.
        def number_of_columns
          @number_of_columns
        end

        # Iterates over each row.
        def each_row(&block)
          @cells.each(&block)
        end

        # Applies the given style properties to all cells and optionally yields all cells for more
        # complex customization.
        def style(**properties, &block)
          @cells.each do |columns|
            columns.each do |cell|
              cell.style.update(**properties)
              block&.call(cell)
            end
          end
        end

        # Fits all rows starting from +start_row+ into an area with the given +available_height+,
        # using the column information in +column_info+. Returns the used height as well as the row
        # index of the last row that fit (which may be -1 if no row fits).
        #
        # The +column_info+ argument needs to be an array of arrays of the form [x_pos, width]
        # containing the horizontal positions and widths of each column.
        #
        # The +frame+ argument is further handed down to the Cell instances for fitting.
        #
        # The fitting of a cell is done through the Cell#fit method which stores the result in the
        # cell itself. Furthermore, Cell#left and Cell#top are also assigned correctly.
        def fit_rows(start_row, available_height, column_info, frame)
          height = available_height
          last_fitted_row_index = -1
          row_heights = {}
          zero_height_rows = {}
          row_spans = []

          @cells[start_row..-1].each.with_index(start_row) do |columns, row_index|
            # 1. Fit all columns of the row and record the max height of all non-row-span cells. If
            #    a row has zero height (usually because it only has row-span cells), record that
            #    information. Additionally store all cells with row-spans.
            row_fit = true
            row_height = 0
            columns.each_with_index do |cell, col_index|
              next if cell.row != row_index || cell.column != col_index
              available_cell_width = if cell.col_span > 1
                                       column_info[cell.column, cell.col_span].map(&:last).sum
                                     else
                                       column_info[cell.column].last
                                     end
              unless cell.fit(available_cell_width, available_height, frame).success?
                row_fit = false
                break
              end
              if row_height < cell.preferred_height && cell.row_span == 1
                row_height = cell.preferred_height
              end
              row_spans << cell if cell.row_span > 1
            end

            zero_height_rows[row_index] = true if row_height == 0

            if row_fit
              # 2. If all cells of the row fit, we subtract the recorded row height of the
              #    non-row-span cells from the available height for the next pass.
              last_fitted_row_index = row_index
              row_heights[row_index] = row_height
              available_height -= row_height

              # 3. We look at all row-span cells that end at the current row index. If the row-span
              #    cell is larger than the sum of the row heights, we proportionally enlarge the
              #    stored height of each spanned row and subtract the difference from the available
              #    height for the next pass. If the row span contains initially zero-height rows,
              #    only those rows are enlarged. Row-span cells themselves are not updated at this
              #    point!
              row_spans.each do |cell|
                upper_row_index = cell.row + cell.row_span - 1
                next unless upper_row_index == row_index

                rows = cell.row.upto(upper_row_index)
                row_span_height = rows.sum {|ri| row_heights[ri] }
                if row_span_height < cell.preferred_height
                  zero_height_rows_in_span = rows.select {|ri| zero_height_rows[ri] }
                  rows = zero_height_rows_in_span if zero_height_rows_in_span.size > 0
                  adjustment = (cell.preferred_height - row_span_height) / rows.size.to_f
                  rows.each {|ri| row_heights[ri] += adjustment }
                  available_height -= cell.preferred_height - row_span_height
                end
              end
            else
              last_fitted_row_index = columns.min_by(&:row).row - 1 if height != available_height
              break
            end
          end

          if last_fitted_row_index >= 0
            # 4. Once all possible rows have been fitted and the heights of the rows are fixed, the
            #    final height and top-left corner of each cell needs to be set.
            running_height = 0
            @cells[start_row..last_fitted_row_index].each.with_index(start_row) do |columns, row_index|
              columns.each_with_index do |cell, col_index|
                next if cell.row != row_index || cell.column != col_index
                cell.left = column_info[cell.column].first
                cell.top = running_height
                if cell.row_span == 1
                  cell.update_height(row_heights[row_index])
                else
                  new_height = cell.row.upto(cell.row + cell.row_span - 1).sum {|ri| row_heights[ri] }
                  cell.update_height(new_height)
                end
              end
              running_height += row_heights[row_index]
            end
          end

          [height - available_height, last_fitted_row_index < start_row ? -1 : last_fitted_row_index]
        end

        # Draws the rows from +start_row+ to +end_row+ on the given +canvas+, with the top-left
        # corner of the resulting table being at (+x+, +y+).
        def draw_rows(start_row, end_row, canvas, x, y)
          @cells[start_row..end_row].each.with_index(start_row) do |columns, row_index|
            columns.each_with_index do |cell, col_index|
              next if cell.row != row_index || cell.column != col_index
              cell.draw(canvas, x + cell.left, y - cell.top - cell.height)
            end
          end
        end

        private

        # Assigns the +data+ to the individual cells, taking row and column spans into account.
        #
        # For details on the +cell_style+ argument see ::new.
        def assign_data(data, cell_style)
          cell_style = data.shift unless data[0].kind_of?(Array)
          cell_style_block = if cell_style.kind_of?(Hash)
                               lambda {|cell| cell.style.update(**cell_style) }
                             else
                               cell_style
                             end

          data.each_with_index do |cols, row_index|
            # Only add new row array if it hasn't been added due to row spans before
            @cells << [] unless @cells[row_index]
            row = @cells[row_index]
            col_index = 0

            cols.each do |content|
              # Ignore already filled in cells due to row/col spans
              col_index += 1 while row[col_index]

              children = content
              if content.kind_of?(Hash)
                children = content.delete(:content)
                row_span = content.delete(:row_span)
                col_span = content.delete(:col_span)
                min_height = content.delete(:min_height)
                properties = content.delete(:properties)
                style = content
              end
              cell = Cell.new(children: children, row: row_index, column: col_index,
                              row_span: row_span, col_span: col_span, min_height: min_height)
              cell_style_block&.call(cell)
              cell.style.update(**style) if style
              cell.properties.update(properties) if properties

              row[col_index] = cell
              if cell.row_span > 1 || cell.col_span > 1
                row_index.upto(row_index + cell.row_span - 1) do |r|
                  @cells << [] unless @cells[r]
                  col_index.upto(col_index + cell.col_span - 1) do |c|
                    @cells[r][c] = cell
                  end
                end
              end

              col_index += cell.col_span
            end

            @number_of_columns = col_index if @number_of_columns < col_index
          end
        end

      end

      # The Cells instance containing the data of the table.
      #
      # If this is an instance that was split from another one, the cells contain *all* the rows,
      # not just the ones for this split instance.
      #
      # Also see #start_row_index.
      attr_reader :cells

      # The Cells instance containing the header cells of the table.
      #
      # If this is a TableBox instance that was split from another one, the header cells are created
      # again through the use of +header+ block supplied to ::new.
      attr_reader :header_cells

      # The Cells instance containing the footer cells of the table.
      #
      # If this is a TableBox instance that was split from another one, the footer cells are created
      # again through the use of +footer+ block supplied to ::new.
      attr_reader :footer_cells

      # The column widths definition.
      #
      # See ::new for details.
      attr_reader :column_widths

      # The row index into the #cells from which this instance starts fitting the rows.
      #
      # This value is 0 if this instance was not split from another one. Otherwise, it contains the
      # correct start index.
      attr_reader :start_row_index

      # This value is -1 if #fit was not yet called. Otherwise it contains the row index of the last
      # row that could be fitted.
      attr_reader :last_fitted_row_index

      # Creates a new TableBox instance.
      #
      # +cells+::
      #
      #     This needs to be an array of arrays containing the data of the table. See Cells for more
      #     information on the allowed contents.
      #
      #     Alternatively, a Cells instance can be used. Note that in this case the +cell_style+
      #     argument is not used.
      #
      # +column_widths+::
      #
      #     An array defining the width of the columns of the table. If not set, defaults to an
      #     empty array.
      #
      #     Each entry in the array may either be a positive or negative number. A positive number
      #     sets a fixed width for the respective column.
      #
      #     A negative number specifies that the respective column is auto-sized. Such columns split
      #     the remaining width (after substracting the widths of the fixed columns) proportionally
      #     among them. For example, if the column width definition is [-1, -2, -2], the first
      #     column is a fifth of the width and the other two columns are each two fifth of the
      #     width.
      #
      #     If the +cells+ definition has more columns than specified by +column_widths+, the
      #     missing entries are assumed to be -1.
      #
      # +header+::
      #
      #     A callable object that needs to accept this TableBox instance as argument and that
      #     returns an array of arrays containing the header rows.
      #
      #     The header rows are shown for the table instance and all split boxes.
      #
      # +footer+::
      #
      #     A callable object that needs to accept this TableBox instance as argument and that
      #     returns an array of arrays containing the footer rows.
      #
      #     The footer rows are shown for the table instance and all split boxes.
      #
      # +cell_style+::
      #
      #     Contains styling information that should be applied to all header, body and footer
      #     cells.
      #
      #     This can either be a hash containing style properties or a callable object accepting a
      #     cell as argument.
      def initialize(cells:, column_widths: nil, header: nil, footer: nil, cell_style: nil, **kwargs)
        super(**kwargs)
        @cell_style = cell_style
        @cells = cells.kind_of?(Cells) ? cells : Cells.new(cells, cell_style: @cell_style)
        @column_widths = column_widths || []
        @start_row_index = 0
        @last_fitted_row_index = -1
        @header = header
        @header_cells = Cells.new(header.call(self), cell_style: @cell_style) if header
        @footer = footer
        @footer_cells = Cells.new(footer.call(self), cell_style: @cell_style) if footer
      end

      # Returns +true+ if not a single row could be fit.
      def empty?
        super && (!@last_fitted_row_index || @last_fitted_row_index < 0)
      end

      private

      # Fits the table into the current region of the frame.
      def fit_content(_available_width, _available_height, frame)
        # Adjust reserved width/height to include space used by the edge cells for their border
        # since cell borders are drawn on the bounds and not inside.
        # This uses the top-left and bottom-right cells and so might not be correct in all cases.
        @cell_tl_border_width = @cells[0, 0].style.border.width
        cell_br_border_width = @cells[-1, -1].style.border.width
        rw = (@cell_tl_border_width.left + cell_br_border_width.right) / 2.0
        rh = (@cell_tl_border_width.top + cell_br_border_width.bottom) / 2.0

        width = @width - reserved_width - rw
        height = @height - reserved_height - rh
        used_height = 0
        columns = calculate_column_widths(width)
        return if columns.empty?

        frame = frame.child_frame(box: self)
        @special_cells_fit_not_successful = false
        [@header_cells, @footer_cells].each do |special_cells|
          next unless special_cells
          special_used_height, last_fitted_row_index = special_cells.fit_rows(0, height, columns, frame)
          height -= special_used_height
          used_height += special_used_height
          @special_cells_fit_not_successful = (last_fitted_row_index != special_cells.number_of_rows - 1)
          return nil if @special_cells_fit_not_successful
        end

        main_used_height, @last_fitted_row_index = @cells.fit_rows(@start_row_index, height, columns, frame)
        used_height += main_used_height

        update_content_width { columns[-1].sum + rw }
        update_content_height { used_height + rh }

        if @last_fitted_row_index == @cells.number_of_rows - 1
          fit_result.success!
        elsif @last_fitted_row_index >= 0
          fit_result.overflow!
        end
      end

      # Calculates and returns the x-coordinates and widths of all columns based on the given total
      # available width.
      #
      # If it is not possible to fit all columns into the given +width+, an empty array is returned.
      def calculate_column_widths(width)
        @column_widths.concat([-1] * (@cells.number_of_columns - @column_widths.size))
        fixed_width, variable_width = @column_widths.partition(&:positive?).map {|c| c.sum(&:abs) }
        rest_width = width - fixed_width
        return [] if rest_width <= 0

        variable_width_unit = rest_width / variable_width.to_f
        position = 0
        @column_widths.map do |column|
          result = column > 0 ? [position, column] : [position, column.abs * variable_width_unit]
          position += result[1]
          result
        end
      end

      # Splits the content of the table box. This method is called from Box#split.
      def split_content
        box = create_split_box
        box.instance_variable_set(:@start_row_index, @last_fitted_row_index + 1)
        box.instance_variable_set(:@last_fitted_row_index, -1)
        box.instance_variable_set(:@special_cells_fit_not_successful, nil)
        header_cells = @header ? Cells.new(@header.call(self), cell_style: @cell_style) : nil
        box.instance_variable_set(:@header_cells, header_cells)
        footer_cells = @footer ? Cells.new(@footer.call(self), cell_style: @cell_style) : nil
        box.instance_variable_set(:@footer_cells, footer_cells)
        [self, box]
      end

      # Draws the child boxes onto the canvas at position [x, y].
      def draw_content(canvas, x, y)
        x += @cell_tl_border_width.left / 2.0
        y += content_height - @cell_tl_border_width.top / 2.0
        if @header_cells
          @header_cells.draw_rows(0, -1, canvas, x, y)
          y -= @header_cells[-1, 0].top + @header_cells[-1, 0].height
        end
        @cells.draw_rows(@start_row_index, @last_fitted_row_index, canvas, x, y)
        if @footer_cells
          y -= @cells[@last_fitted_row_index, 0].top + @cells[@last_fitted_row_index, 0].height
          @footer_cells.draw_rows(0, -1, canvas, x, y)
        end
      end

    end

  end
end
