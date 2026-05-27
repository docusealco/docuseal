require 'rubyXL/objects/ooxml_object'
require 'rubyXL/objects/extensions'

module RubyXL
  # http://www.datypic.com/sc/ooxml/e-ssml_c-1.html
  class CalculationChainCell < OOXMLObject
    define_attribute(:r, :ref,  :accessor => :ref)
    define_attribute(:i, :int,  :accessor => :sheet_id,    :default => 0)
    define_attribute(:s, :bool, :accessor => :child_chain, :default => false)
    define_attribute(:l, :bool, :accessor => :new_dep_lvl, :default => false)
    define_attribute(:t, :bool, :accessor => :new_thread,  :default => false)
    define_attribute(:a, :bool, :accessor => :array,       :default => false)
    define_element_name 'c'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_calcChain.html
  class CalculationChain < OOXMLTopLevelObject
    CONTENT_TYPE = 'application/vnd.openxmlformats-officedocument.spreadsheetml.calcChain+xml'.freeze
    REL_TYPE     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/calcChain'.freeze

    define_child_node(RubyXL::CalculationChainCell, :collection => true, :accessor => :cells)
    define_child_node(RubyXL::ExtensionStorageArea)

    define_element_name 'calcChain'
    set_namespaces('http://schemas.openxmlformats.org/spreadsheetml/2006/main' => nil)

    def xlsx_path
      ROOT.join('xl', 'calcChain.xml')
    end
  end
end
