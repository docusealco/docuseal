require 'rubyXL/objects/ooxml_object'
require 'rubyXL/objects/simple_types'

module RubyXL
  # http://www.datypic.com/sc/ooxml/e-ssml_stop-1.html
  class Stop < OOXMLObject
    define_attribute(:position, :double, :required => true)
    define_child_node(RubyXL::Color)
    define_element_name 'stop'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_patternFill-1.html
  class PatternFill < OOXMLObject
    define_attribute(:patternType, RubyXL::ST_PatternType)
    define_child_node(RubyXL::Color, :node_name => :fgColor)
    define_child_node(RubyXL::Color, :node_name => :bgColor)
    define_element_name 'patternFill'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_gradientFill-1.html
  class GradientFill < OOXMLObject
    define_attribute(:type,   RubyXL::ST_GradientType, :default => 'linear')
    define_attribute(:degree, :double, :default => 0)
    define_attribute(:left,   :double, :default => 0)
    define_attribute(:right,  :double, :default => 0)
    define_attribute(:top,    :double, :default => 0)
    define_attribute(:bottom, :double, :default => 0)
    define_child_node(RubyXL::Stop, :collection => true)
    define_element_name 'gradientFill'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_fill-1.html
  class Fill < OOXMLObject
    define_child_node(RubyXL::PatternFill)
    define_child_node(RubyXL::GradientFill)
    define_element_name 'fill'

    def self.default(pattern_type)
      self.new(:pattern_fill => RubyXL::PatternFill.new(:pattern_type => pattern_type))
    end
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_fills-1.html
  class Fills < OOXMLContainerObject
    define_child_node(RubyXL::Fill, :collection => :with_count)
    define_element_name 'fills'

    def self.default
      self.new(:_ => [ RubyXL::Fill.default('none'), RubyXL::Fill.default('gray125') ])
    end
  end
end
