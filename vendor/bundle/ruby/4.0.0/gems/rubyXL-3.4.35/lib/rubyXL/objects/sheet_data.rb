require 'rubyXL/objects/ooxml_object'
require 'rubyXL/objects/simple_types'
require 'rubyXL/objects/text'
require 'rubyXL/objects/formula'
require 'rubyXL/cell'

module RubyXL
  # http://msdn.microsoft.com/en-us/library/documentformat.openxml.spreadsheet.cellvalues(v=office.14).aspx
  module DataType
    SHARED_STRING = 's'
    RAW_STRING    = 'str'
    INLINE_STRING = 'inlineStr'
    ERROR         = 'e'
    BOOLEAN       = 'b'
    NUMBER        = 'n'
    DATE          = 'd' # Only available in Office2010.
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_v-1.html
  class CellValue < OOXMLObject
    define_attribute(:_, :string, :accessor => :value)
    define_attribute(:'xml:space', %w{ preserve })
    define_element_name 'v'

    def before_write_xml
      preserve_whitespace
      true
    end
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_c-2.html
  class Cell < OOXMLObject
    NUMBER_REGEXP = /\A-?\d+((?:\.\d+)?(?:e[+-]?\d+)?)?\Z/i

    define_attribute(:r,   :ref)
    define_attribute(:s,   :int,  :default => 0, :accessor => :style_index)
    define_attribute(:t,   RubyXL::ST_CellType,  :accessor => :datatype, :default => 'n')
    define_attribute(:cm,  :int,  :default => 0)
    define_attribute(:vm,  :int,  :default => 0)
    define_attribute(:ph,  :bool, :default => false)
    define_child_node(RubyXL::Formula,   :accessor => :formula)
    define_child_node(RubyXL::CellValue, :accessor => :value_container)
    define_child_node(RubyXL::RichText) # is
    define_element_name 'c'

    attr_accessor :worksheet

    def index_in_collection
      r.col_range.begin
    end

    def row
      r&.first_row
    end

    def row=(v)
      self.r = RubyXL::Reference.new(v, column || 0)
    end

    def column
      r&.first_col
    end

    def column=(v)
      self.r = RubyXL::Reference.new(row || 0, v)
    end

    def raw_value
      value_container&.value
    end

    def raw_value=(v)
      self.value_container ||= RubyXL::CellValue.new
      value_container.value = v
    end

    def get_cell_xf
      workbook.stylesheet.cell_xfs[self.style_index || 0]
    end

    def get_cell_font
      workbook.stylesheet.fonts[get_cell_xf.font_id]
    end

    def get_cell_border
      workbook.stylesheet.borders[get_cell_xf.border_id]
    end

    def number_format
      workbook.stylesheet.get_number_format_by_id(get_cell_xf.num_fmt_id)
    end

    def is_date?
      return false unless # Only fully numeric values can be dates
        case raw_value
        when Numeric then true
        when String  then raw_value =~ NUMBER_REGEXP
        else false
        end

      self.number_format&.is_date_format?
    end

    # Gets massaged value of the cell, converting datatypes to those known to Ruby (that includes
    # stripping any special formatting from RichText).
    def value(args = {})
      r = self.raw_value

      case datatype
      when RubyXL::DataType::SHARED_STRING then workbook.shared_strings_container[r.to_i].to_s
      when RubyXL::DataType::INLINE_STRING then is.to_s
      when RubyXL::DataType::RAW_STRING    then raw_value
      when RubyXL::DataType::DATE          then raw_value && DateTime.parse(raw_value)
      else
        if is then is.to_s
        elsif is_date? then workbook.num_to_date(r.to_f)
        elsif r.is_a?(String) && (r =~ NUMBER_REGEXP) then # Numeric
          if Regexp.last_match(1) != '' then r.to_f
          else r.to_i
          end
        else r
        end
      end
    end

    def inspect
      str = "#<#{self.class}(#{row},#{column}): #{raw_value.inspect}"
      str << " =#{self.formula.expression}" if self.formula
      str << ", datatype=#{self.datatype.inspect}, style_index=#{self.style_index.inspect}>"
      return str
    end

    include LegacyCell
  end

#TODO# <row r="1" spans="1:1" x14ac:dyDescent="0.25">

  # http://www.datypic.com/sc/ooxml/e-ssml_row-1.html
  class Row < OOXMLObject
    define_attribute(:r,            :int)
    define_attribute(:spans,        :string)
    define_attribute(:s,            :int,   :default => 0, :accessor => :style_index)
    define_attribute(:customFormat, :bool,  :default => false)
    define_attribute(:ht,           :double)
    define_attribute(:hidden,       :bool,  :default => false)
    define_attribute(:customHeight, :bool,  :default => false)
    define_attribute(:outlineLevel, :int,   :default => 0)
    define_attribute(:collapsed,    :bool,  :default => false)
    define_attribute(:thickTop,     :bool,  :default => false)
    define_attribute(:thickBot,     :bool,  :default => false)
    define_attribute(:ph,           :bool,  :default => false)
    define_child_node(RubyXL::Cell, :collection => true, :accessor => :cells)
    define_element_name 'row'

    attr_accessor :worksheet

    def before_write_xml
      !(cells.nil? || cells.empty?)
    end

    def index_in_collection
      r - 1
    end

    def [](ind)
      cells[ind]
    end

    def size
      cells.size
    end

    def insert_cell_shift_right(c, col_index)
      cells.insert(col_index, c)
      update_cell_coords(col_index)
    end

    def delete_cell_shift_left(col_index)
      cells.delete_at(col_index)
      update_cell_coords(col_index)
    end

    def update_cell_coords(start_from_index)
      cells.drop(start_from_index).each_with_index { |cell, i|
        next if cell.nil?
        cell.column = start_from_index + i
      }
    end
    private :update_cell_coords

    def xf
      @worksheet.workbook.cell_xfs[self.style_index || 0]
    end

    def get_fill_color
      @worksheet.workbook.get_fill_color(xf)
    end

    def get_font
      @worksheet.workbook.fonts[xf.font_id]
    end

    DEFAULT_HEIGHT = 13
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_sheetData-1.html
  class SheetData < OOXMLObject
    define_child_node(RubyXL::Row, :collection => true, :accessor => :rows)
    define_element_name 'sheetData'

    def [](ind)
      rows[ind]
    end

    def size
      rows.size
    end
  end
end
