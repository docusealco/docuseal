require 'rubyXL/objects/ooxml_object'
require 'rubyXL/objects/cell_style'
require 'rubyXL/objects/font'
require 'rubyXL/objects/fill'
require 'rubyXL/objects/border'
require 'rubyXL/objects/extensions'

module RubyXL
  # http://www.datypic.com/sc/ooxml/e-ssml_numFmt-1.html
  class NumberFormat < OOXMLObject
    define_attribute(:numFmtId,   :int,    :required => true)
    define_attribute(:formatCode, :string, :required => true)
    define_element_name 'numFmt'

    def is_date_format?
      #             v-------- Toss all the escaped chars -------v v--- and see if any date-related remained
      !!(format_code.gsub(/("[^"]*"|\[[^\]]*\]|[\\_*].)/i, '') =~ /[dmyhs]/i)
    end
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_numFmts-1.html
  class NumberFormats < OOXMLContainerObject
    define_child_node(RubyXL::NumberFormat, :collection => :with_count)
    define_element_name 'numFmts'

    # https://support.office.com/en-us/article/5026bbd6-04bc-48cd-bf33-80f18b4eae68
    DEFAULT_NUMBER_FORMATS = self.new(:_ => [
      RubyXL::NumberFormat.new(:num_fmt_id => 1, :format_code => '0'),
      RubyXL::NumberFormat.new(:num_fmt_id => 2, :format_code => '0.00'),
      RubyXL::NumberFormat.new(:num_fmt_id => 3, :format_code => '#, ##0'),
      RubyXL::NumberFormat.new(:num_fmt_id => 4, :format_code => '#, ##0.00'),
      RubyXL::NumberFormat.new(:num_fmt_id => 5, :format_code => '$#, ##0_);($#, ##0)'),
      RubyXL::NumberFormat.new(:num_fmt_id => 6, :format_code => '$#, ##0_);[Red]($#, ##0)'),
      RubyXL::NumberFormat.new(:num_fmt_id => 7, :format_code => '$#, ##0.00_);($#, ##0.00)'),
      RubyXL::NumberFormat.new(:num_fmt_id => 8, :format_code => '$#, ##0.00_);[Red]($#, ##0.00)'),
      RubyXL::NumberFormat.new(:num_fmt_id => 9, :format_code => '0%'),
      RubyXL::NumberFormat.new(:num_fmt_id => 10, :format_code => '0.00%'),
      RubyXL::NumberFormat.new(:num_fmt_id => 11, :format_code => '0.00E+00'),
      RubyXL::NumberFormat.new(:num_fmt_id => 12, :format_code => '# ?/?'),
      RubyXL::NumberFormat.new(:num_fmt_id => 13, :format_code => '# ??/??'),
      RubyXL::NumberFormat.new(:num_fmt_id => 14, :format_code => 'm/d/yyyy'),
      RubyXL::NumberFormat.new(:num_fmt_id => 15, :format_code => 'd-mmm-yy'),
      RubyXL::NumberFormat.new(:num_fmt_id => 16, :format_code => 'd-mmm'),
      RubyXL::NumberFormat.new(:num_fmt_id => 17, :format_code => 'mmm-yy'),
      RubyXL::NumberFormat.new(:num_fmt_id => 18, :format_code => 'h:mm AM/PM'),
      RubyXL::NumberFormat.new(:num_fmt_id => 19, :format_code => 'h:mm:ss AM/PM'),
      RubyXL::NumberFormat.new(:num_fmt_id => 20, :format_code => 'h:mm'),
      RubyXL::NumberFormat.new(:num_fmt_id => 21, :format_code => 'h:mm:ss'),
      RubyXL::NumberFormat.new(:num_fmt_id => 22, :format_code => 'm/d/yyyy h:mm'),
      RubyXL::NumberFormat.new(:num_fmt_id => 37, :format_code => '#, ##0_);(#, ##0)'),
      RubyXL::NumberFormat.new(:num_fmt_id => 38, :format_code => '#, ##0_);[Red](#, ##0)'),
      RubyXL::NumberFormat.new(:num_fmt_id => 39, :format_code => '#, ##0.00_);(#, ##0.00)'),
      RubyXL::NumberFormat.new(:num_fmt_id => 40, :format_code => '#, ##0.00_);[Red](#, ##0.00)'),
      RubyXL::NumberFormat.new(:num_fmt_id => 45, :format_code => 'mm:ss'),
      RubyXL::NumberFormat.new(:num_fmt_id => 46, :format_code => '[h]:mm:ss'),
      RubyXL::NumberFormat.new(:num_fmt_id => 47, :format_code => 'mm:ss.0'),
      RubyXL::NumberFormat.new(:num_fmt_id => 48, :format_code => '##0.0E+0'),
      RubyXL::NumberFormat.new(:num_fmt_id => 49, :format_code => '@')
    ])

    def find_by_format_id(format_id)
      self.find { |fmt| fmt.num_fmt_id == format_id }
    end
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_cellStyleXfs-1.html
  class CellStyleXFs < OOXMLContainerObject
    define_child_node(RubyXL::XF, :collection => :with_count)
    define_element_name 'cellStyleXfs'

    def self.default
      self.new(:_ => [ RubyXL::XF.new(:num_fmt_id => 0, :font_id => 0, :fill_id => 0, :border_id => 0) ])
    end
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_cellXfs-1.html
  class CellXFs < OOXMLContainerObject
    define_child_node(RubyXL::XF, :collection => :with_count)
    define_element_name 'cellXfs'

    def self.default
      self.new(:_ => [ RubyXL::XF.new(:num_fmt_id => 0, :font_id => 0, :fill_id => 0,
                                      :border_id => 0, :xfId => 0) ])
    end
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_cellStyles-1.html
  class CellStyles < OOXMLContainerObject
    define_child_node(RubyXL::CellStyle, :collection => :with_count)
    define_element_name 'cellStyles'

    def self.default
      self.new(:_ => [ RubyXL::CellStyle.new(:builtin_id => 0, :name => 'Normal', :xf_id => 0) ])
    end
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_dxf-1.html
  class DXF < OOXMLObject
    define_child_node(RubyXL::Font)
    define_child_node(RubyXL::NumberFormat)
    define_child_node(RubyXL::Fill)
    define_child_node(RubyXL::Alignment)
    define_child_node(RubyXL::Border)
    define_child_node(RubyXL::Protection)
    define_child_node(RubyXL::ExtensionStorageArea)
    define_element_name 'dxf'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_dxfs-1.html
  class DXFs < OOXMLContainerObject
    define_child_node(RubyXL::DXF, :collection => :with_count)
    define_element_name 'dxfs'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_tableStyle-1.html
  class TableStyle < OOXMLObject
    define_attribute(:name,  :string, :required => true)
    define_attribute(:pivot, :bool,   :default => true)
    define_attribute(:table, :bool,   :default => true)
    define_attribute(:count, :int)
    define_element_name 'tableStyle'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_tableStyles-1.html
  class TableStyles < OOXMLContainerObject
    define_attribute(:defaultTableStyle, :string)
    define_attribute(:defaultPivotStyle, :string)
    define_child_node(RubyXL::TableStyle, :collection => :with_count)
    define_element_name 'tableStyles'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_colors-1.html
  class ColorSet < OOXMLObject
    define_child_node(RubyXL::Color, :collection => true)
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_colors-1.html
  class IndexedColors < OOXMLContainerObject
    define_child_node(RubyXL::Color, :collection => true, :node_name => :rgbColor)
    define_element_name 'indexedColors'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_mruColors-1.html
  class MRUColors < OOXMLContainerObject
    define_child_node(RubyXL::Color, :collection => true)
    define_element_name 'mruColors'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_colors-1.html
  class Colors < OOXMLObject
    define_child_node(RubyXL::IndexedColors)
    define_child_node(RubyXL::MRUColors)
    define_element_name 'colors'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_styleSheet.html
  class Stylesheet < OOXMLTopLevelObject
    CONTENT_TYPE = 'application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml'.freeze
    REL_TYPE     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles'.freeze

    define_child_node(RubyXL::NumberFormats, :accessor => :number_formats)
    define_child_node(RubyXL::Fonts)
    define_child_node(RubyXL::Fills)
    define_child_node(RubyXL::Borders)
    define_child_node(RubyXL::CellStyleXFs)
    define_child_node(RubyXL::CellXFs)
    define_child_node(RubyXL::CellStyles)
    define_child_node(RubyXL::DXFs)
    define_child_node(RubyXL::TableStyles)
    define_child_node(RubyXL::Colors)
    define_child_node(RubyXL::ExtensionStorageArea)
    define_element_name 'styleSheet'
    set_namespaces('http://schemas.openxmlformats.org/spreadsheetml/2006/main'           => nil,
                   'http://schemas.openxmlformats.org/officeDocument/2006/relationships' => 'r',
                   'http://schemas.openxmlformats.org/markup-compatibility/2006'         => 'mc',
                   'http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac'         => 'x14ac',
                   'urn:schemas-microsoft-com:mac:vml'                                   => 'mv')

    def initialize(*args)
      super
      @format_hash = nil
    end

    def xlsx_path
      ROOT.join('xl', 'styles.xml')
    end

    def self.default
      self.new(:fonts          => RubyXL::Fonts.default,
               :fills          => RubyXL::Fills.default,
               :borders        => RubyXL::Borders.default,
               :cell_xfs       => RubyXL::CellXFs.default,
               :cell_styles    => RubyXL::CellStyles.default,
               :cell_style_xfs => RubyXL::CellStyleXFs.default)
    end

    def get_number_format_by_id(format_id)
      @format_hash ||= {}

      if @format_hash[format_id].nil? then
        @format_hash[format_id] = NumberFormats::DEFAULT_NUMBER_FORMATS.find_by_format_id(format_id) ||
                                    (number_formats && number_formats.find_by_format_id(format_id))
      end

      @format_hash[format_id]
    end

    def register_number_format(format_code)
      self.number_formats ||= RubyXL::NumberFormats.new

      max_fmt_id = 163

      (NumberFormats::DEFAULT_NUMBER_FORMATS + number_formats).each { |fmt|
        return fmt.num_fmt_id if fmt.format_code == format_code
        max_fmt_id = fmt.num_fmt_id if fmt.num_fmt_id > max_fmt_id
      }

      max_fmt_id += 1
      number_formats << RubyXL::NumberFormat.new(:num_fmt_id => max_fmt_id, :format_code => format_code)

      return max_fmt_id
    end
  end
end
