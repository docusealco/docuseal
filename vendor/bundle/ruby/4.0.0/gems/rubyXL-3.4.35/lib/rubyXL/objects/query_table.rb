require 'rubyXL/objects/ooxml_object'
require 'rubyXL/objects/simple_types'
require 'rubyXL/objects/extensions'
require 'rubyXL/objects/relationships'
require 'rubyXL/objects/sheet_common'

# Query Tables
# https://msdn.microsoft.com/en-us/library/hh643563(v=office.12).aspx

module RubyXL
  # http://www.datypic.com/sc/ooxml/e-ssml_queryTableField-1.html
  class QueryTableField < OOXMLObject
    define_attribute(:id,            :uint, :required => true)
    define_attribute(:name,          RubyXL::ST_Xstring)
    define_attribute(:dataBound,     :bool, :default => true)
    define_attribute(:rowNumbers,    :bool, :default => false)
    define_attribute(:fillFormulas,  :bool, :default => false)
    define_attribute(:clipped,       :bool, :default => false)
    define_attribute(:tableColumnId, :uint, :default => 0)

    define_child_node(RubyXL::ExtensionStorageArea)

    define_element_name 'queryTableField'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_queryTableFields-1.html
  class QueryTableFields < OOXMLObject
    define_child_node(RubyXL::QueryTableField, :collection => :with_count,
                      :accessor => :fields, :node_name => :queryTableField)
    define_element_name 'queryTableFields'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_deletedField-1.html
  class QueryTableDeletedField < OOXMLObject
    define_attribute(:name, RubyXL::ST_Xstring, :required => true)

    define_element_name 'deletedField'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_queryTableDeletedFields-1.html
  class QueryTableDeletedFields < OOXMLObject
    define_child_node(RubyXL::QueryTableDeletedField, :collection => :with_count,
                      :accessor => :deleted_fields, :node_name => :deletedField)
    define_element_name 'queryTableDeletedFields'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_queryTableRefresh-1.html
  class QueryTableRefresh < OOXMLObject
    define_attribute(:preserveSortFilterLayout, :bool, :default => true)
    define_attribute(:fieldIdWrapped,           :bool, :default => false)
    define_attribute(:headersInLastRefresh,     :bool, :default => true)
    define_attribute(:minimumVersion,           :uint, :default => 0)
    define_attribute(:nextId,                   :uint, :default => 1)
    define_attribute(:unboundColumnsLeft,       :uint, :default => 0)
    define_attribute(:unboundColumnsRight,      :uint, :default => 0)

    define_child_node(RubyXL::QueryTableFields) # [1..1]
    define_child_node(RubyXL::QueryTableDeletedFields)
    define_child_node(RubyXL::SortState)
    define_child_node(RubyXL::ExtensionStorageArea)

    define_element_name 'queryTableRefresh'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_queryTable.html
  class QueryTable < OOXMLTopLevelObject
    CONTENT_TYPE = 'application/vnd.openxmlformats-officedocument.spreadsheetml.queryTable+xml'.freeze
    REL_TYPE     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/queryTable'.freeze

    include RubyXL::RelationshipSupport

    define_attribute(:name,                    RubyXL::ST_Xstring, :required => true)
    define_attribute(:headers,                 :bool, :default => true)
    define_attribute(:rowNumbers,              :bool, :default => false)
    define_attribute(:disableRefresh,          :bool, :default => false)
    define_attribute(:backgroundRefresh,       :bool, :default => true)
    define_attribute(:firstBackgroundRefresh,  :bool, :default => false)
    define_attribute(:refreshOnLoad,           :bool, :default => false)
    define_attribute(:growShrinkType,          RubyXL::ST_GrowShrinkType, :default => 'insertDelete')
    define_attribute(:fillFormulas,            :bool, :default => false)
    define_attribute(:removeDataOnSave,        :bool, :default => false)
    define_attribute(:disableEdit,             :bool, :default => false)
    define_attribute(:preserveFormatting,      :bool, :default => true)
    define_attribute(:adjustColumnWidth,       :bool, :default => true)
    define_attribute(:intermediate,            :bool, :default => false)
    define_attribute(:connectionId,            :uint, :required => true)
    define_attribute(:autoFormatId,            :uint)
    define_attribute(:applyNumberFormats,      :bool)
    define_attribute(:applyBorderFormats,      :bool)
    define_attribute(:applyFontFormats,        :bool)
    define_attribute(:applyPatternFormats,     :bool)
    define_attribute(:applyAlignmentFormats,   :bool)
    define_attribute(:applyWidthHeightFormats, :bool)

    define_child_node(RubyXL::QueryTableRefresh)
    define_child_node(RubyXL::ExtensionStorageArea)

    define_element_name 'queryTable'
    set_namespaces('http://schemas.openxmlformats.org/spreadsheetml/2006/main'           => nil,
                   'http://schemas.openxmlformats.org/officeDocument/2006/relationships' => 'r')

    def xlsx_path
      ROOT.join('xl', 'queryTables', "queryTable#{file_index}.xml")
    end
  end
end
