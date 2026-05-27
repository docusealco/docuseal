require 'rubyXL/objects/ooxml_object'
require 'rubyXL/objects/container_nodes'
require 'time'

module RubyXL
  # http://www.datypic.com/sc/ooxml/e-extended-properties_Properties.html
  class DocumentPropertiesFile < OOXMLTopLevelObject
    CONTENT_TYPE = 'application/vnd.openxmlformats-officedocument.extended-properties+xml'.freeze
    REL_TYPE     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties'.freeze

    attr_accessor :workbook

    define_child_node(RubyXL::StringNode,  :node_name => :Template)
    define_child_node(RubyXL::StringNode,  :node_name => :Manager)
    define_child_node(RubyXL::StringNode,  :node_name => :Company)
    define_child_node(RubyXL::IntegerNode, :node_name => :Pages)
    define_child_node(RubyXL::IntegerNode, :node_name => :Words)
    define_child_node(RubyXL::IntegerNode, :node_name => :Characters)
    define_child_node(RubyXL::StringNode,  :node_name => :PresentationFormat)
    define_child_node(RubyXL::IntegerNode, :node_name => :Lines)
    define_child_node(RubyXL::IntegerNode, :node_name => :Paragraphs)
    define_child_node(RubyXL::IntegerNode, :node_name => :Slides)
    define_child_node(RubyXL::IntegerNode, :node_name => :Notes)
    define_child_node(RubyXL::IntegerNode, :node_name => :TotalTime)
    define_child_node(RubyXL::IntegerNode, :node_name => :HiddenSlides)
    define_child_node(RubyXL::IntegerNode, :node_name => :MMClips)
    define_child_node(RubyXL::BooleanNode, :node_name => :ScaleCrop)
    define_child_node(RubyXL::VectorValue, :node_name => :HeadingPairs)
    define_child_node(RubyXL::VectorValue, :node_name => :TitlesOfParts)
    define_child_node(RubyXL::BooleanNode, :node_name => :LinksUpToDate)
    define_child_node(RubyXL::IntegerNode, :node_name => :CharactersWithSpaces)
    define_child_node(RubyXL::BooleanNode, :node_name => :SharedDoc)
    define_child_node(RubyXL::StringNode,  :node_name => :HyperlinkBase)
    define_child_node(RubyXL::VectorValue, :node_name => :HLinks)
    define_child_node(RubyXL::BooleanNode, :node_name => :HyperlinksChanged)
    define_child_node(RubyXL::StringNode,  :node_name => :DigSig)
    define_child_node(RubyXL::StringNode,  :node_name => :Application)
    define_child_node(RubyXL::StringNode,  :node_name => :AppVersion)
    define_child_node(RubyXL::IntegerNode, :node_name => :DocSecurity)
    set_namespaces('http://schemas.openxmlformats.org/officeDocument/2006/extended-properties' => nil,
                   'http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes'      => 'vt')
    define_element_name 'Properties'

    def add_parts_count(name, count)
      return unless count > 0
      heading_pairs.vt_vector.vt_variant << RubyXL::Variant.new(:vt_lpstr => RubyXL::StringNode.new(:value => name))
      heading_pairs.vt_vector.vt_variant << RubyXL::Variant.new(:vt_i4 => RubyXL::IntegerNode.new(:value => count))
    end
    private :add_parts_count

    def add_part_title(name)
      titles_of_parts.vt_vector.vt_lpstr << RubyXL::StringNode.new(:value => name)
    end
    private :add_part_title

    def before_write_xml
      workbook = root.workbook

      self.heading_pairs   = RubyXL::VectorValue.new(:vt_vector => RubyXL::Vector.new(:base_type => 'variant'))
      self.titles_of_parts = RubyXL::VectorValue.new(:vt_vector => RubyXL::Vector.new(:base_type => 'lpstr'))

      worksheets = chartsheets = 0

      workbook.worksheets.each { |sheet|
        add_part_title(sheet.sheet_name)

        case sheet
        when RubyXL::Worksheet  then worksheets += 1
        when RubyXL::Chartsheet then chartsheets += 1
        end
      }

      add_parts_count('Worksheets', worksheets) if worksheets > 0
      add_parts_count('Charts', chartsheets) if chartsheets > 0

      if workbook.defined_names then
        add_parts_count('Named Ranges', workbook.defined_names.size)
        workbook.defined_names.each { |defined_name| add_part_title(defined_name.name) }
      end

      true
    end

    def xlsx_path
      ROOT.join('docProps', 'app.xml')
    end
  end


  class CorePropertiesFile < OOXMLTopLevelObject
    CONTENT_TYPE = 'application/vnd.openxmlformats-package.core-properties+xml'.freeze
    REL_TYPE     = 'http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties'.freeze

    attr_accessor :workbook

    define_child_node(RubyXL::StringNode,    :node_name => 'dc:creator')
    define_child_node(RubyXL::StringNode,    :node_name => 'dc:description')
    define_child_node(RubyXL::StringNode,    :node_name => 'dc:identifier')
    define_child_node(RubyXL::StringNode,    :node_name => 'dc:language')
    define_child_node(RubyXL::StringNode,    :node_name => 'dc:subject')
    define_child_node(RubyXL::StringNode,    :node_name => 'dc:title')
    define_child_node(RubyXL::StringNodeW3C, :node_name => 'dcterms:created')
    define_child_node(RubyXL::StringNodeW3C, :node_name => 'dcterms:modified')
    define_child_node(RubyXL::StringNode,    :node_name => 'cp:lastModifiedBy')
    define_child_node(RubyXL::StringNode,    :node_name => 'cp:lastPrinted')
    define_child_node(RubyXL::StringNode,    :node_name => 'cp:category')
    define_child_node(RubyXL::StringNode,    :node_name => 'cp:contentStatus')
    define_child_node(RubyXL::StringNode,    :node_name => 'cp:contentType')
    define_child_node(RubyXL::StringNode,    :node_name => 'cp:keywords')
    define_child_node(RubyXL::StringNode,    :node_name => 'cp:revision')
    define_child_node(RubyXL::StringNode,    :node_name => 'cp:version')

    set_namespaces('http://schemas.openxmlformats.org/package/2006/metadata/core-properties' => 'cp',
                   'http://purl.org/dc/elements/1.1/'                                        => 'dc',
                   'http://purl.org/dc/terms/'                                               => 'dcterms',
                   'http://purl.org/dc/dcmitype/'                                            => 'dcmitype',
                   'http://www.w3.org/2001/XMLSchema-instance'                               => 'xsi')
    define_element_name 'cp:coreProperties'

    def xlsx_path
      ROOT.join('docProps', 'core.xml')
    end

    def creator
      dc_creator && dc_creator.value
    end

    def creator=(v)
      self.dc_creator = v && RubyXL::StringNode.new(:value => v)
    end

    def modifier
      cp_last_modified_by && cp_last_modified_by.value
    end

    def modifier=(v)
      self.cp_last_modified_by = v && RubyXL::StringNode.new(:value => v)
    end

    def created_at
      dcterms_created && dcterms_created.to_time
    end

    def created_at=(v)
      self.dcterms_created = RubyXL::StringNodeW3C.default(v)
    end

    def modified_at
      dcterms_modified && dcterms_modified.to_time
    end

    def modified_at=(v)
      self.dcterms_modified = RubyXL::StringNodeW3C.default(v)
    end
  end
end
