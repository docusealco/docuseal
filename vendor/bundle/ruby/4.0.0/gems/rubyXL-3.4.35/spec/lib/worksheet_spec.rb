# frozen_string_literal: true

require 'spec_helper'
require 'rubyXL/convenience_methods/worksheet'

SKIP_ROW_COL = 3

describe RubyXL::Worksheet do
  subject do
    workbook  = RubyXL::Workbook.new
    worksheet = workbook.add_worksheet

    11.times do |y|
      11.times do |x|
        next if y == SKIP_ROW_COL || x == SKIP_ROW_COL # Skip some rows/cells
        worksheet.add_cell(y, x, "#{x}:#{y}", "F#{x}:#{y}")
      end
    end

    worksheet
  end

  describe 'addressing cells' do
    it 'should be able to address cells by row and column indices' do
      expect(subject[2][4].value).to eq('4:2')
    end

    it 'should be able to address cells by reference' do
      expect(subject.cell_at('B5').value).to eq('1:4')
    end
  end

  describe '.change_row_fill' do
    it 'should raise error if hex color code not passed' do
      expect {
        subject.change_row_fill(0, 'G')
      }.to raise_error(RuntimeError)
    end

    it 'should raise error if hex color code includes # character' do
      expect {
        subject.change_row_fill(3, '#FFF000')
      }.to raise_error(RuntimeError)
    end

    it 'should make row and cell fill colors equal hex color code passed' do
      subject.change_row_fill(0, '111111')
      expect(subject.get_row_fill(0)).to eq('111111')
      expect(subject[0][5].fill_color).to eq('111111')
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.change_row_fill(-1, '111111')
      }.to raise_error(RuntimeError)
    end

    it 'should create a new row if it did not exist before' do
      expect(subject.sheet_data[11]).to be_nil
      subject.change_row_fill(11, '111111')
      expect(subject.sheet_data[11]).to be_a(RubyXL::Row)
      expect(subject.get_row_fill(11)).to eq('111111')
    end
  end

  describe '.change_row_font_name' do
    it 'should make row and cell font names equal font name passed' do
      subject.change_row_font_name(0, 'Arial')
      expect(subject.get_row_font_name(0)).to eq('Arial')
      expect(subject[0][5].font_name).to eq('Arial')
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.change_row_font_name(-1, 'Arial')
      }.to raise_error(RuntimeError)
    end

    it 'should create a new row if it did not exist before' do
      expect(subject.sheet_data[11]).to be_nil
      subject.change_row_font_name(11, 'Arial')
      expect(subject.sheet_data[11]).to be_a(RubyXL::Row)
      expect(subject.get_row_font_name(11)).to eq('Arial')
    end
  end

  describe '.change_row_font_size' do
    it 'should make row and cell font sizes equal font number passed' do
      subject.change_row_font_size(0, 20)
      expect(subject.get_row_font_size(0)).to eq(20)
      expect(subject[0][5].font_size).to eq(20)
    end

    it 'should cause an error if a string passed' do
      expect {
        subject.change_row_font_size(0, '20')
      }.to raise_error(RuntimeError)
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.change_row_font_size(-1, 20)
      }.to raise_error(RuntimeError)
    end

    it 'should create a new row if it did not exist before' do
      expect(subject.sheet_data[11]).to be_nil
      subject.change_row_font_size(11, 20)
      expect(subject.sheet_data[11]).to be_a(RubyXL::Row)
      expect(subject.get_row_font_size(11)).to eq(20)
    end
  end

  describe '.change_row_font_color' do
    it 'should make row and cell font colors equal to font color passed' do
      subject.change_row_font_color(0, '0f0f0f')
      expect(subject.get_row_font_color(0)).to eq('0f0f0f')
      expect(subject[0][5].font_color).to eq('0f0f0f')
    end

    it 'should raise error if hex color code not passed' do
      expect {
        subject.change_row_font_color(0, 'G')
      }.to raise_error(RuntimeError)
    end

    it 'should raise error if hex color code includes # character' do
      expect {
        subject.change_row_font_color(3, '#FFF000')
      }.to raise_error(RuntimeError)
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.change_row_font_color(-1, '0f0f0f')
      }.to raise_error(RuntimeError)
    end

    it 'should create a new row if it did not exist before' do
      expect(subject.sheet_data[11]).to be_nil
      subject.change_row_font_color(11, '0f0f0f')
      expect(subject.sheet_data[11]).to be_a(RubyXL::Row)
      expect(subject.get_row_font_color(11)).to eq('0f0f0f')
    end
  end

  describe '.change_row_italics' do
    it 'should make row and cell fonts italicized when true is passed' do
      subject.change_row_italics(0, true)
      expect(subject.is_row_italicized(0)).to eq(true)
      expect(subject[0][5].is_italicized).to eq(true)
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.change_row_italics(-1, false)
      }.to raise_error(RuntimeError)
    end

    it 'should create a new row if it did not exist before' do
      expect(subject.sheet_data[11]).to be_nil
      subject.change_row_italics(11, true)
      expect(subject.sheet_data[11]).to be_a(RubyXL::Row)
      expect(subject.is_row_italicized(11)).to eq(true)
    end
  end

  describe '.change_row_bold' do
    it 'should make row and cell fonts bolded when true is passed' do
      subject.change_row_bold(0, true)
      expect(subject.is_row_bolded(0)).to eq(true)
      expect(subject[0][5].is_bolded).to eq(true)
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.change_row_bold(-1, false)
      }.to raise_error(RuntimeError)
    end

    it 'should create a new row if it did not exist before' do
      expect(subject.sheet_data[11]).to be_nil
      subject.change_row_bold(11, true)
      expect(subject.sheet_data[11]).to be_a(RubyXL::Row)
      expect(subject.is_row_bolded(11)).to eq(true)
    end
  end

  describe '.change_row_underline' do
    it 'should make row and cell fonts underlined when true is passed' do
      subject.change_row_underline(0, true)
      expect(subject.is_row_underlined(0)).to eq(true)
      expect(subject[0][5].is_underlined).to eq(true)
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.change_row_underline(-1, false)
      }.to raise_error(RuntimeError)
    end

    it 'should create a new row if it did not exist before' do
      expect(subject.sheet_data[11]).to be_nil
      subject.change_row_underline(11, true)
      expect(subject.sheet_data[11]).to be_a(RubyXL::Row)
      expect(subject.is_row_underlined(11)).to eq(true)
    end
  end

  describe '.change_row_strikethrough' do
    it 'should make row and cell fonts struckthrough when true is passed' do
      subject.change_row_strikethrough(0, true)
      expect(subject.is_row_struckthrough(0)).to eq(true)
      expect(subject[0][5].is_struckthrough).to eq(true)
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.change_row_strikethrough(-1, false)
      }.to raise_error(RuntimeError)
    end

    it 'should create a new row if it did not exist before' do
      expect(subject.sheet_data[11]).to be_nil
      subject.change_row_strikethrough(11, true)
      expect(subject.sheet_data[11]).to be_a(RubyXL::Row)
      expect(subject.is_row_struckthrough(11)).to eq(true)
    end
  end

  describe '.change_row_height' do
    it 'should make row height match number which is passed' do
      subject.change_row_height(0, 30.0002)
      expect(subject.get_row_height(0)).to eq(30.0002)
    end

    it 'should make row height a number equivalent of the string passed if it is a string which is a number' do
      subject.change_row_height(0, 30.0002)
      expect(subject.get_row_height(0)).to eq(30.0002)
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.change_row_height(-1, 30)
      }.to raise_error(RuntimeError)
    end

    it 'should create a new row if it did not exist before' do
      expect(subject.sheet_data[11]).to be_nil
      subject.change_row_height(11, 30)
      expect(subject.sheet_data[11]).to be_a(RubyXL::Row)
      expect(subject.get_row_height(11)).to eq(30)
    end
  end

  describe '.change_row_horizontal_alignment' do
    it 'should cause row and cells to horizontally align as specified by the passed in string' do
      subject.change_row_horizontal_alignment(0, 'center')
      expect(subject.get_row_alignment(0, true)).to eq('center')
      expect(subject[0][5].horizontal_alignment).to eq('center')
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.change_row_horizontal_alignment(-1, 'center')
      }.to raise_error(RuntimeError)
    end

    it 'should create a new row if it did not exist before' do
      expect(subject.sheet_data[11]).to be_nil
      subject.change_row_horizontal_alignment(11, 'center')
      expect(subject.sheet_data[11]).to be_a(RubyXL::Row)
      expect(subject.get_row_alignment(11, true)).to eq('center')
    end
  end

  describe '.change_row_vertical_alignment' do
    it 'should cause row and cells to vertically align as specified by the passed in string' do
      subject.change_row_vertical_alignment(0, 'center')
      expect(subject.get_row_alignment(0, false)).to eq('center')
      expect(subject[0][5].vertical_alignment).to eq('center')
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.change_row_vertical_alignment(-1, 'center')
      }.to raise_error(RuntimeError)
    end

    it 'should create a new row if it did not exist before' do
      expect(subject.sheet_data[11]).to be_nil
      subject.change_row_vertical_alignment(11, 'center')
      expect(subject.sheet_data[11]).to be_a(RubyXL::Row)
      expect(subject.get_row_alignment(11, false)).to eq('center')
    end
  end

  describe '.change_row_border' do
    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.change_row_border(-1, :left, 'thin')
      }.to raise_error(RuntimeError)
    end

    it 'should create a new row if it did not exist before' do
      expect(subject.sheet_data[11]).to be_nil
      subject.change_row_border(11, :left, 'thin')
      expect(subject.sheet_data[11]).to be_a(RubyXL::Row)
      expect(subject.get_row_border(11, :left)).to eq('thin')
    end

    it 'should cause row and cells to have border at top of specified weight' do
      subject.change_row_border(0, :top, 'thin')
      expect(subject.get_row_border(0, :top)).to eq('thin')
      expect(subject[0][5].get_border(:top)).to eq('thin')
    end

    it 'should cause row and cells to have border at left of specified weight' do
      subject.change_row_border(0, :left, 'thin')
      expect(subject.get_row_border(0, :left)).to eq('thin')
      expect(subject[0][5].get_border(:left)).to eq('thin')
    end

    it 'should cause row and cells to have border at right of specified weight' do
      subject.change_row_border(0, :right, 'thin')
      expect(subject.get_row_border(0, :right)).to eq('thin')
      expect(subject[0][5].get_border(:right)).to eq('thin')
    end

    it 'should cause row to have border at bottom of specified weight' do
      subject.change_row_border(0, :bottom, 'thin')
      expect(subject.get_row_border(0, :bottom)).to eq('thin')
      expect(subject[0][5].get_border(:bottom)).to eq('thin')
    end

    it 'should cause row to have border at diagonal of specified weight' do
      subject.change_row_border(0, :diagonal, 'thin')
      expect(subject.get_row_border(0, :diagonal)).to eq('thin')
      expect(subject[0][5].get_border(:diagonal)).to eq('thin')
    end
  end

  describe '.change_column_font_name' do
    it 'should cause column and cell font names to match string passed in' do
      subject.change_column_font_name(0, 'Arial')
      expect(subject.get_column_font_name(0)).to eq('Arial')
      expect(subject[5][0].font_name).to eq('Arial')
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.change_column_font_name(-1, 'Arial')
      }.to raise_error(RuntimeError)
    end
  end

  describe '.change_column_font_size' do
    it 'should make column and cell font sizes equal font number passed' do
      subject.change_column_font_size(0, 20)
      expect(subject.get_column_font_size(0)).to eq(20)
      expect(subject[5][0].font_size).to eq(20)
    end

    it 'should cause an error if a string passed' do
      expect {
        subject.change_column_font_size(0, '20')
      }.to raise_error(RuntimeError)
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.change_column_font_size(-1, 20)
      }.to raise_error(RuntimeError)
    end
  end

  describe '.change_column_font_color' do
    it 'should make column and cell font colors equal to font color passed' do
      subject.change_column_font_color(0, '0f0f0f')
      expect(subject.get_column_font_color(0)).to eq('0f0f0f')
      expect(subject[5][0].font_color).to eq('0f0f0f')
    end

    it 'should raise error if hex color code not passed' do
      expect {
        subject.change_column_font_color(0, 'G')
      }.to raise_error(RuntimeError)
    end

    it 'should raise error if hex color code includes # character' do
      expect {
        subject.change_column_font_color(0, '#FFF000')
      }.to raise_error(RuntimeError)
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.change_column_font_color(-1, '0f0f0f')
      }.to raise_error(RuntimeError)
    end
  end

  describe '.change_column_italics' do
    it 'should make column and cell fonts italicized when true is passed' do
      subject.change_column_italics(0, true)
      expect(subject.is_column_italicized(0)).to eq(true)
      expect(subject[5][0].is_italicized).to eq(true)
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.change_column_italics(-1, false)
      }.to raise_error(RuntimeError)
    end
  end

  describe '.change_column_bold' do
    it 'should make column and cell fonts bolded when true is passed' do
      subject.change_column_bold(0, true)
      expect(subject.is_column_bolded(0)).to eq(true)
      expect(subject[5][0].is_bolded).to eq(true)
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.change_column_bold(-1, false)
      }.to raise_error(RuntimeError)
    end
  end

  describe '.change_column_underline' do
    it 'should make column and cell fonts underlined when true is passed' do
      subject.change_column_underline(0, true)
      expect(subject.is_column_underlined(0)).to eq(true)
      expect(subject[5][0].is_underlined).to eq(true)
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.change_column_underline(-1, false)
      }.to raise_error(RuntimeError)
    end
  end

  describe '.change_column_strikethrough' do
    it 'should make column and cell fonts struckthrough when true is passed' do
      subject.change_column_strikethrough(0, true)
      expect(subject.is_column_struckthrough(0)).to eq(true)
      expect(subject[5][0].is_struckthrough).to eq(true)
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.change_column_strikethrough(-1, false)
      }.to raise_error(RuntimeError)
    end
  end

  describe '.change_column_width_raw' do
    it 'should make column width match number which is passed' do
      subject.change_column_width_raw(0, 30.0002)
      expect(subject.get_column_width_raw(0)).to eq(30.0002)
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.change_column_width_raw(-1, 10)
      }.to raise_error(RuntimeError)
    end
  end

  describe '.change_column_fill' do
    it 'should raise error if hex color code not passed' do
      expect {
        subject.change_column_fill(0, 'G')
      }.to raise_error(RuntimeError)
    end

    it 'should raise error if hex color code includes # character' do
      expect {
        subject.change_column_fill(3, '#FFF000')
      }.to raise_error(RuntimeError)
    end

    it 'should make column and cell fill colors equal hex color code passed' do
      subject.change_column_fill(0, '111111')
      expect(subject.get_column_fill(0)).to eq('111111')
      expect(subject[5][0].fill_color).to eq('111111')
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.change_column_fill(-1, '111111')
      }.to raise_error(RuntimeError)
    end
  end

  describe '.change_column_horizontal_alignment' do
    it 'should cause column and cell to horizontally align as specified by the passed in string' do
      subject.change_column_horizontal_alignment(0, 'center')
      expect(subject.get_column_alignment(0, :horizontal)).to eq('center')
      expect(subject[5][0].horizontal_alignment).to eq('center')
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.change_column_horizontal_alignment(-1, 'center')
      }.to raise_error(RuntimeError)
    end
  end

  describe '.change_column_vertical_alignment' do
    it 'should cause column and cell to vertically align as specified by the passed in string' do
      subject.change_column_vertical_alignment(0, 'center')
      expect(subject.get_column_alignment(0, :vertical)).to eq('center')
      expect(subject[5][0].vertical_alignment).to eq('center')
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.change_column_vertical_alignment(-1, 'center')
      }.to raise_error(RuntimeError)
    end

    it 'should set column width if column alignment is changed' do
      test_column = 2
      expect(subject.get_column_alignment(test_column, :vertical)).to be_nil
      expect(subject.get_column_width_raw(test_column)).to be_nil
      expect(subject.get_column_width(test_column)).to eq(RubyXL::ColumnRange::DEFAULT_WIDTH)
      subject.change_column_vertical_alignment(test_column, 'top')
      expect(subject.get_column_width_raw(test_column)).not_to be_nil
      expect(subject.get_column_width(test_column)).to eq(RubyXL::ColumnRange::DEFAULT_WIDTH)
      expect(subject.get_column_alignment(test_column, :vertical)).to eq('top')
    end
  end

  describe '.change_column_border' do
    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.change_column_border(-1, :top, 'thin')
      }.to raise_error(RuntimeError)
    end

    it 'should cause column and cells within to have border at top of specified weight' do
      subject.change_column_border(0, :top, 'thin')
      expect(subject.get_column_border(0, :top)).to eq('thin')
      expect(subject[5][0].get_border(:top)).to eq('thin')
    end

    it 'should cause column and cells within to have border at left of specified weight' do
      subject.change_column_border(0, :left, 'thin')
      expect(subject.get_column_border(0, :left)).to eq('thin')
      expect(subject[5][0].get_border(:left)).to eq('thin')
    end

    it 'should cause column and cells within to have border at right of specified weight' do
      subject.change_column_border(0, :right, 'thin')
      expect(subject.get_column_border(0, :right)).to eq('thin')
      expect(subject[5][0].get_border(:right)).to eq('thin')
    end

    it 'should cause column and cells within to have border at bottom of specified weight' do
      subject.change_column_border(0, :bottom, 'thin')
      expect(subject.get_column_border(0, :bottom)).to eq('thin')
      expect(subject[5][0].get_border(:bottom)).to eq('thin')
    end

    it 'should cause column and cells within to have border at diagonal of specified weight' do
      subject.change_column_border(0, :diagonal, 'thin')
      expect(subject.get_column_border(0, :diagonal)).to eq('thin')
      expect(subject[5][0].get_border(:diagonal)).to eq('thin')
    end
  end

  describe '.merge_cells' do
    it 'should merge cells in any valid range specified by indices' do
      subject.merge_cells(0, 1, 2, 3)
      expect(subject.merged_cells.collect{ |r| r.ref.to_s }).to eq(['B1:D3'])
    end

    it 'should merge cells in any valid range specified by Reference' do
      subject.merge_cells('A1:FF99')
      expect(subject.merged_cells.collect{ |r| r.ref.to_s }).to eq(['A1:FF99'])
    end

    it 'should merge cells in any valid range specified by named params' do
      subject.merge_cells(row_from: 0, row_to: 1, col_from: 2, col_to: 3)
      expect(subject.merged_cells.collect{ |r| r.ref.to_s }).to eq(['C1:D2'])
    end
  end

  describe '.add_cell' do
    it 'should add new cell where specified, even if a cell is already there (default)' do
      old_cell = subject[0][0]
      old_cell_value = old_cell.value.to_s

      subject.add_cell(0, 0, 'TEST')
      expect(subject[0][0].value).not_to eq(old_cell_value)
      expect(subject[0][0].value).to eq('TEST')
    end

    it 'should add a new cell below nil rows that might exist' do
      subject.sheet_data.rows << nil << nil
      subject.add_cell(15, 0, 'TEST')
      expect(subject[15][0].value).to eq('TEST')
    end

    it 'should add new cell where specified with formula, even if a cell is already there (default)' do
      old_cell = subject[0][0]
      old_cell_value = old_cell.value.to_s
      old_cell_formula = old_cell.formula.expression.to_s

      subject.add_cell(0, 0, '', 'SUM(A2:A10)')
      expect(subject[0][0].value).not_to eq(old_cell_value)
      expect(subject[0][0].formula).not_to eq(old_cell_formula)
      expect(subject[0][0].value).to eq('')
      expect(subject[0][0].formula.expression).to eq('SUM(A2:A10)')
    end

    it 'should not overwrite when a cell is present when overwrite is specified to be false' do
      old_cell = subject[0][0]
      old_cell_value = old_cell.value.to_s
      old_cell_formula = old_cell.formula.expression.to_s

      subject.add_cell(0, 0, 'TEST', 'B2', false)
      expect(subject[0][0].value).to eq(old_cell_value)
      expect(subject[0][0].formula.expression.to_s).to eq(old_cell_formula)
    end

    it 'should still add a new cell when there is no cell to be overwritten' do
      subject.add_cell(11, 11, 'TEST', 'B2', false)
      expect(subject[11][11].value).to eq('TEST')
      expect(subject[11][11].formula.expression).to eq('B2')
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.add_cell(-1, -1, '')
      }.to raise_error(RuntimeError)
    end
  end

  describe '.delete_row' do
    it 'should delete a row at index specified, "pushing" everything else "up"' do
      subject.delete_row(0)
      expect(subject[0][0].value).to eq('0:1')
      expect(subject[0][0].formula.expression.to_s).to eq('F0:1')
      expect(subject[0][0].row).to eq(0)
      expect(subject[0][0].column).to eq(0)
    end

    it 'should delete a row at index specified, adjusting styles for other rows' do
      subject.change_row_font_name(1, 'Courier')
      subject.delete_row(0)
      expect(subject.get_row_font_name(0)).to eq('Courier')
    end

    it 'should preserve (rather than fix) formulas that reference cells in "pushed up" rows' do
      subject.add_cell(11, 0, nil, 'SUM(A1:A10)')
      subject.delete_row(0)
      expect(subject[10][0].formula.expression).to eq('SUM(A1:A10)')
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.delete_row(-1)
      }.to raise_error(RuntimeError)
    end

    it 'should properly reindex the cells' do
      subject.sheet_data.rows.each_with_index { |row, r|
        if (r == SKIP_ROW_COL) then
          expect(row).to be_nil
        else
          row.cells.each_with_index { |cell, c|
            if (c == SKIP_ROW_COL) then
              expect(cell).to be_nil
            else
              expect(cell.row).to eq(r)
              expect(cell.column).to eq(c)
            end
          }
        end
      }
    end

    describe 'merged_cells updating' do
      context 'merged cells in the row' do
        # | A1 | B1 | C1 | D1 | E1 |
        # | A2 |    MERGED    | E2 |
        # | A3 | B3 | C3 | D3 | E3 |
        before do
          subject.merge_cells(1, 1, 1, 3)
          expect(subject.merged_cells.size).to eq 1
          expect(subject.merged_cells.first.ref.to_s).to eq 'B2:D2'
        end
        it 'should delete merged cell' do
          subject.delete_row(1)
          expect(subject.merged_cells.size).to eq 0
        end
      end
      context 'merged vertical two cells' do
        # | A1 | B1     | C1 |
        # | A2 | MERGED | C2 |
        # | A3 |        | C3 |
        # | A4 | B4     | C4 |
        before do
          subject.merge_cells(1, 1, 2, 1)
          expect(subject.merged_cells.size).to eq 1
          expect(subject.merged_cells.first.ref.to_s).to eq 'B2:B3'
        end
        it 'should delete merged cell' do
          subject.delete_row(1)
          expect(subject.merged_cells.size).to eq 0
        end
      end

      context 'merged three or more rows' do
        # | A1 | B1 | C1 | D1 | E1 |
        # | A2 |              | E2 |
        # | A3 |    MERGED    | E3 |
        # | A4 |              | E4 |
        # | A5 | B5 | C5 | D5 | E5 |
        before do
          subject.merge_cells(1, 1, 3, 3)
          expect(subject.merged_cells.size).to eq 1
          expect(subject.merged_cells.first.ref.to_s).to eq 'B2:D4'
        end

        # | A2 |              | E2 |
        # | A3 |    MERGED    | E3 |
        # | A4 |              | E4 |
        # | A5 | B5 | C5 | D5 | E5 |
        it 'should updates merged cell when delete above the cell' do
          subject.delete_row(0)
          expect(subject.merged_cells.size).to eq 1
          expect(subject.merged_cells.first.ref.to_s).to eq 'B1:D3'
        end

        # | A1 | B1 | C1 | D1 | E1 |
        # | A3 |    MERGED    | E3 |
        # | A4 |              | E4 |
        # | A5 | B5 | C5 | D5 | E5 |
        it 'should updates merged cell when delete top of the cell' do
          subject.delete_row(1)
          expect(subject.merged_cells.size).to eq 1
          expect(subject.merged_cells.first.ref.to_s).to eq 'B2:D3'
        end

        # | A1 | B1 | C1 | D1 | E1 |
        # | A2 |    MERGED    | E2 |
        # | A4 |              | E4 |
        # | A5 | B5 | C5 | D5 | E5 |
        it 'should updates merged cell when delete middle of the cell' do
          subject.delete_row(2)
          expect(subject.merged_cells.size).to eq 1
          expect(subject.merged_cells.first.ref.to_s).to eq 'B2:D3'
        end

        # | A1 | B1 | C1 | D1 | E1 |
        # | A2 |    MERGED    | E2 |
        # | A3 |              | E3 |
        # | A5 | B5 | C5 | D5 | E5 |
        it 'should updates merged cell when delete bottom of the cell' do
          subject.delete_row(3)
          expect(subject.merged_cells.size).to eq 1
          expect(subject.merged_cells.first.ref.to_s).to eq 'B2:D3'
        end

        # | A1 | B1 | C1 | D1 | E1 |
        # | A2 |              | E2 |
        # | A3 |    MERGED    | E3 |
        # | A4 |              | E4 |
        it 'should not updates merged cell when ldelete below the cell' do
          subject.delete_row(4)
          expect(subject.merged_cells.size).to eq 1
          expect(subject.merged_cells.first.ref.to_s).to eq 'B2:D4'
        end
      end
    end

    it 'should not make empty merged_cells when a worksheet does not have a merged cell' do
      # If a worksheet has empty merged_cells, the xlsx file has an XML error and has to repair.
      subject.delete_row(0)
      expect(subject.merged_cells).to be_nil
    end
  end

  describe '.insert_row' do
    it 'should insert a row at index specified, "pushing" everything else "down"' do
      old_cell = subject[0][0]
      old_cell_value = old_cell.value.to_s
      old_cell_formula = old_cell.formula.expression.to_s

      subject.insert_row(0)
      expect(subject[0][0]).to be_nil
      expect(subject[1][0].value).to eq(old_cell_value)
      expect(subject[1][0].formula.expression.to_s).to eq(old_cell_formula)

      subject.insert_row(7)
      expect(subject[7][0].is_underlined).to be_nil
    end

    it 'should insert a row skipping nil rows that might exist' do
      subject.sheet_data.rows << nil << nil
      rows = subject.sheet_data.rows.size
      subject.insert_row(rows)
      expect(subject[rows - 1]).to be_nil
    end

    it 'should insert a row at index specified, copying styles from row "above"' do
      subject.change_row_font_name(0, 'Courier')
      subject.insert_row(1)
      expect(subject.get_row_font_name(1)).to eq('Courier')
    end

    it 'should preserve (rather than fix) formulas that reference cells "pushed down" rows' do
      subject.add_cell(5, 0, nil, 'SUM(A1:A4)')
      subject.insert_row(0)
      expect(subject[6][0].formula.expression).to eq('SUM(A1:A4)')
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.insert_row(-1)
      }.to raise_error(RuntimeError)
    end

    it 'should expand matrix to fit argument if nonnegative' do
      expect(subject.sheet_data.size).to eq(11)
      subject.insert_row(11)
      expect(subject.sheet_data.size).to eq(13)
    end

    it 'should properly reindex the cells' do
      subject.sheet_data.rows.each_with_index { |row, r|
        if (r == SKIP_ROW_COL) then
          expect(row).to be_nil
        else
          row.cells.each_with_index { |cell, c|
            if (c == SKIP_ROW_COL) then
              expect(cell).to be_nil
            else
              expect(cell.row).to eq(r)
              expect(cell.column).to eq(c)
            end
          }
        end
      }
    end

    describe 'merged_cells updating' do
      # | A1 | B1 | C1 | D1 |
      # | A2 | MERGED  | D2 |
      # | A3 |         | D3 |
      # | A4 | B4 | C4 | D4 |
      before do
        subject.merge_cells(1, 1, 2, 2)
        expect(subject.merged_cells.size).to eq 1
        expect(subject.merged_cells.first.ref.to_s).to eq 'B2:C3'
      end

      # | A1 | B1 | C1 | D1 |
      # |    |    |    |    |
      # | A2 | MERGED  | D2 |
      # | A3 |         | D3 |
      # | A4 | B4 | C4 | D4 |
      it 'should updates merged cell when insert above the cell' do
        subject.insert_row(1)
        expect(subject.merged_cells.size).to eq 1
        expect(subject.merged_cells.first.ref.to_s).to eq 'B3:C4'
      end

      # | A1 | B1 | C1 | D1 |
      # | A2 |         | D2 |
      # |    | MERGED  |    |
      # | A3 |         | D3 |
      # | A4 | B4 | C4 | D4 |
      it 'should updates merged cell when insert into the cell' do
        subject.insert_row(2)
        expect(subject.merged_cells.size).to eq 1
        expect(subject.merged_cells.first.ref.to_s).to eq 'B2:C4'
      end

      # | A1 | B1 | C1 | D1 |
      # | A2 | MERGED  | D2 |
      # | A3 |         | D3 |
      # |    |    |    |    |
      # | A4 | B4 | C4 | D4 |
      it 'should not updates merged cell when insert below the cell' do
        subject.insert_row(3)
        expect(subject.merged_cells.size).to eq 1
        expect(subject.merged_cells.first.ref.to_s).to eq 'B2:C3'
      end
    end

    it 'should not make empty merged_cells when a worksheet does not have a merged cell' do
      # If a worksheet has empty merged_cells, the xlsx file has an XML error and has to repair.
      subject.insert_row(0)
      expect(subject.merged_cells).to be_nil
    end
  end

  describe '.delete_column' do
    it 'should delete a column at index specified, "pushing" everything else "left"' do
      subject.delete_column(0)
      expect(subject[0][0].value).to eq('1:0')
      expect(subject[0][0].formula.expression.to_s).to eq('F1:0')
      expect(subject[0][0].row).to eq(0)
    end

    it 'should delete a column at index specified, "pushing" styles "left"' do
      subject.change_column_font_name(1, 'Courier')
      subject.delete_column(0)
      expect(subject.get_column_font_name(0)).to eq('Courier')
    end

    it 'should preserve (rather than fix) formulas that reference cells in "pushed left" columns' do
      subject.add_cell(0, 4, nil, 'SUM(A1:D1)')
      subject.delete_column(0)
      expect(subject[0][3].formula.expression).to eq('SUM(A1:D1)')
    end

    it 'should update cell indices after deleting the column' do
      subject.delete_column(2)

      subject.sheet_data.rows.each_with_index { |row, r|
        if (r == SKIP_ROW_COL) then
          expect(row).to be_nil
        else
          row.cells.each_with_index { |cell, c|
            if (SKIP_ROW_COL - 1 == c) then
              expect(cell).to be_nil
            else
              expect(cell.row).to eq(r)
              expect(cell.column).to eq(c)
            end
          }
        end
      }
    end

    it 'should cause error if negative argument is passed in' do
      expect {
        subject.delete_column(-1)
      }.to raise_error(RuntimeError)
    end

    it 'should properly reindex the cells' do
      subject.sheet_data.rows.each_with_index { |row, r|
        if (r == SKIP_ROW_COL) then
          expect(row).to be_nil
        else
          row.cells.each_with_index { |cell, c|
            if (c == SKIP_ROW_COL) then
              expect(cell).to be_nil
            else
              expect(cell.row).to eq(r)
              expect(cell.column).to eq(c)
            end
          }
        end
      }
    end

    describe 'merged_cells updating' do
      context 'merged cells in the column' do
        # | A1 | B1     | C1 |
        # | A2 |        | C2 |
        # | A3 | MERGED | C3 |
        # | A4 |        | C4 |
        # | A5 | B5     | C5 |
        before do
          subject.merge_cells(1, 1, 3, 1)
          expect(subject.merged_cells.size).to eq 1
          expect(subject.merged_cells.first.ref.to_s).to eq 'B2:B4'
        end
        it 'should delete merged cell' do
          subject.delete_column(1)
          expect(subject.merged_cells.size).to eq 0
        end
      end
      context 'merged horizontal two cells' do
        # | A1 | B1 | C1 | D1 |
        # | A2 | MERGED  | D2 |
        # | A3 | B3 | C3 | D3 |
        before do
          subject.merge_cells(1, 1, 1, 2)
          expect(subject.merged_cells.size).to eq 1
          expect(subject.merged_cells.first.ref.to_s).to eq 'B2:C2'
        end
        it 'should delete merged cell' do
          subject.delete_column(1)
          expect(subject.merged_cells.size).to eq 0
        end
      end
      context 'merged three or more columns' do
        # | A1 | B1 | C1 | D1 | E1 |
        # | A2 |              | E2 |
        # | A3 |    MERGED    | E3 |
        # | A4 |              | E4 |
        # | A5 | B5 | C5 | D5 | E5 |
        before do
          subject.merge_cells(1, 1, 3, 3)
          expect(subject.merged_cells.size).to eq 1
          expect(subject.merged_cells.first.ref.to_s).to eq 'B2:D4'
        end
        # | B1 | C1 | D1 | E1 |
        # |              | E2 |
        # |    MERGED    | E3 |
        # |              | E4 |
        # | B5 | C5 | D5 | E5 |
        it 'should updates merged cell when delete before the cell' do
          subject.delete_column(0)
          expect(subject.merged_cells.size).to eq 1
          expect(subject.merged_cells.first.ref.to_s).to eq 'A2:C4'
        end
        # | A1 | C1 | D1 | E1 |
        # | A2 |         | E2 |
        # | A3 | MERGED  | E3 |
        # | A4 |         | E4 |
        # | A5 | C5 | D5 | E5 |
        it 'should updates merged cell when delete left of the cell' do
          subject.delete_column(1)
          expect(subject.merged_cells.size).to eq 1
          expect(subject.merged_cells.first.ref.to_s).to eq 'B2:C4'
        end
        # | A1 | B1 | D1 | E1 |
        # | A2 |         | E2 |
        # | A3 | MERGED  | E3 |
        # | A4 |         | E4 |
        # | A5 | B5 | D5 | E5 |
        it 'should updates merged cell when delete center of the cell' do
          subject.delete_column(2)
          expect(subject.merged_cells.size).to eq 1
          expect(subject.merged_cells.first.ref.to_s).to eq 'B2:C4'
        end
        # | A1 | B1 | C1 | E1 |
        # | A2 |         | E2 |
        # | A3 | MERGED  | E3 |
        # | A4 |         | E4 |
        # | A5 | B5 | C5 | E5 |
        it 'should updates merged cell when delete right of the cell' do
          subject.delete_column(3)
          expect(subject.merged_cells.size).to eq 1
          expect(subject.merged_cells.first.ref.to_s).to eq 'B2:C4'
        end
        # | A1 | B1 | C1 | D1 |
        # | A2 |              |
        # | A3 |    MERGED    |
        # | A4 |              |
        # | A5 | B5 | C5 | D5 |
        it 'should not updates merged cell when delete after the cell' do
          subject.delete_column(4)
          expect(subject.merged_cells.size).to eq 1
          expect(subject.merged_cells.first.ref.to_s).to eq 'B2:D4'
        end
      end
    end

    it 'should not make empty merged_cells when a worksheet does not have a merged cell' do
      # If a worksheet has empty merged_cells, the xlsx file has an XML error and has to repair.
      subject.delete_column(0)
      expect(subject.merged_cells).to be_nil
    end
  end

  describe '.insert_column' do
    it 'should insert a column at index specified, "pushing" everything else "right"' do
      old_cell = subject[0][0]
      old_cell_value = old_cell.value.to_s
      old_cell_formula = old_cell.formula.expression.to_s

      subject.insert_column(0)
      expect(subject[0][0]).to be_nil
      expect(subject[0][1].value).to eq(old_cell_value)
      expect(subject[0][1].formula.expression.to_s).to eq(old_cell_formula)
    end

    it 'should insert a column at index specified, copying styles from column to "left"' do
      subject.change_column_font_name(0, 'Courier')
      subject.insert_column(1)
      expect(subject.get_column_font_name(1)).to eq('Courier')
    end

    it 'should insert a column at 0 without copying any styles, when passed 0 as column index' do
      subject.change_column_font_name(0, 'Courier')
      subject.insert_column(0)
      expect(subject.get_column_font_name(0)).to eq('Verdana') # not courier
    end

    it 'should preserve (rather than fix) formulas that reference cells in "pushed right" column' do
      subject.add_cell(0, 5, nil, 'SUM(A1:D1)')
      subject.insert_column(0)
      expect(subject[0][6].formula.expression).to eq('SUM(A1:D1)')
    end

    it 'should update cell indices after deleting the column' do
      subject.insert_column(5)
      subject[0].cells.each_with_index { |cell, i|
        next if cell.nil?
        expect(cell.column).to eq(i)
      }
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.insert_column(-1)
      }.to raise_error(RuntimeError)
    end

    it 'should properly reindex the cells' do
      subject.sheet_data.rows.each_with_index { |row, r|
        if (r == SKIP_ROW_COL) then
          expect(row).to be_nil
        else
          row.cells.each_with_index { |cell, c|
            if (c == SKIP_ROW_COL) then
              expect(cell).to be_nil
            else
              expect(cell.row).to eq(r)
              expect(cell.column).to eq(c)
            end
          }
        end
      }
    end

    describe 'merged_cells updating' do
      # | A1 | B1 | C1 | D1 |
      # | A2 | MERGED  | D2 |
      # | A3 |         | D3 |
      # | A4 | B4 | C4 | D4 |
      before do
        subject.merge_cells(1, 1, 2, 2)
        expect(subject.merged_cells.size).to eq 1
        expect(subject.merged_cells.first.ref.to_s).to eq 'B2:C3'
      end

      # | A1 |    | B1 | C1 | D1 |
      # | A2 |    | MERGED  | D2 |
      # | A3 |    |         | D3 |
      # | A4 |    | B4 | C4 | D4 |
      it 'should updates merged cell when insert before the cell' do
        subject.insert_column(1)
        expect(subject.merged_cells.size).to eq 1
        expect(subject.merged_cells.first.ref.to_s).to eq 'C2:D3'
      end

      # | A1 | B1 |    | C1 | D1 |
      # | A2 |    MERGED    | D2 |
      # | A3 |              | D3 |
      # | A4 | B4 |    | C4 | D4 |
      it 'should updates merged cell when insert into the cell' do
        subject.insert_column(2)
        expect(subject.merged_cells.size).to eq 1
        expect(subject.merged_cells.first.ref.to_s).to eq 'B2:D3'
      end

      # | A1 | B1 | C1 |    | D1 |
      # | A2 | MERGED  |    | D2 |
      # | A3 |         |    | D3 |
      # | A4 | B4 | C4 |    | D4 |
      it 'should not updates merged cell when insert after the cell' do
        subject.insert_column(3)
        expect(subject.merged_cells.size).to eq 1
        expect(subject.merged_cells.first.ref.to_s).to eq 'B2:C3'
      end
    end

    it 'should not make empty merged_cells when a worksheet does not have a merged cell' do
      # If a worksheet has empty merged_cells, the xlsx file has an XML error and has to repair.
      subject.insert_column(0)
      expect(subject.merged_cells).to be_nil
    end
  end

  describe '.insert_cell' do
    it 'should simply add a cell if no shift argument is specified' do
      subject.insert_cell(0, 0, 'test')
      expect(subject[0][0].value).to eq('test')
      expect(subject[0][1].value).to eq('1:0')
      expect(subject[1][0].value).to eq('0:1')
    end

    it 'should shift cells to the right if :right is specified' do
      subject.insert_cell(0, 0, 'test', nil, :right)
      expect(subject[0][0].value).to eq('test')
      expect(subject[0][1].value).to eq('0:0')
      expect(subject[1][0].value).to eq('0:1')
    end

    it 'should update cell indices after inserting the cell' do
      subject.insert_cell(0, 0, 'test', nil, :right)
      subject.sheet_data.rows.each_with_index { |row, r|
        if (r == SKIP_ROW_COL) then
          expect(row).to be_nil
        else
          row.cells.each_with_index { |cell, c|
            if ((r == 0) && (SKIP_ROW_COL + 1 == c)) || ((r != 0) && (c == SKIP_ROW_COL)) then
              expect(cell).to be_nil
            else
              expect(cell.row).to eq(r)
              expect(cell.column).to eq(c)
            end
          }
        end
      }
    end

    it 'should shift cells down if :down is specified' do
      subject.insert_cell(0, 0, 'test', nil, :down)
      expect(subject[0][0].value).to eq('test')
      expect(subject[0][1].value).to eq('1:0')
      expect(subject[1][0].value).to eq('0:0')
    end

    it 'should cause error if shift argument is specified which is not :right or :down' do
      expect {
        subject.insert_cell(0, 0, 'test', nil, :up)
      }.to raise_error(RuntimeError)
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.insert_cell(-1, -1)
      }.to raise_error(RuntimeError)
    end
  end

  describe '.delete_cell' do
    it 'should make a cell nil if no shift argument specified' do
      old_cell = subject[0][0].inspect

      deleted = subject.delete_cell(0, 0)
      expect(subject[0][0]).to be_nil
      expect(old_cell).to eq(deleted.inspect)
    end

    it 'should return nil if a cell which is out of range is specified' do
      expect(subject.delete_cell(12, 12)).to be_nil
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.delete_cell(-1, -1)
      }.to raise_error(RuntimeError)
    end

    it 'should shift cells to the right of the deleted cell left if :left is specified' do
      subject.delete_cell(0, 0, :left)
      expect(subject[0][0].value).to eq('1:0')
    end

    it 'should update cell indices after deleting the cell' do
      subject.delete_cell(4, 0, :left)
      subject[0].cells.each_with_index { |cell, i|
        if i == SKIP_ROW_COL then
          expect(cell).to be_nil
        else
          expect(cell.column).to eq(i)
        end
      }
    end

    it 'should shift cells below the deleted cell up if :up is specified' do
      subject.delete_cell(0, 0, :up)
      expect(subject[0][0].value).to eq('0:1')
    end

    it 'should cause en error if an argument other than :left, :up, or nil is specified for shift' do
      expect {
        subject.delete_cell(0, 0, :down)
      }.to raise_error(RuntimeError)
    end
  end

  describe '.get_row_fill' do
    it 'should return white (ffffff) if no fill color specified for row' do
      expect(subject.get_row_fill(0)).to eq('ffffff')
    end

    it 'should correctly reflect fill color if specified for row' do
      subject.change_row_fill(0, '000000')
      expect(subject.get_row_fill(0)).to eq('000000')
    end

    it 'should return nil if a row which does not exist is passed in' do
      expect(subject.get_row_fill(11)).to be_nil
    end
  end

  describe '.get_row_font_name' do
    it 'should correctly reflect font name for row' do
      subject.change_row_font_name(0, 'Courier')
      expect(subject.get_row_font_name(0)).to eq('Courier')
    end

    it 'should return nil if a (nonnegative) row which does not exist is passed in' do
      expect(subject.get_row_font_name(11)).to be_nil
    end
  end

  describe '.get_row_font_size' do
    it 'should correctly reflect font size for row' do
      subject.change_row_font_size(0, 30)
      expect(subject.get_row_font_size(0)).to eq(30)
    end

    it 'should return nil if a (nonnegative) row which does not exist is passed in' do
      expect(subject.get_row_font_size(11)).to be_nil
    end
  end

  describe '.get_row_font_color' do
    it 'should correctly reflect font color for row' do
      subject.change_row_font_color(0, '0f0f0f')
      expect(subject.get_row_font_color(0)).to eq('0f0f0f')
    end

    it 'should return nil if a (nonnegative) row which does not exist is passed in' do
      expect(subject.get_row_font_color(11)).to be_nil
    end
  end

  describe '.is_row_italicized' do
    it 'should correctly return whether row is italicized' do
      subject.change_row_italics(0, true)
      expect(subject.is_row_italicized(0)).to eq(true)
    end

    it 'should return nil if a (nonnegative) row which does not exist is passed in' do
      expect(subject.is_row_italicized(11)).to be_nil
    end
  end

  describe '.is_row_bolded' do
    it 'should correctly return whether row is bolded' do
      subject.change_row_bold(0, true)
      expect(subject.is_row_bolded(0)).to eq(true)
    end

    it 'should return nil if a (nonnegative) row which does not exist is passed in' do
      expect(subject.is_row_bolded(11)).to be_nil
    end
  end

  describe '.is_row_underlined' do
    it 'should correctly return whether row is underlined' do
      subject.change_row_underline(0, true)
      expect(subject.is_row_underlined(0)).to eq(true)
    end

    it 'should return nil if a (nonnegative) row which does not exist is passed in' do
      expect(subject.is_row_underlined(11)).to be_nil
    end
  end

  describe '.is_row_struckthrough' do
    it 'should correctly return whether row is struckthrough' do
      subject.change_row_strikethrough(0, true)
      expect(subject.is_row_struckthrough(0)).to eq(true)
    end

    it 'should return nil if a (nonnegative) row which does not exist is passed in' do
      expect(subject.is_row_struckthrough(11)).to be_nil
    end
  end

  describe '.get_row_height' do
    it 'should return 13 if no height specified for row' do
      expect(subject.get_row_height(0)).to eq(13)
    end

    it 'should correctly reflect height if specified for row' do
      subject.change_row_height(0, 30)
      expect(subject.get_row_height(0)).to eq(30)
    end

    it 'should return default row height if a row which does not exist is passed in' do
      expect(subject.get_row_height(11)).to eq(13)
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.get_row_height(-1)
      }.to raise_error(RuntimeError)
    end
  end

  describe '.get_row_alignment' do
    it 'should return nil if no horizontal alignment specified for row' do
      expect(subject.get_row_alignment(0, true)).to be_nil
    end

    it 'should return nil if a row which does not exist is passed in' do
      expect(subject.get_row_alignment(11, true)).to be_nil
    end

    it 'should return correct horizontal alignment if it is set for that row' do
      subject.change_row_horizontal_alignment(0, 'center')
      expect(subject.get_row_alignment(0, true)).to eq('center')
    end

    it 'should return nil if no alignment specified for row' do
      expect(subject.get_row_alignment(0, false)).to be_nil
    end

    it 'should return nil if a row which does not exist is passed in' do
      expect(subject.get_row_alignment(11, false)).to be_nil
    end

    it 'should return correct vertical alignment if it is set for that row' do
      subject.change_row_vertical_alignment(0, 'center')
      expect(subject.get_row_alignment(0, false)).to eq('center')
    end
  end

  describe '.get_row_border' do
    it 'should return nil if no border is specified for that row in that direction' do
      expect(subject.get_row_border(0, :top)).to be_nil
    end

    it 'should return type of border that this row has on top' do
      subject.change_row_border(0, :top, 'thin')
      expect(subject.get_row_border(0, :top)).to eq('thin')
    end

    it 'should return nil if a row which does not exist is passed in' do
      expect(subject.get_row_border(11, :top)).to be_nil
    end
  end

  describe '.get_column_font_name' do
    it 'should correctly reflect font name for column' do
      subject.change_column_font_name(0, 'Courier')
      expect(subject.get_column_font_name(0)).to eq('Courier')
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.get_column_font_name(-1)
      }.to raise_error(RuntimeError)
    end

    it 'should return default font if a (nonnegative) column which does not exist is passed in' do
      expect(subject.get_column_font_name(11)).to eq('Verdana')
    end
  end

  describe '.get_column_font_size' do
    it 'should correctly reflect font size for column' do
      subject.change_column_font_size(0, 30)
      expect(subject.get_column_font_size(0)).to eq(30)
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.get_column_font_size(-1)
      }.to raise_error(RuntimeError)
    end

    it 'should return default font size if a column which does not exist is passed in' do
      expect(subject.get_column_font_size(11)).to eq(10)
    end
  end

  describe '.get_column_font_color' do
    it 'should correctly reflect font color for column' do
      subject.change_column_font_color(0, '0f0f0f')
      expect(subject.get_column_font_color(0)).to eq('0f0f0f')
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.get_column_font_color(-1)
      }.to raise_error(RuntimeError)
    end

    it 'should return default color (000000) if a (nonnegative) column which does not exist is passed in' do
      expect(subject.get_column_font_color(11)).to eq('000000')
    end

    it 'should return default color (000000) if no rgb font color is specified' do
      expect(subject.get_column_font_color(0)).to eq('000000')
    end
  end

  describe '.is_column_italicized' do
    it 'should correctly return whether column is italicized' do
      subject.change_column_italics(0, true)
      expect(subject.is_column_italicized(0)).to eq(true)
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.is_column_italicized(-1)
      }.to raise_error(RuntimeError)
    end

    it 'should return nil if a (nonnegative) column which does not exist is passed in' do
      expect(subject.is_column_italicized(11)).to be_nil
    end
  end

  describe '.is_column_bolded' do
    it 'should correctly return whether column is bolded' do
      subject.change_column_bold(0, true)
      expect(subject.is_column_bolded(0)).to eq(true)
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.is_column_bolded(-1)
      }.to raise_error(RuntimeError)
    end

    it 'should return nil if a (nonnegative) column which does not exist is passed in' do
      expect(subject.is_column_bolded(11)).to be_nil
    end
  end

  describe '.is_column_underlined' do
    it 'should correctly return whether column is underlined' do
      subject.change_column_underline(0, true)
      expect(subject.is_column_underlined(0)).to eq(true)
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.is_column_underlined(-1)
      }.to raise_error(RuntimeError)
    end

    it 'should return nil if a (nonnegative) column which does not exist is passed in' do
      expect(subject.is_column_underlined(11)).to be_nil
    end
  end

  describe '.is_column_struckthrough' do
    it 'should correctly return whether column is struckthrough' do
      subject.change_column_strikethrough(0, true)
      expect(subject.is_column_struckthrough(0)).to eq(true)
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.is_column_struckthrough(-1)
      }.to raise_error(RuntimeError)
    end

    it 'should return nil if a (nonnegative) column which does not exist is passed in' do
      expect(subject.is_column_struckthrough(11)).to be_nil
    end
  end

  describe '.get_column_width_raw' do
    it 'should return nil if no width specified for column' do
      expect(subject.get_column_width_raw(0)).to be_nil
    end

    it 'should correctly reflect width if specified for column' do
      subject.change_column_width_raw(0, 30.123)
      expect(subject.get_column_width_raw(0)).to eq(30.123)
    end

    it 'should return nil for a column that does not exist' do
      expect(subject.get_column_width_raw(11)).to be_nil
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.get_column_width_raw(-1)
      }.to raise_error(RuntimeError)
    end
  end

  describe '.get_column_width' do
    it 'should return default width if no width specified for column' do
      expect(subject.get_column_width(0)).to eq(RubyXL::ColumnRange::DEFAULT_WIDTH)
    end

    it 'should correctly reflect width if specified for column' do
      subject.change_column_width(0, 15)
      expect(subject.get_column_width(0)).to eq(15)
    end

    it 'should return default width for a column that does not exist' do
      expect(subject.get_column_width(11)).to eq(RubyXL::ColumnRange::DEFAULT_WIDTH)
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.get_column_width(-1)
      }.to raise_error(RuntimeError)
    end
  end

  describe '.get_column_fill' do
    it 'should return white (ffffff) if no fill color specified for column' do
      expect(subject.get_column_fill(0)).to eq('ffffff')
    end

    it 'should correctly reflect fill color if specified for column' do
      subject.change_column_fill(0, '000000')
      expect(subject.get_column_fill(0)).to eq('000000')
    end

    it 'should return nil if a column which does not exist is passed in' do
      expect(subject.get_column_fill(11)).to eq('ffffff')
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.get_column_fill(-1)
      }.to raise_error(RuntimeError)
    end
  end

  describe '.get_column_horizontal_alignment' do
    it 'should return nil if no alignment specified for column' do
      expect(subject.get_column_alignment(0, :horizontal)).to be_nil
    end

    it 'should return nil if a column which does not exist is passed in' do
      expect(subject.get_column_alignment(11, :horizontal)).to be_nil
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.get_column_alignment(-1, :horizontal)
      }.to raise_error(RuntimeError)
    end

    it 'should return correct horizontal alignment if it is set for that column' do
      subject.change_column_horizontal_alignment(0, 'center')
      expect(subject.get_column_alignment(0, :horizontal)).to eq('center')
    end
  end

  describe '.get_column_vertical_alignment' do
    it 'should return nil if no alignment specified for column' do
      expect(subject.get_column_alignment(0, :vertical)).to be_nil
    end

    it 'should return nil if a column which does not exist is passed in' do
      expect(subject.get_column_alignment(11, :vertical)).to be_nil
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.get_column_alignment(-1, :vertical)
      }.to raise_error(RuntimeError)
    end

    it 'should return correct vertical alignment if it is set for that column' do
      subject.change_column_vertical_alignment(0, 'center')
      expect(subject.get_column_alignment(0, :vertical)).to eq('center')
    end
  end

  describe '.get_column_border' do
    it 'should return nil if no border is specified for that column in that direction' do
      expect(subject.get_column_border(0, :diagonal)).to be_nil
    end

    it 'should return type of border that this column has on diagonal' do
      subject.change_column_border(0, :diagonal, 'thin')
      expect(subject.get_column_border(0, :diagonal)).to eq('thin')
    end

    it 'should cause error if a negative argument is passed in' do
      expect {
        subject.get_column_border(-1, :diagonal)
      }.to raise_error(RuntimeError)
    end

    it 'should return nil if a column which does not exist is passed in' do
      expect(subject.get_column_border(11, :diagonal)).to be_nil
    end
  end

  describe '@column_range' do
    it 'should properly handle range addition and modification' do
      # Ranges should be empty for brand new worskeet
      expect(subject.cols.size).to eq(0)

      # Range should be created if the column has not been touched before
      subject.change_column_width(0, 30)
      expect(subject.get_column_width(0)).to eq(30)
      expect(subject.cols.size).to eq(1)

      # Existing range should be reused
      subject.change_column_width(0, 20)
      expect(subject.get_column_width(0)).to eq(20)
      expect(subject.cols.size).to eq(1)

      # Creation of the new range should not affect previously changed columns
      subject.change_column_width(1, 30)
      expect(subject.get_column_width(1)).to eq(30)
      expect(subject.get_column_width(0)).to eq(20)
      expect(subject.cols.size).to eq(2)

      subject.cols.clear
      subject.cols << RubyXL::ColumnRange.new(:min => 1, :max => 9, :width => 33) # Note that this is raw width

      r = subject.cols.locate_range(3)
      expect(r.min).to eq(1)
      expect(r.max).to eq(9)

      # When a column is modified at the beginning of the range, it should shrink to the right
      subject.change_column_width(0, 20)
      expect(subject.cols.size).to eq(2)
      expect(subject.get_column_width(0)).to eq(20)
      expect(subject.get_column_width(1)).to eq(32)

      r = subject.cols.locate_range(3)
      expect(r.min).to eq(2)
      expect(r.max).to eq(9)

      # When a column is modified at the beginning of the range, it should shrink to the left
      subject.change_column_width(8, 30)
      expect(subject.cols.size).to eq(3)
      expect(subject.get_column_width(8)).to eq(30)

      r = subject.cols.locate_range(3)
      expect(r.min).to eq(2)
      expect(r.max).to eq(8)

      # When a column is modified in the middle of the range, it should split into two
      subject.change_column_width(4, 15)
      expect(subject.cols.size).to eq(5)
      expect(subject.get_column_width(3)).to eq(32)

      r = subject.cols.locate_range(2)
      expect(r.min).to eq(2)
      expect(r.max).to eq(4)

      expect(subject.get_column_width(4)).to eq(15)

      r = subject.cols.locate_range(4)
      expect(r.min).to eq(5)
      expect(r.max).to eq(5)

      expect(subject.get_column_width(5)).to eq(32)

      r = subject.cols.locate_range(6)
      expect(r.min).to eq(6)
      expect(r.max).to eq(8)
    end
  end

  describe 'forbidden sheet names' do
    it 'should stream a workbook successfully' do
      subject.sheet_name = 'Test Name'
      subject.workbook.stream
    end

    it 'should throw an error when forbidden characters are used in the sheet name' do
      subject.sheet_name = 'Some [Special] Name'
      expect { subject.workbook.stream }.to raise_error(RuntimeError)
    end

    it 'should throw an error when forbidden name is used' do
      subject.sheet_name = 'History'
      expect { subject.workbook.stream }.to raise_error(RuntimeError)
    end
  end
end
