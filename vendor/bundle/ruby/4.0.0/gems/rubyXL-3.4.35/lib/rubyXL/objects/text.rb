require 'rubyXL/objects/ooxml_object'
require 'rubyXL/objects/simple_types'
require 'rubyXL/objects/container_nodes'
require 'rubyXL/objects/color'

module RubyXL
  # http://www.datypic.com/sc/ooxml/e-ssml_t-1.html
  class Text < OOXMLObject
    define_attribute(:_,           :string, :accessor => :value)
    define_attribute(:'xml:space', %w{ preserve })
    define_element_name 't'

    # http://www.w3.org/TR/REC-xml/#NT-Char:
    # Char ::= #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF]

    INVALID_XML10_CHARS = /([^\x09\x0A\x0D\x20-\uD7FF\uE000-\uFFFD\u{10000}-\u{10FFFF}])/
    ESCAPED_UNICODE = /_x([0-9A-F]{4})_/

    def before_write_xml
      preserve_whitespace
      self.value.gsub(INVALID_XML10_CHARS) { |bad_char| format('_x%04x_', bad_char.ord) }
      true
    end

    def to_s
      value.to_s.gsub(ESCAPED_UNICODE) { Regexp.last_match(1).hex.chr(::Encoding::UTF_8) }
    end
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_rPr-1.html
  class RunProperties < OOXMLObject
    define_child_node(RubyXL::StringValue,  :node_name => :rFont)
    define_child_node(RubyXL::IntegerValue, :node_name => :charset)
    define_child_node(RubyXL::IntegerValue, :node_name => :family)
    define_child_node(RubyXL::BooleanValue, :node_name => :b)
    define_child_node(RubyXL::BooleanValue, :node_name => :i)
    define_child_node(RubyXL::BooleanValue, :node_name => :strike)
    define_child_node(RubyXL::BooleanValue, :node_name => :outline)
    define_child_node(RubyXL::BooleanValue, :node_name => :shadow)
    define_child_node(RubyXL::BooleanValue, :node_name => :condense)
    define_child_node(RubyXL::BooleanValue, :node_name => :extend)
    define_child_node(RubyXL::Color)
    define_child_node(RubyXL::FloatValue,   :node_name => :sz)
    define_child_node(RubyXL::BooleanValue, :node_name => :u)
    define_child_node(RubyXL::StringValue,  :node_name => :vertAlign)
    define_child_node(RubyXL::StringValue,  :node_name => :scheme)
    define_element_name 'rPr'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_r-2.html
  class RichTextRun < OOXMLObject
    define_child_node(RubyXL::RunProperties)
    define_child_node(RubyXL::Text)
    define_element_name 'r'

    def to_s
      t.to_s
    end
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_rPh-1.html
  class PhoneticRun < OOXMLObject
    define_attribute(:sb, :int, :required => true)
    define_attribute(:eb, :int, :required => true)
    define_child_node(RubyXL::Text)
    define_element_name 'rPh'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_phoneticPr-1.html
  class PhoneticProperties < OOXMLObject
    define_attribute(:fontId,    :int, :required => true)
    define_attribute(:type,      RubyXL::ST_PhoneticType,      :default => 'fullwidthKatakana')
    define_attribute(:alignment, RubyXL::ST_PhoneticAlignment, :default => 'left')
    define_element_name 'phoneticPr'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_is-1.html
  class RichText < OOXMLObject
    define_child_node(RubyXL::Text)
    define_child_node(RubyXL::RichTextRun, :collection => true)
    define_child_node(RubyXL::PhoneticRun, :collection => true)
    define_child_node(RubyXL::PhoneticProperties)
    define_element_name 'is'

    def to_s
      # `dup` here unfreezes the string since it's not a constant but initial value
      str = t.nil? ? ''.dup : t.to_s
      r&.each { |rtr| str << rtr.to_s if rtr }
      str
    end
  end
end
