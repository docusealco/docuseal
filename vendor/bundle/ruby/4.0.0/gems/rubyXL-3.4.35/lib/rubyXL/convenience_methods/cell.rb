module RubyXL
  module CellConvenienceMethods
    def change_contents(data, formula_expression = nil)
      validate_worksheet

      if formula_expression then
        self.datatype = nil
        self.formula = RubyXL::Formula.new(:expression => formula_expression)
      else
        self.datatype = case data
                        when Date, Time, Numeric then nil
                        else RubyXL::DataType::RAW_STRING
                        end
      end

      data = workbook.date_to_num(data) if data.is_a?(Date) || data.is_a?(Time)

      self.raw_value = data
    end

    def remove_formula
      self.formula = nil

      calculation_chain = workbook && workbook.calculation_chain
      calculation_cells = calculation_chain && calculation_chain.cells
      calculation_cells && calculation_cells.reject! { |c|
        c.ref.col_range.c == self.column && c.ref.row_range.begin == self.row
      }
    end

    def get_border(direction)
      validate_worksheet
      get_cell_border.get_edge_style(direction)
    end

    def get_border_color(direction)
      validate_worksheet
      get_cell_border.get_edge_color(direction)
    end

    def change_horizontal_alignment(alignment = 'center')
      validate_worksheet
      self.style_index = workbook.modify_alignment(self.style_index) { |a| a.horizontal = alignment }
    end

    def change_vertical_alignment(alignment = 'center')
      validate_worksheet
      self.style_index = workbook.modify_alignment(self.style_index) { |a| a.vertical = alignment }
    end

    def change_text_wrap(wrap = false)
      validate_worksheet
      self.style_index = workbook.modify_alignment(self.style_index) { |a| a.wrap_text = wrap }
    end

    def change_shrink_to_fit(shrink_to_fit = false)
      validate_worksheet
      self.style_index = workbook.modify_alignment(self.style_index) { |a| a.shrink_to_fit = shrink_to_fit }
    end

    def change_text_rotation(rot)
      validate_worksheet
      self.style_index = workbook.modify_alignment(self.style_index) { |a| a.text_rotation = rot }
    end

    def change_text_indent(indent)
      validate_worksheet
      self.style_index = workbook.modify_alignment(self.style_index) { |a| a.indent = indent }
    end

    def change_border(direction, weight)
      validate_worksheet
      self.style_index = workbook.modify_border(self.style_index, direction, weight)
    end

    def change_border_color(direction, color)
      validate_worksheet
      Color.validate_color(color)
      self.style_index = workbook.modify_border_color(self.style_index, direction, color)
    end

    def is_italicized
      validate_worksheet
      get_cell_font.is_italic
    end

    def is_bolded
      validate_worksheet
      get_cell_font.is_bold
    end

    def is_underlined
      validate_worksheet
      get_cell_font.is_underlined
    end

    def is_struckthrough
      validate_worksheet
      get_cell_font.is_strikethrough
    end

    def font_name
      validate_worksheet
      get_cell_font.get_name
    end

    def font_size
      validate_worksheet
      get_cell_font.get_size
    end

    def font_color
      validate_worksheet
      get_cell_font.get_rgb_color || '000000'
    end

    def fill_color
      validate_worksheet
      workbook.get_fill_color(get_cell_xf)
    end

    def horizontal_alignment
      validate_worksheet
      xf_obj = get_cell_xf
      return nil if xf_obj.alignment.nil?
      xf_obj.alignment.horizontal
    end

    def vertical_alignment
      validate_worksheet
      xf_obj = get_cell_xf
      return nil if xf_obj.alignment.nil?
      xf_obj.alignment.vertical
    end

    def text_wrap
      validate_worksheet
      xf_obj = get_cell_xf
      return nil if xf_obj.alignment.nil?
      xf_obj.alignment.wrap_text
    end

    def text_rotation
      validate_worksheet
      xf_obj = get_cell_xf
      return nil if xf_obj.alignment.nil?
      xf_obj.alignment.text_rotation
    end

    def text_indent
      validate_worksheet
      xf_obj = get_cell_xf
      return nil if xf_obj.alignment.nil?
      xf_obj.alignment.indent
    end

    def set_number_format(format_code)
      new_xf = get_cell_xf.dup
      new_xf.num_fmt_id = workbook.stylesheet.register_number_format(format_code)
      new_xf.apply_number_format = true
      self.style_index = workbook.register_new_xf(new_xf)
    end

    # Changes fill color of cell
    def change_fill(rgb = 'ffffff')
      validate_worksheet
      Color.validate_color(rgb)
      self.style_index = workbook.modify_fill(self.style_index, rgb)
    end

    # Changes font name of cell
    def change_font_name(new_font_name = 'Verdana')
      validate_worksheet

      font = get_cell_font.dup
      font.set_name(new_font_name)
      update_font_references(font)
    end

    # Changes font size of cell
    def change_font_size(font_size = 10)
      validate_worksheet
      raise 'Argument must be a number' unless font_size.is_a?(Integer) || font_size.is_a?(Float)

      font = get_cell_font.dup
      font.set_size(font_size)
      update_font_references(font)
    end

    # Changes font color of cell
    def change_font_color(font_color = '000000')
      validate_worksheet
      Color.validate_color(font_color)

      font = get_cell_font.dup
      font.set_rgb_color(font_color)
      update_font_references(font)
    end

    # Changes font italics settings of cell
    def change_font_italics(italicized = false)
      validate_worksheet

      font = get_cell_font.dup
      font.set_italic(italicized)
      update_font_references(font)
    end

    # Changes font bold settings of cell
    def change_font_bold(bolded = false)
      validate_worksheet

      font = get_cell_font.dup
      font.set_bold(bolded)
      update_font_references(font)
    end

    # Changes font underline settings of cell
    def change_font_underline(underlined = false)
      validate_worksheet

      font = get_cell_font.dup
      font.set_underline(underlined)
      update_font_references(font)
    end

    def change_font_strikethrough(struckthrough = false)
      validate_worksheet

      font = get_cell_font.dup
      font.set_strikethrough(struckthrough)
      update_font_references(font)
    end

    # Helper method to update the font array and xf array
    def update_font_references(modified_font)
      xf = workbook.register_new_font(modified_font, get_cell_xf)
      self.style_index = workbook.register_new_xf(xf)
    end
    private :update_font_references

    # Performs correct modification based on what type of change_type is specified
    def font_switch(change_type, arg)
      case change_type
      when Worksheet::NAME          then change_font_name(arg)
      when Worksheet::SIZE          then change_font_size(arg)
      when Worksheet::COLOR         then change_font_color(arg)
      when Worksheet::ITALICS       then change_font_italics(arg)
      when Worksheet::BOLD          then change_font_bold(arg)
      when Worksheet::UNDERLINE     then change_font_underline(arg)
      when Worksheet::STRIKETHROUGH then change_font_strikethrough(arg)
      else raise 'Invalid change_type'
      end
    end

    def add_hyperlink(url, tooltip = nil)
      worksheet.relationship_container ||= RubyXL::OOXMLRelationshipsFile.new
      relationships = worksheet.relationship_container.relationships
      r_id = "rId#{relationships.size + 1}"
      relationships << RubyXL::Relationship.new(:id => r_id, :target => url, :target_mode => 'External',
                                                :type => RubyXL::HyperlinkRelFile::REL_TYPE)

      hyperlink = RubyXL::Hyperlink.new(:ref => self.r, :r_id => r_id)
      hyperlink.tooltip = tooltip if tooltip
      worksheet.hyperlinks ||= RubyXL::Hyperlinks.new
      worksheet.hyperlinks << hyperlink
    end

    def add_shared_string(str)
      self.datatype = RubyXL::DataType::SHARED_STRING
      workbook.shared_strings_container ||= RubyXL::SharedStringsTable.new
      self.raw_value = workbook.shared_strings_container.add(str)
    end
  end

  RubyXL::Cell.send(:include, RubyXL::CellConvenienceMethods) # ruby 2.1 compat
end
