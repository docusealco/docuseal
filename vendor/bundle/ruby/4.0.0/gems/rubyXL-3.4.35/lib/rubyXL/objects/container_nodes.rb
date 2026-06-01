require 'rubyXL/objects/ooxml_object'
require 'rubyXL/objects/simple_types'

module RubyXL
  class BooleanValue < OOXMLObject
    define_attribute(:val, :bool, :required => true, :default => true)
  end

  class StringValue < OOXMLObject
    define_attribute(:val, :string, :required => true)
  end

  class IntegerValue < OOXMLObject
    define_attribute(:val, :int, :required => true)
  end

  class FloatValue < OOXMLObject
    define_attribute(:val, :double, :required => true)
  end

  class BooleanNode < OOXMLObject
    define_attribute(:_, :bool, :accessor => :value)
  end

  class StringNode < OOXMLObject
    define_attribute(:_, :string, :accessor => :value)
  end

  class IntegerNode < OOXMLObject
    define_attribute(:_, :int, :accessor => :value)
  end

  class FloatNode < OOXMLObject
    define_attribute(:_, :double, :accessor => :value)
  end

  class StringNodeW3C < OOXMLObject
    define_attribute(:_, :string, :accessor => :value)
    define_attribute('xsi:type', :string, :required => true, :default => 'dcterms:W3CDTF')

    def to_time
      value && (value.strip.empty? ? nil : DateTime.parse(value).to_time)
    end

    def self.default(v)
      v && self.new(:value => v.to_datetime.iso8601)
    end
  end

  # http://www.datypic.com/sc/ooxml/e-docPropsVTypes_variant.html
  class Variant < OOXMLObject
    define_child_node(RubyXL::Variant, :node_name => 'vt:variant')

#   vector    Vector
#    array    Array
#    blob    Binary Blob
#    oblob    Binary Blob Object
#    empty    Empty
#    null    Null
#    int    Integer
#    uint    Unsigned Integer
#    decimal    Decimal
#    stream    Binary Stream
#    ostream    Binary Stream Object
#    storage    Binary Storage
#    ostorage    Binary Storage Object
#    vstream    Binary Versioned Stream
#
    define_child_node(RubyXL::IntegerNode, :node_name => 'vt:i1')
    define_child_node(RubyXL::IntegerNode, :node_name => 'vt:i2')
    define_child_node(RubyXL::IntegerNode, :node_name => 'vt:i4')
    define_child_node(RubyXL::IntegerNode, :node_name => 'vt:i8')
    define_child_node(RubyXL::IntegerNode, :node_name => 'vt:ui1')
    define_child_node(RubyXL::IntegerNode, :node_name => 'vt:ui2')
    define_child_node(RubyXL::IntegerNode, :node_name => 'vt:ui4')
    define_child_node(RubyXL::IntegerNode, :node_name => 'vt:ui8')
    define_child_node(RubyXL::FloatNode,   :node_name => 'vt:r4')
    define_child_node(RubyXL::FloatNode,   :node_name => 'vt:r8')
    define_child_node(RubyXL::StringNode,  :node_name => 'vt:lpstr')
    define_child_node(RubyXL::StringNode,  :node_name => 'vt:lpstrw')
    define_child_node(RubyXL::StringNode,  :node_name => 'vt:bstr')
    define_child_node(RubyXL::StringNode,  :node_name => 'vt:date')
    define_child_node(RubyXL::StringNode,  :node_name => 'vt:filetime')
    define_child_node(RubyXL::BooleanNode, :node_name => 'vt:bool')
    define_child_node(RubyXL::StringNode,  :node_name => 'vt:cy')
    define_child_node(RubyXL::StringNode,  :node_name => 'vt:error')
    define_child_node(RubyXL::StringNode,  :node_name => 'vt:clsid')
    define_child_node(RubyXL::StringNode,  :node_name => 'vt:cf')
    define_element_name 'vt:vector'
  end

  # http://www.datypic.com/sc/ooxml/e-docPropsVTypes_vector.html
  class Vector < OOXMLObject
    define_attribute(:baseType, RubyXL::ST_VectorBaseType, :required => true)
    define_attribute(:size,     :int, :required => true)
    define_child_node(RubyXL::Variant,     :collection => true, :node_name => 'vt:variant')
    define_child_node(RubyXL::IntegerNode, :collection => true, :node_name => 'vt:i1')
    define_child_node(RubyXL::IntegerNode, :collection => true, :node_name => 'vt:i2')
    define_child_node(RubyXL::IntegerNode, :collection => true, :node_name => 'vt:i4')
    define_child_node(RubyXL::IntegerNode, :collection => true, :node_name => 'vt:i8')
    define_child_node(RubyXL::IntegerNode, :collection => true, :node_name => 'vt:ui1')
    define_child_node(RubyXL::IntegerNode, :collection => true, :node_name => 'vt:ui2')
    define_child_node(RubyXL::IntegerNode, :collection => true, :node_name => 'vt:ui4')
    define_child_node(RubyXL::IntegerNode, :collection => true, :node_name => 'vt:ui8')
    define_child_node(RubyXL::FloatNode,   :collection => true, :node_name => 'vt:r4')
    define_child_node(RubyXL::FloatNode,   :collection => true, :node_name => 'vt:r8')
    define_child_node(RubyXL::StringNode,  :collection => true, :node_name => 'vt:lpstr')
    define_child_node(RubyXL::StringNode,  :collection => true, :node_name => 'vt:lpstrw')
    define_child_node(RubyXL::StringNode,  :collection => true, :node_name => 'vt:bstr')
    define_child_node(RubyXL::StringNode,  :collection => true, :node_name => 'vt:date')
    define_child_node(RubyXL::StringNode,  :collection => true, :node_name => 'vt:filetime')
    define_child_node(RubyXL::BooleanNode, :collection => true, :node_name => 'vt:bool')
    define_child_node(RubyXL::StringNode,  :collection => true, :node_name => 'vt:cy')
    define_child_node(RubyXL::StringNode,  :collection => true, :node_name => 'vt:error')
    define_child_node(RubyXL::StringNode,  :collection => true, :node_name => 'vt:clsid')
    define_child_node(RubyXL::StringNode,  :collection => true, :node_name => 'vt:cf')
    define_element_name 'vt:vector'

    def before_write_xml
      # Fill out the count attribute
      known_child_nodes = obtain_class_variable(:@@ooxml_child_nodes)
      self.size = 0
      known_child_nodes.values.each { |v| self.size += self.send(v[:accessor]).size }
      true
    end
  end

  class VectorValue < OOXMLObject
    define_child_node(RubyXL::Vector)
  end
end
