require 'rubyXL/objects/ooxml_object'
require 'rubyXL/objects/simple_types'

module RubyXL
  # http://www.datypic.com/sc/ooxml/e-ssml_color-4.html
  class Color < OOXMLObject
    COLOR_REGEXP = /\A(?:[a-f0-9]{6}|[a-f0-9]{8})\Z/i

    define_attribute(:auto,    :bool)
    define_attribute(:indexed, :uint)
    define_attribute(:rgb,     RubyXL::ST_UnsignedIntHex)
    define_attribute(:theme,   :uint)
    define_attribute(:tint,    :double, :default => 0.0)
    define_element_name 'color'

    # validates hex color code, no '#' allowed
    def self.validate_color(color)
      if color =~ COLOR_REGEXP
        return true
      else
        raise 'invalid color'
      end
    end
  end
end
