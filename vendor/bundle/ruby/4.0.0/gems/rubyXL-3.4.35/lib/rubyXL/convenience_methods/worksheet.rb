module RubyXL
  module WorksheetConvenienceMethods
    NAME = 0
    SIZE = 1
    COLOR = 2
    ITALICS = 3
    BOLD = 4
    UNDERLINE = 5
    STRIKETHROUGH = 6

    def insert_cell(row = 0, col = 0, data = nil, formula = nil, shift = nil)
      validate_workbook
      ensure_cell_exists(row, col)

      case shift
      when nil then # No shifting at all
      when :right then
        sheet_data.rows[row].insert_cell_shift_right(nil, col)
      when :down then
        add_row(sheet_data.size, :cells => Array.new(sheet_data.rows[row].size))
        (sheet_data.size - 1).downto(row + 1) { |index|
          old_row = sheet_data.rows[index - 1]
          if old_row.nil? then
            sheet_data.rows[index] = nil
          else
            new_row = sheet_data.rows[index] || add_row(index)
            new_row.cells[col] = old_row.cells[col]
          end
        }
      else
        raise 'invalid shift option'
      end

      return add_cell(row, col, data, formula)
    end

    # by default, only sets cell to nil
    # if :left is specified, method will shift row contents to the right of the deleted cell to the left
    # if :up is specified, method will shift column contents below the deleted cell upward
    def delete_cell(row_index = 0, column_index=0, shift=nil)
      validate_workbook
      validate_nonnegative(row_index)
      validate_nonnegative(column_index)

      row = sheet_data[row_index]
      old_cell = row && row[column_index]

      case shift
      when nil then
        row.cells[column_index] = nil if row
      when :left then
        row.delete_cell_shift_left(column_index) if row
      when :up then
        (row_index...(sheet_data.size - 1)).each { |index|
          old_row = sheet_data.rows[index + 1]
          if old_row.nil? then
            sheet_data.rows[index] = nil
          else
            new_row = sheet_data.rows[index] || add_row(index)
            c = new_row.cells[column_index] = old_row.cells[column_index]
            c.row = (index + 1) if c.is_a?(Cell)
          end
        }
      else
        raise 'invalid shift option'
      end

      return old_cell
    end

    # Inserts row at row_index, pushes down, copies style from the row above (that's what Excel 2013 does!)
    # NOTE: use of this method will break formulas which reference cells which are being "pushed down"
    def insert_row(row_index = 0)
      validate_workbook
      ensure_cell_exists(row_index)

      old_row = new_cells = nil

      if row_index > 0 then
        old_row = sheet_data.rows[row_index - 1]
        if old_row then
          new_cells = old_row.cells.collect { |c|
                        if c.nil? then nil
                        else nc = RubyXL::Cell.new(:style_index => c.style_index)
                             nc.worksheet = self
                             nc
                        end
                      }
        end
      end

      row0 = sheet_data.rows[0]
      new_cells ||= Array.new((row0 && row0.cells.size) || 0)

      sheet_data.rows.insert(row_index, nil)
      new_row = add_row(row_index, :cells => new_cells, :style_index => old_row && old_row.style_index)

      # Update row values for all rows below
      row_index.upto(sheet_data.rows.size - 1) { |r|
        row = sheet_data.rows[r]
        next if row.nil?
        row.cells.each_with_index { |cell, c|
          next if cell.nil?
          cell.r = RubyXL::Reference.new(r, c)
        }
      }

      # Update merged cells for all rows below
      if self.merged_cells then
        merged_cells.each { |mc|
          next if mc.ref.row_range.last < row_index

          in_merged_cell = mc.ref.row_range.first < row_index
          mc.ref = RubyXL::Reference.new(
            mc.ref.row_range.first + (in_merged_cell ? 0 : 1),
            mc.ref.row_range.last + 1,
            mc.ref.col_range.first,
            mc.ref.col_range.last,
          )
        }
      end

      return new_row
    end

    def delete_row(row_index=0)
      validate_workbook
      validate_nonnegative(row_index)

      deleted = sheet_data.rows.delete_at(row_index)

      # Update row number of each cell
      row_index.upto(sheet_data.size - 1) { |index|
        row = sheet_data[index]
        row && row.cells.each{ |c| c.row -= 1 unless c.nil? }
      }

      # Update row number of merged cells
      if self.merged_cells then
        merged_cells.delete_if { |mc| mc.ref.row_range == (row_index..row_index) }
        merged_cells.each { |mc|
          next if mc.ref.row_range.last < row_index

          in_merged_cell = mc.ref.row_range.first <= row_index
          mc.ref = RubyXL::Reference.new(
            mc.ref.row_range.first - (in_merged_cell ? 0 : 1),
            mc.ref.row_range.last - 1,
            mc.ref.col_range.first,
            mc.ref.col_range.last,
          )
        }
        merged_cells.delete_if { |mc| mc.ref.single_cell? }
      end

      return deleted
    end

    # Inserts column at +column_index+, pushes everything right, takes styles from column to left
    # NOTE: use of this method will break formulas which reference cells which are being "pushed right"
    def insert_column(column_index = 0)
      validate_workbook
      ensure_cell_exists(0, column_index)

      old_range = cols.get_range(column_index)

      # Go through each cell in column
      sheet_data.rows.each_with_index { |row, row_index|
        next if row.nil? # Do not process blank rows

        old_cell = row[column_index]
        c = nil

        if old_cell && old_cell.style_index != 0 &&
             old_range && old_range.style_index != old_cell.style_index then

          c = RubyXL::Cell.new(:style_index => old_cell.style_index, :worksheet => self,
                               :row => row_index, :column => column_index,
                               :datatype => RubyXL::DataType::SHARED_STRING)
        end

        row.insert_cell_shift_right(c, column_index)
      }

      cols.insert_column(column_index)

      # Update merged cells for all rows below
      if self.merged_cells then
        merged_cells.each { |mc|
          next if mc.ref.col_range.last < column_index

          in_merged_cell = mc.ref.row_range.first < column_index
          mc.ref = RubyXL::Reference.new(
            mc.ref.row_range.first,
            mc.ref.row_range.last,
            mc.ref.col_range.first + (in_merged_cell ? 0 : 1),
            mc.ref.col_range.last + 1,
          )
        }
      end

      # TODO: update column numbers
    end

    def delete_column(column_index = 0)
      validate_workbook
      validate_nonnegative(column_index)

      # Delete column
      sheet_data.rows.each { |row| row&.cells&.delete_at(column_index) }

      # Update column numbers for cells to the right of the deleted column
      sheet_data.rows.each { |row|
        next if row.nil?
        row.cells.each_with_index { |c, ci|
          c.column = ci if c.is_a?(Cell)
        }
      }

      cols.each { |range| range.delete_column(column_index) }

      # Update row number of merged cells
      return unless self.merged_cells

      merged_cells.delete_if { |mc| mc.ref.col_range == (column_index..column_index) }
      merged_cells.each { |mc|
        next if mc.ref.col_range.last < column_index

        in_merged_cell = mc.ref.col_range.first <= column_index
        mc.ref = RubyXL::Reference.new(
          mc.ref.row_range.first,
          mc.ref.row_range.last,
          mc.ref.col_range.first - (in_merged_cell ? 0 : 1),
          mc.ref.col_range.last - 1,
        )
      }

      merged_cells.delete_if { |mc| mc.ref.single_cell? }
    end

    def get_row_style(row_index)
      row = sheet_data.rows[row_index]
      (row && row.style_index) || 0
    end

    def get_row_fill(row = 0)
      (row = sheet_data.rows[row]) && row.get_fill_color
    end

    def get_row_font_name(row = 0)
      (font = row_font(row)) && font.get_name
    end

    def get_row_font_size(row = 0)
      (font = row_font(row)) && font.get_size
    end

    def get_row_font_color(row = 0)
      font = row_font(row)
      color = font && font.color
      color && (color.rgb || '000000')
    end

    def is_row_italicized(row = 0)
      (font = row_font(row)) && font.is_italic
    end

    def is_row_bolded(row = 0)
      (font = row_font(row)) && font.is_bold
    end

    def is_row_underlined(row = 0)
      (font = row_font(row)) && font.is_underlined
    end

    def is_row_struckthrough(row = 0)
      (font = row_font(row)) && font.is_strikethrough
    end

    def get_row_height(row = 0)
      validate_workbook
      validate_nonnegative(row)
      row = sheet_data.rows[row]
      (row && row.ht) || RubyXL::Row::DEFAULT_HEIGHT
    end

    def get_row_border(row, border_direction)
      validate_workbook

      border = @workbook.borders[get_row_xf(row).border_id]
      border && border.get_edge_style(border_direction)
    end

    def get_row_border_color(row, border_direction)
      validate_workbook

      border = @workbook.borders[get_row_xf(row).border_id]
      border && border.get_edge_color(border_direction)
    end

    def row_font(row)
      (row = sheet_data.rows[row]) && row.get_font
    end

    def get_row_alignment(row, is_horizontal)
      validate_workbook

      xf_obj = get_row_xf(row)
      return nil if xf_obj.alignment.nil?

      if is_horizontal then return xf_obj.alignment.horizontal
      else                  return xf_obj.alignment.vertical
      end
    end

    def get_cols_style_index(column_index)
      validate_nonnegative(column_index)
      range = cols.locate_range(column_index)
      (range && range.style_index) || 0
    end

    def get_column_font_name(col = 0)
      font = column_font(col)
      font && font.get_name
    end

    def get_column_font_size(col = 0)
      font = column_font(col)
      font && font.get_size
    end

    def get_column_font_color(col = 0)
      font = column_font(col)
      font && (font.get_rgb_color || '000000')
    end

    def is_column_italicized(col = 0)
      font = column_font(col)
      font && font.is_italic
    end

    def is_column_bolded(col = 0)
      font = column_font(col)
      font && font.is_bold
    end

    def is_column_underlined(col = 0)
      font = column_font(col)
      font && font.is_underlined
    end

    def is_column_struckthrough(col = 0)
      font = column_font(col)
      font && font.is_strikethrough
    end

    # Get raw column width value as stored in the file
    def get_column_width_raw(column_index = 0)
      validate_workbook
      validate_nonnegative(column_index)

      range = cols.locate_range(column_index)
      range && range.width
    end

    # Get column width measured in number of digits, as per
    # http://msdn.microsoft.com/en-us/library/documentformat.openxml.spreadsheet.column%28v=office.14%29.aspx
    def get_column_width(column_index = 0)
      width = get_column_width_raw(column_index)
      return RubyXL::ColumnRange::DEFAULT_WIDTH if width.nil?
      (width - (5.0 / RubyXL::Font::MAX_DIGIT_WIDTH)).round
    end

    # Set raw column width value
    def change_column_width_raw(column_index, width)
      validate_workbook
      ensure_cell_exists(0, column_index)
      range = cols.get_range(column_index)
      range.width = width
      range.custom_width = true
    end

    # Get column width measured in number of digits, as per
    # http://msdn.microsoft.com/en-us/library/documentformat.openxml.spreadsheet.column%28v=office.14%29.aspx
    def change_column_width(column_index, width_in_chars = RubyXL::ColumnRange::DEFAULT_WIDTH)
      change_column_width_raw(column_index, RubyXL::ColumnRange::chars2raw(width_in_chars))
    end

    # Helper method to get the style index for a column
    def get_col_style(column_index)
      range = cols.locate_range(column_index)
      (range && range.style_index) || 0
    end

    def get_column_fill(col=0)
      validate_workbook
      validate_nonnegative(col)

      @workbook.get_fill_color(get_col_xf(col))
    end

    def change_column_fill(column_index, color_code = 'ffffff')
      validate_workbook
      RubyXL::Color.validate_color(color_code)
      ensure_cell_exists(0, column_index)

      cols.get_range(column_index).style_index = @workbook.modify_fill(get_col_style(column_index), color_code)

      sheet_data.rows.each { |row|
        next if row.nil?
        c = row[column_index]
        next if c.nil?
        c.change_fill(color_code)
      }
    end

    def get_column_border(col, border_direction)
      validate_workbook

      xf = @workbook.cell_xfs[get_cols_style_index(col)]
      border = @workbook.borders[xf.border_id]
      border && border.get_edge_style(border_direction)
    end

    def get_column_border_color(col, border_direction)
      validate_workbook

      xf = @workbook.cell_xfs[get_cols_style_index(col)]
      border = @workbook.borders[xf.border_id]
      border && border.get_edge_color(border_direction)
    end

    def column_font(col)
      validate_workbook

      @workbook.fonts[@workbook.cell_xfs[get_cols_style_index(col)].font_id]
    end

    def get_column_alignment(col, type)
      validate_workbook

      xf = @workbook.cell_xfs[get_cols_style_index(col)]
      xf.alignment && xf.alignment.send(type)
    end

    def change_row_horizontal_alignment(row = 0, alignment = 'center')
      validate_workbook
      validate_nonnegative(row)
      change_row_alignment(row) { |a| a.horizontal = alignment }
    end

    def change_row_vertical_alignment(row = 0, alignment = 'center')
      validate_workbook
      validate_nonnegative(row)
      change_row_alignment(row) { |a| a.vertical = alignment }
    end

    def change_row_border(row, direction, weight)
      validate_workbook
      ensure_cell_exists(row)

      sheet_data.rows[row].style_index = @workbook.modify_border(get_row_style(row), direction, weight)

      sheet_data[row].cells.each { |c|
        c.change_border(direction, weight) unless c.nil?
      }
    end

    def change_row_border_color(row, direction, color = '000000')
      validate_workbook
      ensure_cell_exists(row)
      Color.validate_color(color)

      sheet_data.rows[row].style_index = @workbook.modify_border_color(get_row_style(row), direction, color)

      sheet_data[row].cells.each { |c|
        c.change_border_color(direction, color) unless c.nil?
      }
    end

    def change_row_fill(row_index = 0, rgb = 'ffffff')
      validate_workbook
      ensure_cell_exists(row_index)
      Color.validate_color(rgb)

      sheet_data.rows[row_index].style_index = @workbook.modify_fill(get_row_style(row_index), rgb)
      sheet_data[row_index].cells.each { |c| c.change_fill(rgb) unless c.nil? }
    end

    # Helper method to update the row styles array
    # change_type - NAME or SIZE or COLOR etc
    # main method to change font, called from each separate font mutator method
    def change_row_font(row_index, change_type, arg, font)
      validate_workbook
      ensure_cell_exists(row_index)

      xf = workbook.register_new_font(font, get_row_xf(row_index))
      row = sheet_data[row_index]
      row.style_index = workbook.register_new_xf(xf)
      row.cells.each { |c| c.font_switch(change_type, arg) unless c.nil? }
    end

    def change_row_font_name(row = 0, font_name = 'Verdana')
      ensure_cell_exists(row)
      font = row_font(row).dup
      font.set_name(font_name)
      change_row_font(row, Worksheet::NAME, font_name, font)
    end

    def change_row_font_size(row = 0, font_size=10)
      ensure_cell_exists(row)
      font = row_font(row).dup
      font.set_size(font_size)
      change_row_font(row, Worksheet::SIZE, font_size, font)
    end

    def change_row_font_color(row = 0, font_color = '000000')
      ensure_cell_exists(row)
      Color.validate_color(font_color)
      font = row_font(row).dup
      font.set_rgb_color(font_color)
      change_row_font(row, Worksheet::COLOR, font_color, font)
    end

    def change_row_italics(row = 0, italicized = false)
      ensure_cell_exists(row)
      font = row_font(row).dup
      font.set_italic(italicized)
      change_row_font(row, Worksheet::ITALICS, italicized, font)
    end

    def change_row_bold(row = 0, bolded = false)
      ensure_cell_exists(row)
      font = row_font(row).dup
      font.set_bold(bolded)
      change_row_font(row, Worksheet::BOLD, bolded, font)
    end

    def change_row_underline(row = 0, underlined=false)
      ensure_cell_exists(row)
      font = row_font(row).dup
      font.set_underline(underlined)
      change_row_font(row, Worksheet::UNDERLINE, underlined, font)
    end

    def change_row_strikethrough(row = 0, struckthrough=false)
      ensure_cell_exists(row)
      font = row_font(row).dup
      font.set_strikethrough(struckthrough)
      change_row_font(row, Worksheet::STRIKETHROUGH, struckthrough, font)
    end

    def change_row_height(row = 0, height = 10)
      validate_workbook
      ensure_cell_exists(row)

      c = sheet_data.rows[row]
      c.ht = height
      c.custom_height = true
    end

    # Helper method to update the fonts and cell styles array
    # main method to change font, called from each separate font mutator method
    def change_column_font(column_index, change_type, arg, font, xf)
      validate_workbook
      ensure_cell_exists(0, column_index)

      xf = workbook.register_new_font(font, xf)
      cols.get_range(column_index).style_index = workbook.register_new_xf(xf)

      sheet_data.rows.each { |row|
        c = row && row[column_index]
        c.font_switch(change_type, arg) unless c.nil?
      }
    end

    def change_column_font_name(column_index = 0, font_name = 'Verdana')
      xf = get_col_xf(column_index)
      font = @workbook.fonts[xf.font_id].dup
      font.set_name(font_name)
      change_column_font(column_index, Worksheet::NAME, font_name, font, xf)
    end

    def change_column_font_size(column_index, font_size=10)
      xf = get_col_xf(column_index)
      font = @workbook.fonts[xf.font_id].dup
      font.set_size(font_size)
      change_column_font(column_index, Worksheet::SIZE, font_size, font, xf)
    end

    def change_column_font_color(column_index, font_color='000000')
      Color.validate_color(font_color)

      xf = get_col_xf(column_index)
      font = @workbook.fonts[xf.font_id].dup
      font.set_rgb_color(font_color)
      change_column_font(column_index, Worksheet::COLOR, font_color, font, xf)
    end

    def change_column_italics(column_index, italicized = false)
      xf = get_col_xf(column_index)
      font = @workbook.fonts[xf.font_id].dup
      font.set_italic(italicized)
      change_column_font(column_index, Worksheet::ITALICS, italicized, font, xf)
    end

    def change_column_bold(column_index, bolded = false)
      xf = get_col_xf(column_index)
      font = @workbook.fonts[xf.font_id].dup
      font.set_bold(bolded)
      change_column_font(column_index, Worksheet::BOLD, bolded, font, xf)
    end

    def change_column_underline(column_index, underlined = false)
      xf = get_col_xf(column_index)
      font = @workbook.fonts[xf.font_id].dup
      font.set_underline(underlined)
      change_column_font(column_index, Worksheet::UNDERLINE, underlined, font, xf)
    end

    def change_column_strikethrough(column_index, struckthrough=false)
      xf = get_col_xf(column_index)
      font = @workbook.fonts[xf.font_id].dup
      font.set_strikethrough(struckthrough)
      change_column_font(column_index, Worksheet::STRIKETHROUGH, struckthrough, font, xf)
    end

    def change_column_horizontal_alignment(column_index, alignment = 'center')
      change_column_alignment(column_index) { |a| a.horizontal = alignment }
    end

    def change_column_vertical_alignment(column_index, alignment = 'center')
      change_column_alignment(column_index) { |a| a.vertical = alignment }
    end

    def change_column_border(column_index, direction, weight)
      validate_workbook
      ensure_cell_exists(0, column_index)

      cols.get_range(column_index).style_index = @workbook.modify_border(get_col_style(column_index), direction, weight)

      sheet_data.rows.each { |row|
        next if row.nil?
        c = row.cells[column_index]
        next if c.nil?
        c.change_border(direction, weight)
      }
    end

    def change_column_border_color(column_index, direction, color)
      validate_workbook
      ensure_cell_exists(0, column_index)
      Color.validate_color(color)

      cols.get_range(column_index).style_index = @workbook.modify_border_color(get_col_style(column_index), direction, color)

      sheet_data.rows.each { |row|
        c = row.cells[column_index]
        c.change_border_color(direction, color) unless c.nil?
      }
    end

    def change_row_alignment(row, &block)
      validate_workbook
      validate_nonnegative(row)
      ensure_cell_exists(row)

      sheet_data.rows[row].style_index = @workbook.modify_alignment(get_row_style(row), &block)

      sheet_data[row].cells.each { |c|
        next if c.nil?
        c.style_index = @workbook.modify_alignment(c.style_index, &block)
      }
    end

    def change_column_alignment(column_index, &block)
      validate_workbook
      ensure_cell_exists(0, column_index)

      cols.get_range(column_index).style_index = @workbook.modify_alignment(get_col_style(column_index), &block)
      # Excel gets confused if width is not explicitly set for a column that had alignment changes
      change_column_width(column_index) if get_column_width_raw(column_index).nil?

      sheet_data.rows.each { |row|
        next if row.nil?
        c = row[column_index]
        next if c.nil?
        c.style_index = @workbook.modify_alignment(c.style_index, &block)
      }
    end

    # Merges cells within a rectangular area
    # #merge_cells(row_from, col_from, row_to, col_to)
    # #merge_cells(reference_string)
    # #merge_cells(row_from:, row_to:, col_from:, col_to:)
    def merge_cells(*params)
      validate_workbook

      row_from = col_from = row_to = col_to = nil
      case params.size
      when 4 then row_from, col_from, row_to, col_to = params
      when 1 then
        case params.first
        when Hash then
          row_from, row_to, col_from, col_to = params.first.fetch_values(:row_from, :row_to, :col_from, :col_to)
        when String then
          from, to = params[0].split(':')
          raise ArgumentError.new("reference for merging cells must be a range") if to.nil?
          row_from, col_from = RubyXL::Reference.ref2ind(from)
          row_to, col_to = RubyXL::Reference.ref2ind(to)
        else
          raise ArgumentError.new("invalid value for #{self.class}: #{params[0].inspect}") unless params[0].is_a?(String)
        end
      end

      self.merged_cells ||= RubyXL::MergedCells.new
      # TODO: add validation to make sure ranges are not intersecting with existing ones
      merged_cells << RubyXL::MergedCell.new(:ref => RubyXL::Reference.new(row_from, row_to, col_from, col_to))
    end

    def add_validation_list(ref, list_arr)
      # "Any double quote characters in the value should be escaped with another double quote.
      # If the value does not contain a comma, newline or double quote, then the String value should be returned unchanged.
      # If the value contains a comma, newline or double quote, then the String value should be returned enclosed in double quotes."
      expr = '"' + list_arr.collect{ |str| str.gsub('"', '""') }.join(',') + '"'
      self.data_validations ||= RubyXL::DataValidations.new
      self.data_validations <<
        RubyXL::DataValidation.new({:sqref    => RubyXL::Reference.new(ref),
                                    :formula1 => RubyXL::Formula.new(:expression => expr),
                                    :type     => 'list'})
    end
  end

  RubyXL::Worksheet.send(:include, RubyXL::WorksheetConvenienceMethods) # ruby 2.1 compat
end
