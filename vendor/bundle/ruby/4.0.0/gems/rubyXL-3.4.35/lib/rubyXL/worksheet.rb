module RubyXL
  module LegacyWorksheet
    TEXT_LENGTH_LIMIT_IN_CELL = 32767 # 2 ** 15 - 1

    include Enumerable

    def initialize(params = {})
      super
      self.workbook   = params[:workbook]
      self.sheet_name = params[:sheet_name]
      self.sheet_id   = params[:sheet_id]
      self.sheet_data = RubyXL::SheetData.new
      self.cols = RubyXL::ColumnRanges.new
      @comments = [] # Do not optimize! These are arrays, so they will share the pointer!
      @printer_settings = []
      @generic_storage = []
    end

    # allows for easier access to sheet_data
    def [](row = 0)
      sheet_data[row]
    end

    def each
      sheet_data.rows.each { |row| yield(row) }
    end

    def add_row(row_index = 0, params = {})
      new_row = RubyXL::Row.new(params)
      new_row.worksheet = self
      sheet_data.rows[row_index] = new_row
    end

    def add_cell(row_index = 0, column_index = 0, data = '', formula = nil, overwrite = true)
      validate_workbook
      validate_nonnegative(row_index)
      validate_nonnegative(column_index)
      row = sheet_data.rows[row_index] || add_row(row_index)

      c = row.cells[column_index]

      if overwrite || c.nil?
        c = RubyXL::Cell.new
        c.worksheet = self
        c.row = row_index
        c.column = column_index

        if formula then
          c.formula = RubyXL::Formula.new(:expression => formula)
          c.raw_value = data
        else
          case data
          when Numeric          then c.raw_value = data
          when String           then
            if data.length > TEXT_LENGTH_LIMIT_IN_CELL
              raise ArgumentError, "The maximum length of cell contents (text) is #{TEXT_LENGTH_LIMIT_IN_CELL} characters"
            end
            c.raw_value = data
            c.datatype = RubyXL::DataType::RAW_STRING
          when RubyXL::RichText then
            if data.to_s.length > TEXT_LENGTH_LIMIT_IN_CELL
              raise ArgumentError, "The maximum length of cell contents (text) is #{TEXT_LENGTH_LIMIT_IN_CELL} characters"
            end
            c.is = data
            c.datatype = RubyXL::DataType::INLINE_STRING
          when Time, Date, DateTime then
            c.raw_value = workbook.date_to_num(data)
          when NilClass then nil
          end
        end

        range = cols&.locate_range(column_index)
        c.style_index = row.style_index || range&.style_index || 0
        row.cells[column_index] = c
      end

      c
    end

    private

    # validates Workbook, ensures that this worksheet is in @workbook
    def validate_workbook
      unless @workbook.nil? || @workbook.worksheets.nil?
        return if @workbook.worksheets.any? { |sheet| sheet.equal?(self) }
      end

      raise "This worksheet #{self} is not in workbook #{@workbook}"
    end

    # Ensures that storage space for a cell with +row_index+ and +column_index+
    # exists in +sheet_data+ arrays, growing them up if necessary.
    def ensure_cell_exists(row_index, column_index = 0)
      validate_nonnegative(row_index)
      validate_nonnegative(column_index)

      sheet_data.rows[row_index] || add_row(row_index)
    end

    def validate_nonnegative(row_or_col)
      raise 'Row and Column arguments must be nonnegative' if row_or_col < 0
    end
    private :validate_nonnegative
  end
end
