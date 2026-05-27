require 'rubyXL/objects/ooxml_object'
require 'rubyXL/objects/simple_types'

module RubyXL
  class BorderEdge < OOXMLObject
    define_attribute(:style, RubyXL::ST_BorderStyle, :default => 'none')
    define_child_node(RubyXL::Color)

    def set_rgb_color(font_color)
      self.color = RubyXL::Color.new(:rgb => font_color.to_s)
    end

    def get_rgb_color
      color && color.rgb
    end
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_border-2.html
  class Border < OOXMLObject
    define_attribute(:diagonalUp,   :bool)
    define_attribute(:diagonalDown, :bool)
    define_attribute(:outline,      :bool, :default => true)
    define_child_node(RubyXL::BorderEdge, :node_name => :left)
    define_child_node(RubyXL::BorderEdge, :node_name => :right)
    define_child_node(RubyXL::BorderEdge, :node_name => :top)
    define_child_node(RubyXL::BorderEdge, :node_name => :bottom)
    define_child_node(RubyXL::BorderEdge, :node_name => :diagonal)
    define_child_node(RubyXL::BorderEdge, :node_name => :vertical)
    define_child_node(RubyXL::BorderEdge, :node_name => :horizontal)
    define_element_name 'border'

    def get_edge_style(direction)
      edge = self.send(direction)
      edge && edge.style
    end

    def set_edge_style(direction, style)
      edge = self.send(direction)
      if edge
        edge.style = style
      else
        self.send("#{direction}=", RubyXL::BorderEdge.new(:style => style))
      end
    end

    def get_edge_color(direction)
      edge = self.send(direction)
      edge && edge.get_rgb_color
    end

    def set_edge_color(direction, color)
      edge = self.send(direction)
      if edge
        edge.set_rgb_color(color)
      else
        self.send("#{direction}=", RubyXL::BorderEdge.new)
        self.send(direction).set_rgb_color(color)
      end
    end
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_borders-1.html
  class Borders < OOXMLContainerObject
    define_child_node(RubyXL::Border, :collection => :with_count)
    define_element_name 'borders'

    def self.default
      self.new(:_ => [ RubyXL::Border.new ])
    end
  end
end
