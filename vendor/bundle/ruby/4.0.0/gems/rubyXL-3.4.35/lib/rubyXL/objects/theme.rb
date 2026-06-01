require 'rubyXL/objects/ooxml_object'
require 'rubyXL/objects/extensions'

module RubyXL
  # http://www.datypic.com/sc/ooxml/e-a_ext-1.html
  class AExtension < OOXMLObject
    define_attribute(:uri, :string)
    define_element_name 'a:ext'
    attr_accessor :raw_xml

    def self.parse(node, ignore)
      obj = new
      obj.raw_xml = node.to_xml
      obj
    end

    def write_xml(xml, node_name_override = nil)
      self.raw_xml
    end
  end

  class AExtensionStorageArea < OOXMLObject
    define_child_node(RubyXL::AExtension, :collection => true)
    define_element_name 'a:extLst'
  end

  # http://www.datypic.com/sc/ooxml/e-a_srgbClr-1.html
  class CT_ScRgbColor < OOXMLObject
    # -- Choice [0..*] (a:EG_ColorTransform)
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:tint')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:shade')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:comp')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:inv')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:gray')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:alpha')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:alphaOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:alphaMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:hue')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:hueOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:hueMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:sat')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:satOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:satMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:lum')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:lumOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:lumMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:red')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:redOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:redMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:green')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:greenOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:greenMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:blue')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:blueOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:blueMod')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:gamma')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:invGamma')
    define_attribute(:r, :int, :required => true)
    define_attribute(:g, :int, :required => true)
    define_attribute(:b, :int, :required => true)
    define_element_name 'a:scrgbClr'
  end

  # http://www.datypic.com/sc/ooxml/e-a_srgbClr-1.html
  class CT_SRgbColor < OOXMLObject
    # -- Choice [0..*] (a:EG_ColorTransform)
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:tint')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:shade')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:comp')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:inv')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:gray')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:alpha')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:alphaOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:alphaMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:hue')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:hueOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:hueMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:sat')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:satOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:satMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:lum')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:lumOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:lumMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:red')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:redOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:redMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:green')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:greenOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:greenMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:blue')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:blueOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:blueMod')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:gamma')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:invGamma')
    define_attribute(:val, :string, :required => true)
    define_element_name 'a:srgbClr'
  end

  # http://www.datypic.com/sc/ooxml/e-a_hslClr-1.html
  class CT_HslColor < OOXMLObject
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:tint')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:shade')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:comp')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:inv')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:gray')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:alpha')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:alphaOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:alphaMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:hue')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:hueOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:hueMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:sat')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:satOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:satMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:lum')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:lumOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:lumMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:red')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:redOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:redMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:green')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:greenOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:greenMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:blue')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:blueOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:blueMod')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:gamma')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:invGamma')
    define_attribute(:hue, :int, :required => true)
    define_attribute(:sat, :int, :required => true)
    define_attribute(:lum, :int, :required => true)
    define_element_name 'a:hslClr'
  end

  # http://www.datypic.com/sc/ooxml/e-a_sysClr-1.html
  class CT_SystemColor < OOXMLObject
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:tint')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:shade')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:comp')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:inv')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:gray')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:alpha')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:alphaOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:alphaMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:hue')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:hueOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:hueMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:sat')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:satOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:satMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:lum')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:lumOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:lumMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:red')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:redOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:redMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:green')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:greenOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:greenMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:blue')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:blueOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:blueMod')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:gamma')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:invGamma')
    define_attribute(:val,     RubyXL::ST_SystemColorVal, :required => true)
    define_attribute(:lastClr, :string)
    define_element_name 'a:sysClr'
  end

  # http://www.datypic.com/sc/ooxml/e-a_schemeClr-1.html
  class CT_SchemeColor < OOXMLObject
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:tint')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:shade')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:comp')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:inv')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:gray')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:alpha')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:alphaOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:alphaMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:hue')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:hueOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:hueMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:sat')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:satOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:satMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:lum')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:lumOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:lumMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:red')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:redOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:redMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:green')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:greenOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:greenMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:blue')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:blueOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:blueMod')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:gamma')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:invGamma')
    define_attribute(:val, RubyXL::ST_SchemeColorVal, :required => true)
    define_element_name 'a:schemeClr'
  end

  # http://www.datypic.com/sc/ooxml/e-a_prstClr-1.html
  class CT_PresetColor < OOXMLObject
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:tint')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:shade')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:comp')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:inv')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:gray')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:alpha')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:alphaOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:alphaMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:hue')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:hueOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:hueMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:sat')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:satOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:satMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:lum')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:lumOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:lumMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:red')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:redOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:redMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:green')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:greenOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:greenMod')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:blue')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:blueOff')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:blueMod')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:gamma')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:invGamma')
    define_attribute(:val, RubyXL::ST_PresetColorVal, :required => true)
    define_element_name 'a:prstClr'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_Color.html
  class CT_Color < OOXMLObject
    define_child_node(RubyXL::CT_ScRgbColor)
    define_child_node(RubyXL::CT_SRgbColor)
    define_child_node(RubyXL::CT_HslColor)
    define_child_node(RubyXL::CT_SystemColor)
    define_child_node(RubyXL::CT_SchemeColor)
    define_child_node(RubyXL::CT_PresetColor)
  end

  # http://www.datypic.com/sc/ooxml/e-a_clrScheme-1.html
  class CT_ColorScheme < OOXMLObject
    define_child_node(RubyXL::CT_Color, :node_name => 'a:dk1')
    define_child_node(RubyXL::CT_Color, :node_name => 'a:lt1')
    define_child_node(RubyXL::CT_Color, :node_name => 'a:dk2')
    define_child_node(RubyXL::CT_Color, :node_name => 'a:lt2')
    define_child_node(RubyXL::CT_Color, :node_name => 'a:accent1')
    define_child_node(RubyXL::CT_Color, :node_name => 'a:accent2')
    define_child_node(RubyXL::CT_Color, :node_name => 'a:accent3')
    define_child_node(RubyXL::CT_Color, :node_name => 'a:accent4')
    define_child_node(RubyXL::CT_Color, :node_name => 'a:accent5')
    define_child_node(RubyXL::CT_Color, :node_name => 'a:accent6')
    define_child_node(RubyXL::CT_Color, :node_name => 'a:hlink')
    define_child_node(RubyXL::CT_Color, :node_name => 'a:folHlink')
    define_attribute(:name, :string, :required => true)
    define_element_name 'a:clrScheme'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_SupplementalFont.html
  class CT_SupplementalFont < OOXMLObject
    define_attribute(:script,   :string, :required => true)
    define_attribute(:typeface, :string, :required => true)
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_TextFont.html
  class CT_TextFont < OOXMLObject
    define_attribute(:typeface,    :string)
    define_attribute(:panose,      :string)
    define_attribute(:pitchFamily, :int, :default => 0)
    define_attribute(:charset,     :int, :default => 1)
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_FontCollection.html
  class CT_FontCollection < OOXMLObject
    define_child_node(RubyXL::CT_TextFont,         :node_name => 'a:latin')
    define_child_node(RubyXL::CT_TextFont,         :node_name => 'a:ea')
    define_child_node(RubyXL::CT_TextFont,         :node_name => 'a:cs')
    define_child_node(RubyXL::CT_SupplementalFont, :node_name => 'a:font', :collection => [0..-1])
    define_child_node(RubyXL::AExtensionStorageArea)
  end

  # http://www.datypic.com/sc/ooxml/e-a_fontScheme-1.html
  class FontScheme < OOXMLObject
    # -- Sequence [1..1]
    define_child_node(RubyXL::CT_FontCollection, :node_name => 'a:majorFont')
    define_child_node(RubyXL::CT_FontCollection, :node_name => 'a:minorFont')
    define_child_node(RubyXL::AExtensionStorageArea)
    # --
    define_attribute(:name, :string, :required => true)
    define_element_name 'a:fontScheme'
  end

  # http://www.datypic.com/sc/ooxml/e-a_gs-1.html
  class CT_GradientStop < OOXMLObject
    # -- Choice [1..1] (EG_ColorChoice)
    define_child_node(RubyXL::CT_ScRgbColor)
    define_child_node(RubyXL::CT_SRgbColor)
    define_child_node(RubyXL::CT_HslColor)
    define_child_node(RubyXL::CT_SystemColor)
    define_child_node(RubyXL::CT_SchemeColor)
    define_child_node(RubyXL::CT_PresetColor)
    # --
    define_attribute(:pos, :int, :required => true)
    define_element_name 'a:gs'
  end

  # http://www.datypic.com/sc/ooxml/e-a_gsLst-1.html
  class CT_GradientStopList < OOXMLContainerObject
    define_child_node(RubyXL::CT_GradientStop, :collection => [2..-1])
    define_element_name 'a:gsLst'
  end

  # http://www.datypic.com/sc/ooxml/e-a_lin-1.html
  class CT_LinearShadeProperties < OOXMLObject
    define_attribute(:ang,    :int)
    define_attribute(:scaled, :bool)
    define_element_name 'a:lin'
  end

  # http://www.datypic.com/sc/ooxml/e-a_tileRect-1.html
  class CT_RelativeRect < OOXMLObject
    define_attribute(:l, :int, :default => 0)
    define_attribute(:t, :int, :default => 0)
    define_attribute(:r, :int, :default => 0)
    define_attribute(:b, :int, :default => 0)
    define_element_name 'a:tileRect'
  end

  # http://www.datypic.com/sc/ooxml/e-a_path-1.html
  class CT_PathShadeProperties < OOXMLObject
    define_child_node(CT_RelativeRect, :node_name => 'a:fillToRect')
    define_attribute(:path, RubyXL::ST_PathShadeType)
    define_element_name 'a:path'
  end

  # http://www.datypic.com/sc/ooxml/e-a_gradFill-1.html
  class CT_GradientFillProperties < OOXMLObject
    define_child_node(RubyXL::CT_GradientStopList)
    define_child_node(RubyXL::CT_LinearShadeProperties)
    define_child_node(RubyXL::CT_PathShadeProperties)
    define_child_node(RubyXL::CT_RelativeRect)
    define_attribute(:flip,         RubyXL::ST_TileFlipMode)
    define_attribute(:rotWithShape, :bool)
    define_element_name 'a:gradFill'
  end

  # http://www.datypic.com/sc/ooxml/e-a_pattFill-1.html
  class CT_PatternFillProperties < OOXMLObject
    define_child_node(RubyXL::CT_Color, :node_name => 'a:fgClr')
    define_child_node(RubyXL::CT_Color, :node_name => 'a:bgClr')
    define_attribute(:prst, RubyXL::ST_PresetPatternVal)
    define_element_name 'a:pattFill'
  end

  # http://www.datypic.com/sc/ooxml/e-a_tile-1.html
  class CT_TileInfoProperties < OOXMLObject
    define_attribute(:tx,    :int)
    define_attribute(:ty,    :int)
    define_attribute(:sx,    :int)
    define_attribute(:sy,    :int)
    define_attribute(:flip,  RubyXL::ST_TileFlipMode)
    define_attribute(:align, RubyXL::ST_RectAlignment)
    define_element_name 'a:tile'
  end

  # http://www.datypic.com/sc/ooxml/e-a_stretch-1.html
  class CT_StretchInfoProperties < OOXMLObject
    define_child_node(RubyXL::CT_RelativeRect, :node_name => 'a:fillRect')
    define_element_name 'a:stretch'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_TintEffect.html
  class CT_TintEffect < OOXMLObject
    define_attribute(:hue, :int, :default => 0)
    define_attribute(:amt, :int, :default => 0)
    define_element_name 'a:tint'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_HSLEffect.html
  class CT_HSLEffect < OOXMLObject
    define_attribute(:hue, :int, :default => 0)
    define_attribute(:sat, :int, :default => 0)
    define_attribute(:lum, :int, :default => 0)
    define_element_name 'a:hsl'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_LuminanceEffect.html
  class CT_LuminanceEffect < OOXMLObject
    define_attribute(:bright,   :int, :default => 0)
    define_attribute(:contrast, :int, :default => 0)
    define_element_name 'a:lum'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_AlphaBiLevelEffect.html
  class CT_AlphaBiLevelEffect < OOXMLObject
    define_attribute(:thresh, :int, :required => true)
    define_element_name 'a:alphaBiLevel'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_AlphaModulateFixedEffect.html
  class CT_AlphaModulateFixedEffect < OOXMLObject
    define_attribute(:amt, :int, :default => 100000)
    define_element_name 'a:alphaModFix'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_AlphaReplaceEffect.html
  class CT_AlphaReplaceEffect < OOXMLObject
    define_attribute(:a, :int, :required => true)
    define_element_name 'a:alphaRepl'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_BiLevelEffect.html
  class CT_BiLevelEffect < OOXMLObject
    define_attribute(:thresh, :int, :required => true, :default => 100000)
    define_element_name 'a:biLevel'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_BlurEffect.html
  class CT_BlurEffect < OOXMLObject
    define_attribute(:rad,  :int,  :default => 0)
    define_attribute(:grow, :bool, :default => true)
    define_element_name 'a:blur'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_DuotoneEffect.html
  class CT_DuotoneEffect < OOXMLObject
    define_attribute(:rad,  :int,  :default => 0)
    define_attribute(:grow, :bool, :default => true)
    define_element_name 'a:blur'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_ColorChangeEffect.html
  class CT_ColorChangeEffect < OOXMLObject
    define_child_node(RubyXL::CT_Color, :node_name => 'a:clrFrom')
    define_child_node(RubyXL::CT_Color, :node_name => 'a:clrTo')
    define_attribute(:useA, :bool, :default => true)
    define_element_name 'a:clrChange'
  end

  class CT_EffectContainer < OOXMLObject
    # Defining class here without actually filling the OOXML definitions
    # so it can reference itself in the actual definition.
  end

  # http://www.datypic.com/sc/ooxml/e-a_alphaMod-2.html
  class CT_AlphaModulateEffect < OOXMLObject
    define_child_node(RubyXL::CT_EffectContainer, :node_name => :cont)
    define_element_name 'a:alphaMod'
  end

  # http://www.datypic.com/sc/ooxml/e-a_blend-1.html
  class CT_BlendEffect < OOXMLObject
    define_child_node(RubyXL::CT_EffectContainer, :node_name => :cont)
    define_attribute(:blend, RubyXL::ST_BlendMode, :required => true)
    define_element_name 'a:blend'
  end

  # http://www.datypic.com/sc/ooxml/e-a_effect-1.html
  class CT_EffectReference < OOXMLObject
    define_attribute(:ref, :string)
    define_element_name 'a:effect'
  end

  # http://www.datypic.com/sc/ooxml/e-a_alphaOutset-1.html
  class CT_AlphaOutsetEffect < OOXMLObject
    define_attribute(:rad, :int, :default => 0)
    define_element_name 'a:alphaOutset'
  end

  # http://www.datypic.com/sc/ooxml/e-a_blip-1.html
  class CT_Blip < OOXMLObject
    define_child_node(RubyXL::CT_AlphaBiLevelEffect)
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:alphaCeiling')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:alphaFloor')
    define_child_node(RubyXL::CT_Color,     :node_name => 'a:alphaInv')
    define_child_node(RubyXL::CT_AlphaModulateEffect)
    define_child_node(RubyXL::CT_AlphaModulateFixedEffect)
    define_child_node(RubyXL::CT_AlphaReplaceEffect)
    define_child_node(RubyXL::CT_BiLevelEffect)
    define_child_node(RubyXL::CT_BlurEffect)
    define_child_node(RubyXL::CT_ColorChangeEffect)
    define_child_node(RubyXL::CT_Color,     :node_name => 'a:clrRepl')
    define_child_node(RubyXL::CT_Color,     :node_name => 'a:duotone')
    define_child_node(RubyXL::CT_Color,     :node_name => 'a:fillOverlay')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:grayscl')
    define_child_node(RubyXL::CT_HSLEffect)
    define_child_node(RubyXL::CT_LuminanceEffect)
    define_child_node(RubyXL::CT_TintEffect)
    define_attribute(:'r:embed', :string)
    define_attribute(:'r:link',  :string)
    define_attribute(:cstate,    RubyXL::ST_BlipCompression)
    define_element_name 'a:blip'
  end

  # http://www.datypic.com/sc/ooxml/e-a_blipFill-1.html
  class CT_BlipFillProperties < OOXMLObject
    define_child_node(RubyXL::CT_Blip)
    define_child_node(RubyXL::CT_RelativeRect, :node_name => 'a:srcRect')
    define_child_node(RubyXL::CT_TileInfoProperties)
    define_child_node(RubyXL::CT_StretchInfoProperties)
    define_attribute(:dpi,          :int)
    define_attribute(:rotWithShape, :bool)
    define_element_name 'a:blipFill'
  end

  # http://www.datypic.com/sc/ooxml/e-a_fill-1.html
  class CT_FillEffect < OOXMLObject
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:noFill')
    define_child_node(RubyXL::CT_Color,     :node_name => 'a:solidFill')
    define_child_node(RubyXL::CT_GradientFillProperties)
    define_child_node(RubyXL::CT_BlipFillProperties)
    define_child_node(RubyXL::CT_PatternFillProperties)
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:grpFill')
    define_element_name 'a:fill'
  end

  # http://www.datypic.com/sc/ooxml/e-a_fillOverlay-1.html
  class CT_FillOverlayEffect < OOXMLObject
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:noFill')
    define_child_node(RubyXL::CT_Color,     :node_name => 'a:solidFill')
    define_child_node(RubyXL::CT_GradientFillProperties)
    define_child_node(RubyXL::CT_BlipFillProperties)
    define_child_node(RubyXL::CT_PatternFillProperties)
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:grpFill')
    define_attribute(:blend, RubyXL::ST_BlendMode)
    define_element_name 'a:fillOverlay'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_GlowEffect.html
  class CT_GlowEffect < OOXMLObject
    define_child_node(RubyXL::CT_ScRgbColor)
    define_child_node(RubyXL::CT_SRgbColor)
    define_child_node(RubyXL::CT_HslColor)
    define_child_node(RubyXL::CT_SystemColor)
    define_child_node(RubyXL::CT_SchemeColor)
    define_child_node(RubyXL::CT_PresetColor)
    define_attribute(:rad, :int, :default => 0)
    define_element_name 'a:glow'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_InnerShadowEffect.html
  class CT_InnerShadowEffect < OOXMLObject
    define_child_node(RubyXL::CT_ScRgbColor)
    define_child_node(RubyXL::CT_SRgbColor)
    define_child_node(RubyXL::CT_HslColor)
    define_child_node(RubyXL::CT_SystemColor)
    define_child_node(RubyXL::CT_SchemeColor)
    define_child_node(RubyXL::CT_PresetColor)
    define_attribute(:blurRad, :int, :default => 0)
    define_attribute(:dist,    :int, :default => 0)
    define_attribute(:dir,     :int, :default => 0)
    define_element_name 'a:innerShdw'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_OuterShadowEffect.html
  class CT_OuterShadowEffect < OOXMLObject
    define_child_node(RubyXL::CT_ScRgbColor)
    define_child_node(RubyXL::CT_SRgbColor)
    define_child_node(RubyXL::CT_HslColor)
    define_child_node(RubyXL::CT_SystemColor)
    define_child_node(RubyXL::CT_SchemeColor)
    define_child_node(RubyXL::CT_PresetColor)
    define_attribute(:blurRad,      :int,  :default => 0)
    define_attribute(:dist,         :int,  :default => 0)
    define_attribute(:dir,          :int,  :default => 0)
    define_attribute(:sx,           :int,  :default => 100000)
    define_attribute(:sy,           :int,  :default => 100000)
    define_attribute(:kx,           :int,  :default => 0)
    define_attribute(:ky,           :int,  :default => 0)
    define_attribute(:algn,         RubyXL::ST_RectAlignment, :default => 'b')
    define_attribute(:rotWithShape, :bool, :default => true)
    define_element_name 'a:outerShdw'
  end

  # http://www.datypic.com/sc/ooxml/e-a_prstShdw-1.html
  class CT_PresetShadowEffect < OOXMLObject
    define_child_node(RubyXL::CT_ScRgbColor)
    define_child_node(RubyXL::CT_SRgbColor)
    define_child_node(RubyXL::CT_HslColor)
    define_child_node(RubyXL::CT_SystemColor)
    define_child_node(RubyXL::CT_SchemeColor)
    define_child_node(RubyXL::CT_PresetColor)
    define_attribute(:prst, RubyXL::ST_PresetShadowVal, :required => true)
    define_attribute(:dist, :int, :default => 0)
    define_attribute(:dir,  :int, :default => 0)
    define_element_name 'a:prstShdw'
  end

  # http://www.datypic.com/sc/ooxml/e-a_reflection-1.html
  class CT_ReflectionEffect < OOXMLObject
    define_attribute(:blurRad,      :int,  :default => 0)
    define_attribute(:stA,          :int,  :default => 100000)
    define_attribute(:stPos,        :int,  :default => 0)
    define_attribute(:endA,         :int,  :default => 0)
    define_attribute(:endPos,       :int,  :default => 100000)
    define_attribute(:dist,         :int,  :default => 0)
    define_attribute(:dir,          :int,  :default => 0)
    define_attribute(:fadeDir,      :int,  :default => 5400000)
    define_attribute(:sx,           :int,  :default => 100000)
    define_attribute(:sy,           :int,  :default => 100000)
    define_attribute(:kx,           :int,  :default => 0)
    define_attribute(:ky,           :int,  :default => 0)
    define_attribute(:algn,         RubyXL::ST_RectAlignment, :default => 'b')
    define_attribute(:rotWithShape, :bool, :default => true)
    define_element_name 'a:reflection'
  end

  # http://www.datypic.com/sc/ooxml/e-a_relOff-1.html
  class CT_RelativeOffsetEffect < OOXMLObject
    define_attribute(:tx, :int)
    define_attribute(:ty, :int)
    define_element_name 'a:relOff'
  end

  # http://www.datypic.com/sc/ooxml/e-a_softEdge-1.html
  class CT_SoftEdgesEffect < OOXMLObject
    define_attribute(:rad, :int, :required => true)
    define_element_name 'a:softEdge'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_TransformEffect.html
  class CT_TransformEffect < OOXMLObject
    define_attribute(:sx, :int, :default => 100000)
    define_attribute(:sy, :int, :default => 100000)
    define_attribute(:kx, :int, :default => 0)
    define_attribute(:ky, :int, :default => 0)
    define_attribute(:tx, :int, :default => 0)
    define_attribute(:ty, :int, :default => 0)
    define_element_name 'a:xfrm'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_EffectContainer.html
  class CT_EffectContainer < OOXMLObject
    define_child_node(RubyXL::CT_EffectContainer, :node_name => 'a:cont')
    define_child_node(RubyXL::CT_EffectReference)
    define_child_node(RubyXL::CT_AlphaBiLevelEffect)
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:alphaCeiling')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:alphaFloor')
    define_child_node(RubyXL::CT_Color,     :node_name => 'a:alphaInv')
    define_child_node(RubyXL::CT_AlphaModulateEffect)
    define_child_node(RubyXL::CT_AlphaModulateFixedEffect)
    define_child_node(RubyXL::CT_AlphaOutsetEffect)
    define_child_node(RubyXL::CT_AlphaReplaceEffect)
    define_child_node(RubyXL::CT_BiLevelEffect)
    define_child_node(RubyXL::CT_BlendEffect)
    define_child_node(RubyXL::CT_BlurEffect)
    define_child_node(RubyXL::CT_ColorChangeEffect)
    define_child_node(RubyXL::CT_Color,     :node_name => 'a:clrRepl')
    define_child_node(RubyXL::CT_Color,     :node_name => 'a:duotone')
    define_child_node(RubyXL::CT_FillEffect)
    define_child_node(RubyXL::CT_FillOverlayEffect)
    define_child_node(RubyXL::CT_GlowEffect)
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:grayscl')
    define_child_node(RubyXL::CT_HSLEffect)
    define_child_node(RubyXL::CT_InnerShadowEffect)
    define_child_node(RubyXL::CT_LuminanceEffect)
    define_child_node(RubyXL::CT_OuterShadowEffect)
    define_child_node(RubyXL::CT_PresetShadowEffect)
    define_child_node(RubyXL::CT_ReflectionEffect)
    define_child_node(RubyXL::CT_RelativeOffsetEffect)
    define_child_node(RubyXL::CT_SoftEdgesEffect)
    define_child_node(RubyXL::CT_TintEffect)
    define_child_node(RubyXL::CT_TransformEffect)
    define_attribute(:type, RubyXL::ST_EffectContainerType, :default => 'sib')
    define_attribute(:name, :string)
  end

  # http://www.datypic.com/sc/ooxml/e-a_fillStyleLst-1.html
  class CT_FillStyleList < OOXMLObject
    # -- Choice [3..*] (EG_FillProperties)
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:noFill')
    define_child_node(RubyXL::CT_Color,     :node_name => 'a:solidFill', :collection => true)
    define_child_node(RubyXL::CT_GradientFillProperties, :collection => true)
    define_child_node(RubyXL::CT_BlipFillProperties,     :collection => true)
    define_child_node(RubyXL::CT_PatternFillProperties,  :collection => true)
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:grpFill')
    # --
    define_element_name 'a:fillStyleLst'
  end

  # http://www.datypic.com/sc/ooxml/e-a_miter-1.html
  class CT_LineJoinMiterProperties < OOXMLObject
    define_attribute(:lim, :int)
    define_element_name 'a:miter'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_LineEndProperties.html
  class CT_LineEndProperties < OOXMLObject
    define_attribute(:type, RubyXL::ST_LineEndType)
    define_attribute(:w,    RubyXL::ST_LineEndWidth)
    define_attribute(:len,  RubyXL::ST_LineEndLength)
  end

  # http://www.datypic.com/sc/ooxml/e-a_prstDash-1.html
  class CT_PresetLineDashProperties < OOXMLObject
    define_attribute(:val, RubyXL::ST_PresetLineDashVal)
    define_element_name 'a:prstDash'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_DashStop.html
  class CT_DashStop < OOXMLObject
    define_attribute(:d,  :int, :required => true)
    define_attribute(:sp, :int, :required => true)
    define_element_name 'a:ds'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_DashStopList.html
  class CT_DashStopList < OOXMLContainerObject
    define_child_node(RubyXL::CT_DashStop, :collection => [0..-1])
    define_element_name 'a:custDash'
  end

  # http://www.datypic.com/sc/ooxml/e-a_ln-1.html
  class CT_LineProperties < OOXMLObject
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:noFill')
    define_child_node(RubyXL::CT_Color,     :node_name => 'a:solidFill')
    define_child_node(RubyXL::CT_GradientFillProperties)
    define_child_node(RubyXL::CT_PatternFillProperties)
    define_child_node(RubyXL::CT_PresetLineDashProperties)
    define_child_node(RubyXL::CT_DashStopList)
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:round')
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:bevel')
    define_child_node(RubyXL::CT_LineJoinMiterProperties)
    define_child_node(RubyXL::CT_LineEndProperties, :node_name => 'a:headEnd')
    define_child_node(RubyXL::CT_LineEndProperties, :node_name => 'a:tailEnd')
    define_child_node(RubyXL::AExtensionStorageArea)
    define_attribute(:w,    :int)
    define_attribute(:cap,  RubyXL::ST_LineCap)
    define_attribute(:cmpd, RubyXL::ST_CompoundLine)
    define_attribute(:algn, RubyXL::ST_PenAlignment)
    define_element_name 'a:ln'
  end

  # http://www.datypic.com/sc/ooxml/e-a_lnStyleLst-1.html
  class CT_LineStyleList < OOXMLContainerObject
    define_child_node(RubyXL::CT_LineProperties, :collection => [3..-1])
    define_element_name 'a:lnStyleLst'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_SphereCoords.html
  class CT_SphereCoords < OOXMLObject
    define_attribute(:lat, :int, :required => true)
    define_attribute(:lon, :int, :required => true)
    define_attribute(:rev, :int, :required => true)
    define_element_name 'a:rot'
  end

  # http://www.datypic.com/sc/ooxml/e-a_camera-1.html
  class CT_Camera < OOXMLObject
    define_child_node(RubyXL::CT_SphereCoords)
    define_attribute(:prst, RubyXL::ST_PresetCameraType, :required => true)
    define_attribute(:fov,  :int)
    define_attribute(:zoom, :int, :default => 100000)
    define_element_name 'a:camera'
  end

  # http://www.datypic.com/sc/ooxml/e-a_lightRig-1.html
  class CT_LightRig < OOXMLObject
    define_child_node(RubyXL::CT_SphereCoords)
    define_attribute(:rig, RubyXL::ST_LightRigType,      :required => true)
    define_attribute(:dir, RubyXL::ST_LightRigDirection, :required => true)
    define_element_name 'a:lightRig'
  end

  # http://www.datypic.com/sc/ooxml/e-a_anchor-1.html
  class CT_Point3D < OOXMLObject
    define_attribute(:x, :int, :required => true)
    define_attribute(:y, :int, :required => true)
    define_attribute(:z, :int, :required => true)
    define_element_name 'a:anchor'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_Vector3D.html
  class CT_Vector3D < OOXMLObject
    define_attribute(:dx, :int, :required => true)
    define_attribute(:dy, :int, :required => true)
    define_attribute(:dz, :int, :required => true)
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_Backdrop.html
  class CT_Backdrop < OOXMLObject
    define_child_node(RubyXL::CT_Point3D)
    define_child_node(RubyXL::CT_Vector3D, :node_name => 'a:norm')
    define_child_node(RubyXL::CT_Vector3D, :node_name => 'a:up')
    define_child_node(RubyXL::AExtensionStorageArea)
    define_element_name 'a:backdrop'
  end

  # http://www.datypic.com/sc/ooxml/e-a_scene3d-1.html
  class CT_Scene3D < OOXMLObject
    define_child_node(RubyXL::CT_Camera,   :required => true)
    define_child_node(RubyXL::CT_LightRig, :required => true)
    define_child_node(RubyXL::CT_Backdrop)
    define_child_node(RubyXL::AExtensionStorageArea)
    define_element_name 'a:scene3d'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_Bevel.html
  class CT_Bevel < OOXMLObject
    define_attribute(:w,    :int, :default => 76200)
    define_attribute(:h,    :int, :default => 76200)
    define_attribute(:prst, RubyXL::ST_BevelPresetType)
    define_element_name 'a:CT_Bevel'
  end

  # http://www.datypic.com/sc/ooxml/e-a_sp3d-1.html
  class CT_Shape3D < OOXMLObject
    define_child_node(RubyXL::CT_Bevel, :node_name => 'a:bevelT')
    define_child_node(RubyXL::CT_Bevel, :node_name => 'a:bevelB')
    define_child_node(RubyXL::CT_Color, :node_name => 'a:extrusionClr')
    define_child_node(RubyXL::CT_Color, :node_name => 'a:contourClr')
    define_child_node(RubyXL::AExtensionStorageArea)
    define_attribute(:z,            :int, :default => 0)
    define_attribute(:extrusionH,   :int, :default => 0)
    define_attribute(:contourW,     :int, :default => 0)
    define_attribute(:prstMaterial, RubyXL::ST_PresetMaterialType, :default => 'warmMatte')
    define_element_name 'a:sp3d'
  end

  # http://www.datypic.com/sc/ooxml/e-a_effectLst-1.html
  class CT_EffectList < OOXMLObject
    define_child_node(RubyXL::CT_BlurEffect)
    define_child_node(RubyXL::CT_FillOverlayEffect)
    define_child_node(RubyXL::CT_GlowEffect)
    define_child_node(RubyXL::CT_InnerShadowEffect)
    define_child_node(RubyXL::CT_OuterShadowEffect)
    define_child_node(RubyXL::CT_PresetShadowEffect)
    define_child_node(RubyXL::CT_ReflectionEffect)
    define_child_node(RubyXL::CT_SoftEdgesEffect)
    define_element_name 'a:effectLst'
  end

  # http://www.datypic.com/sc/ooxml/e-a_effectStyle-1.html
  class CT_EffectStyleItem < OOXMLObject
    define_child_node(RubyXL::CT_EffectList)
    define_child_node(RubyXL::CT_EffectContainer, :node_name => 'a:effectDag')
    define_child_node(RubyXL::CT_Scene3D)
    define_child_node(RubyXL::CT_Shape3D)
    define_element_name 'a:effectStyle'
  end

  # http://www.datypic.com/sc/ooxml/e-a_effectStyleLst-1.html
  class CT_EffectStyleList < OOXMLContainerObject
    define_child_node(RubyXL::CT_EffectStyleItem, :collection => [3..-1])
    define_element_name 'a:effectStyleLst'
  end

  # http://www.datypic.com/sc/ooxml/e-a_fmtScheme-1.html
  class CT_StyleMatrix < OOXMLObject
    define_child_node(RubyXL::CT_FillStyleList,   :required => true)
    define_child_node(RubyXL::CT_LineStyleList,   :required => true)
    define_child_node(RubyXL::CT_EffectStyleList, :required => true)
    define_child_node(RubyXL::CT_FillStyleList,   :required => true, :node_name => 'a:bgFillStyleLst')
    define_attribute(:name, :string)
    define_element_name 'a:fmtScheme'
  end

  # http://www.datypic.com/sc/ooxml/e-a_themeElements-1.html
  class ThemeElements < OOXMLObject
    define_child_node(RubyXL::CT_ColorScheme)
    define_child_node(RubyXL::FontScheme)
    define_child_node(RubyXL::CT_StyleMatrix)
    define_child_node(RubyXL::AExtensionStorageArea)
    define_element_name 'a:themeElements'
  end

  # http://www.datypic.com/sc/ooxml/e-a_off-1.html
  class Offset < OOXMLObject
    define_attribute(:x, :int, :required => true)
    define_attribute(:y, :int, :required => true)
    define_element_name 'a:off'
  end

  # http://www.datypic.com/sc/ooxml/e-a_ext-2.html
  class Extents < OOXMLObject
    define_attribute(:cx, :int, :required => true)
    define_attribute(:cy, :int, :required => true)
    define_element_name 'a:ext'
  end

  # http://www.datypic.com/sc/ooxml/e-a_xfrm-4.html
  class CT_Transform2D < OOXMLObject
    define_attribute(:rot,   :int,  :default => 0)
    define_attribute(:flipH, :bool, :default => false)
    define_attribute(:flipV, :bool, :default => false)
    define_child_node(RubyXL::Offset)
    define_child_node(RubyXL::Extents)
    define_element_name 'a:xfrm'
  end

  # http://www.datypic.com/sc/ooxml/e-a_gd-1.html
  class ShapeGuide < OOXMLObject
    define_attribute(:name, :string, :required => true)
    define_attribute(:fmla, :string, :required => true)
    define_element_name 'a:gd'
  end

  # http://www.datypic.com/sc/ooxml/e-a_avLst-1.html
  class CT_GeomGuideList < OOXMLContainerObject
    define_child_node(RubyXL::ShapeGuide, :collection => [0..-1])
  end

  # http://www.datypic.com/sc/ooxml/e-a_rect-1.html
  class ShapeTextRectangle < OOXMLObject
    define_attribute(:l, :int, :required => true)
    define_attribute(:t, :int, :required => true)
    define_attribute(:r, :int, :required => true)
    define_attribute(:b, :int, :required => true)
    define_element_name 'a:rect'
  end

  # http://www.datypic.com/sc/ooxml/e-a_pos-2.html
  class CT_AdjPoint2D < OOXMLObject
    define_attribute(:x, :int, :required => true)
    define_attribute(:y, :int, :required => true)
    define_element_name 'a:pos'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_PolarAdjustHandle.html
  class CT_XYAdjustHandle < OOXMLObject
    define_child_node(RubyXL::CT_AdjPoint2D)
    define_attribute(:gdRefX, :string)
    define_attribute(:minX,   :int)
    define_attribute(:maxX,   :int)
    define_attribute(:gdRefY, :string)
    define_attribute(:minY,   :int)
    define_attribute(:maxY,   :int)
    define_element_name 'a:ahXY'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_PolarAdjustHandle.html
  class CT_PolarAdjustHandle < OOXMLObject
    define_child_node(RubyXL::CT_AdjPoint2D)
    define_attribute(:gdRefR,   :string)
    define_attribute(:minR,     :int)
    define_attribute(:maxR,     :int)
    define_attribute(:gdRefAng, :string)
    define_attribute(:minAng,   :int)
    define_attribute(:maxAng,   :int)
    define_element_name 'a:ahPolar'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_AdjustHandleList.html
  class AdjustHandleList < OOXMLObject
    define_child_node(RubyXL::CT_XYAdjustHandle)
    define_child_node(RubyXL::CT_PolarAdjustHandle)
    define_element_name 'a:ahLst'
  end

  # http://www.datypic.com/sc/ooxml/e-a_cxn-1.html
  class CT_ConnectionSite < OOXMLObject
    define_child_node(RubyXL::CT_AdjPoint2D)
    define_attribute(:ang, :int)
    define_element_name 'a:cxn'
  end

  # http://www.datypic.com/sc/ooxml/e-a_cxnLst-1.html
  class CT_ConnectionSiteList < OOXMLContainerObject
    define_child_node(RubyXL::CT_ConnectionSite, :collection => [0..-1])
    define_element_name 'a:cxnLst'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_Path2DLineTo.html
  class CT_Path2DTo < OOXMLContainerObject
    define_child_node(RubyXL::CT_AdjPoint2D)
  end

  # http://www.datypic.com/sc/ooxml/e-a_arcTo-1.html
  class CT_Path2DArcTo < OOXMLObject
    define_attribute(:wR,    :int, :required => true)
    define_attribute(:hR,    :int, :required => true)
    define_attribute(:stAng, :int, :required => true)
    define_attribute(:swAng, :int, :required => true)
    define_element_name 'a:arcTo'
  end

  # http://www.datypic.com/sc/ooxml/e-a_quadBezTo-1.html
  class CT_Path2DQuadBezierTo < OOXMLContainerObject
    define_child_node(RubyXL::CT_AdjPoint2D, :collection => [2..2], :node_name => 'a:pt')
    define_element_name 'a:quadBezTo'
  end

  # http://www.datypic.com/sc/ooxml/e-a_quadBezTo-1.html
  class CT_Path2DCubicBezierTo < OOXMLContainerObject
    define_child_node(RubyXL::CT_AdjPoint2D, :collection => [2..2], :node_name => 'a:pt')
    define_element_name 'a:cubicBezTo'
  end

  # http://www.datypic.com/sc/ooxml/e-a_path-2.html
  class CT_Path2D < OOXMLObject
    define_child_node(RubyXL::BooleanValue,           :node_name => 'a:close')
    define_child_node(RubyXL::CT_Path2DTo,            :node_name => 'a:moveTo')
    define_child_node(RubyXL::CT_Path2DTo,            :node_name => 'a:lnTo')
    define_child_node(RubyXL::CT_Path2DArcTo,         :node_name => 'a:arcTo')
    define_child_node(RubyXL::CT_Path2DQuadBezierTo)
    define_child_node(RubyXL::CT_Path2DCubicBezierTo)
    define_attribute(:w,           :int,  :default => 0)
    define_attribute(:h,           :int,  :default => 0)
    define_attribute(:fill,        RubyXL::ST_PathFillMode, :default => 'norm')
    define_attribute(:stroke,      :bool, :default => true)
    define_attribute(:extrusionOk, :bool, :default => true)
    define_element_name 'a:path'
  end

  # http://www.datypic.com/sc/ooxml/e-a_pathLst-1.html
  class CT_Path2DList < OOXMLContainerObject
    define_child_node(RubyXL::CT_Path2D, :collection => [0..-1])
    define_element_name 'a:pathLst'
  end

  # http://www.datypic.com/sc/ooxml/e-a_custGeom-1.html
  class CustomGeometry < OOXMLObject
    define_child_node(RubyXL::CT_GeomGuideList, :node_name => 'a:avLst')
    define_child_node(RubyXL::CT_GeomGuideList, :node_name => 'a:gdLst')
    define_child_node(RubyXL::AdjustHandleList)
    define_child_node(RubyXL::CT_ConnectionSiteList)
    define_child_node(RubyXL::ShapeTextRectangle)
    define_child_node(RubyXL::CT_Path2DList)
    define_element_name 'a:custGeom'
  end

  # http://www.datypic.com/sc/ooxml/e-a_prstGeom-1.html
  class PresetGeometry < OOXMLObject
    define_child_node(RubyXL::CT_GeomGuideList, :node_name => 'a:avLst')
    define_attribute(:prst, RubyXL::ST_ShapeType, :required => true)
    define_element_name 'a:prstGeom'
  end

  # http://www.datypic.com/sc/ooxml/e-a_spPr-1.html
  class VisualProperties < OOXMLObject
    define_child_node(RubyXL::CT_Transform2D)
    # -- Choice [0..1] (EG_Geometry)
    define_child_node(RubyXL::CustomGeometry)
    define_child_node(RubyXL::PresetGeometry)
    # -- Choice [0..1] (EG_FillProperties)
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:noFill')
    define_child_node(RubyXL::CT_Color,     :node_name => 'a:solidFill')
    define_child_node(RubyXL::CT_GradientFillProperties)
    define_child_node(RubyXL::CT_BlipFillProperties)
    define_child_node(RubyXL::CT_PatternFillProperties)
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:grpFill')
    # --
    define_child_node(RubyXL::CT_LineProperties)
    # -- Choice [0..1] (EG_EffectProperties)
    define_child_node(RubyXL::CT_EffectList)
    define_child_node(RubyXL::CT_EffectContainer, :node_name => 'a:effectDag')
    # --
    define_child_node(RubyXL::CT_Scene3D)
    define_child_node(RubyXL::CT_Shape3D)
    define_child_node(RubyXL::AExtensionStorageArea)
    define_attribute(:bwMode, RubyXL::ST_BlackWhiteMode)
    define_element_name 'a:spPr'
  end

  # http://www.datypic.com/sc/ooxml/e-a_prstTxWarp-2.html
  class CT_PresetTextShape < OOXMLObject
    define_child_node(RubyXL::CT_GeomGuideList, :node_name => 'a:avLst')
    define_attribute(:prst, RubyXL::ST_TextShapeType)
    define_element_name 'a:prstTxWarp'
  end

  # http://www.datypic.com/sc/ooxml/e-a_normAutofit-1.html
  class CT_TextNormalAutofit < OOXMLObject
    define_attribute(:fontScale,      :int, :default => 100000)
    define_attribute(:lnSpcReduction, :int, :default => 0)
    define_element_name 'a:normAutofit'
  end

  # http://www.datypic.com/sc/ooxml/e-a_flatTx-1.html
  class CT_FlatText < OOXMLObject
    define_attribute(:z, :int, :default => 0)
    define_element_name 'a:flatTx'
  end

  # http://www.datypic.com/sc/ooxml/e-a_bodyPr-1.html
  class BodyProperties < OOXMLObject
    define_child_node(RubyXL::CT_PresetTextShape)
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:noAutofit')
    define_child_node(RubyXL::CT_TextNormalAutofit)
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:spAutoFit')
    define_child_node(RubyXL::CT_Scene3D)
    define_child_node(RubyXL::CT_Shape3D)
    define_child_node(RubyXL::CT_FlatText)
    define_child_node(RubyXL::AExtensionStorageArea)
    define_attribute(:rot, :int)
    define_attribute(:spcFirstLastPara, :bool)
    define_attribute(:vertOverflow,     RubyXL::ST_TextVertOverflowType)
    define_attribute(:horzOverflow,     RubyXL::ST_TextHorzOverflowType)
    define_attribute(:vert,             RubyXL::ST_TextVerticalType)
    define_attribute(:wrap,             RubyXL::ST_TextWrappingType)
    define_attribute(:lIns,             :int)
    define_attribute(:tIns,             :int)
    define_attribute(:rIns,             :int)
    define_attribute(:bIns,             :int)
    define_attribute(:numCol,           :int)
    define_attribute(:spcCol,           :int)
    define_attribute(:rtlCol,           :bool)
    define_attribute(:fromWordArt,      :bool)
    define_attribute(:anchor,           RubyXL::ST_TextAnchoringType)
    define_attribute(:anchorCtr,        :bool)
    define_attribute(:forceAA,          :bool)
    define_attribute(:upright,          :bool, :default => false)
    define_attribute(:compatLnSpc,      :bool)
    define_element_name 'a:bodyPr'
  end

  # http://www.datypic.com/sc/ooxml/e-a_tab-1.html
  class CT_TextTabStop < OOXMLObject
    define_attribute(:pos,  :int)
    define_attribute(:algn, RubyXL::ST_TextTabAlignType)
    define_element_name 'a:tabLst'
  end

  # http://www.datypic.com/sc/ooxml/e-a_tabLst-1.html
  class CT_TextTabStopList < OOXMLContainerObject
    define_child_node(RubyXL::CT_TextTabStop, :collection => [0..32])
    define_element_name 'a:tabLst'
  end

  # http://www.datypic.com/sc/ooxml/e-a_buAutoNum-1.html
  class CT_TextAutonumberBullet < OOXMLObject
    define_attribute(:type, RubyXL::ST_TextAutonumberScheme)
    define_attribute(:startAt, :int)
    define_element_name 'a:buAutoNum'
  end

  # http://www.datypic.com/sc/ooxml/e-a_buChar-1.html
  class CT_TextCharBullet < OOXMLObject
    define_attribute(:char, :string, :required => true)
    define_element_name 'a:buChar'
  end

  # http://www.datypic.com/sc/ooxml/e-a_buBlip-1.html
  class CT_TextBlipBullet < OOXMLObject
    define_child_node(RubyXL::CT_Blip)
    define_element_name 'a:buBlip'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_TextSpacing.html
  class CT_TextSpacing < OOXMLObject
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:spcPct')
    define_child_node(RubyXL::IntegerValue, :node_name => 'a:spcPts')
  end

  # http://www.datypic.com/sc/ooxml/e-a_snd-1.html
  class CT_EmbeddedWAVAudioFile < OOXMLObject
    define_attribute(:'r:embed', :string)
    define_attribute(:name,      :string, :default => '')
    define_attribute(:builtIn,   :bool,   :default => false)
    define_element_name 'a:snd'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_Hyperlink.html
  class CT_Hyperlink < OOXMLObject
    define_child_node(RubyXL::CT_EmbeddedWAVAudioFile)
    define_child_node(RubyXL::AExtensionStorageArea)
    define_relationship
    define_attribute(:invalidUrl,     :string, :default => '')
    define_attribute(:action,         :string, :default => '')
    define_attribute(:tgtFrame,       :string, :default => '')
    define_attribute(:tooltip,        :string, :default => '')
    define_attribute(:history,        :bool,   :default => true)
    define_attribute(:highlightClick, :bool,   :default => false)
    define_attribute(:endSnd,         :bool,   :default => false)
  end

  # http://www.datypic.com/sc/ooxml/e-a_defRPr-1.html
  class CT_TextCharacterProperties < OOXMLObject
    define_child_node(RubyXL::CT_LineProperties)
    # -- EG_FillProperties
    define_child_node(RubyXL::BooleanValue,      :node_name => 'a:noFill')
    define_child_node(RubyXL::CT_Color,          :node_name => 'a:solidFill')
    define_child_node(RubyXL::CT_GradientFillProperties)
    define_child_node(RubyXL::CT_BlipFillProperties)
    define_child_node(RubyXL::CT_PatternFillProperties)
    define_child_node(RubyXL::BooleanValue, :node_name => 'a:grpFill')
    # -- EG_EffectProperties
    define_child_node(RubyXL::CT_EffectList)
    define_child_node(RubyXL::CT_EffectContainer, :node_name => 'a:effectDag')
    # --
    define_child_node(RubyXL::CT_Color,          :node_name => 'a:highlight')
    # -- EG_TextUnderlineLine
    define_child_node(RubyXL::BooleanValue,      :node_name => 'a:uLnTx')
    define_child_node(RubyXL::CT_LineProperties, :node_name => 'a:uLn')
    # -- EG_TextUnderlineFill
    define_child_node(RubyXL::BooleanValue,      :node_name => 'a:uFillTx')
    define_child_node(RubyXL::CT_FillStyleList,  :node_name => 'a:uFill')
    define_child_node(RubyXL::CT_TextFont,       :node_name => 'a:latin')
    define_child_node(RubyXL::CT_TextFont,       :node_name => 'a:ea')
    define_child_node(RubyXL::CT_TextFont,       :node_name => 'a:cs')
    define_child_node(RubyXL::CT_TextFont,       :node_name => 'a:sym')
    define_child_node(RubyXL::CT_Hyperlink,      :node_name => 'a:hlinkClick')
    define_child_node(RubyXL::CT_Hyperlink,      :node_name => 'a:hlinkMouseOver')
    define_child_node(RubyXL::AExtensionStorageArea)
    define_attribute(:kumimoji,   :bool)
    define_attribute(:lang,       :string)
    define_attribute(:altLang,    :string)
    define_attribute(:sz,         :int)
    define_attribute(:b,          :bool)
    define_attribute(:i,          :bool)
    define_attribute(:u,          RubyXL::ST_TextUnderlineType)
    define_attribute(:strike,     RubyXL::ST_TextStrikeType)
    define_attribute(:kern,       :int)
    define_attribute(:cap,        RubyXL::ST_TextCapsType)
    define_attribute(:spc,        :int)
    define_attribute(:normalizeH, :bool)
    define_attribute(:baseline,   :int)
    define_attribute(:noProof,    :bool)
    define_attribute(:dirty,      :bool, :default => true)
    define_attribute(:err,        :bool, :default => false)
    define_attribute(:smtClean,   :bool, :default => true)
    define_attribute(:smtId,      :int,  :default => 0)
    define_attribute(:bmk,        :string)
    define_element_name 'a:defRPr'
  end

  # http://www.datypic.com/sc/ooxml/e-a_defPPr-1.html
  class CT_TextParagraphProperties < OOXMLObject
    define_child_node(RubyXL::CT_TextSpacing, :node_name => 'a:lnSpc')
    define_child_node(RubyXL::CT_TextSpacing, :node_name => 'a:spcBef')
    define_child_node(RubyXL::CT_TextSpacing, :node_name => 'a:spcAft')
    define_child_node(RubyXL::BooleanValue,   :node_name => 'a:buClrTx')
    define_child_node(RubyXL::CT_Color,       :node_name => 'a:buClr')
    define_child_node(RubyXL::BooleanValue,   :node_name => 'a:buSzTx')
    define_child_node(RubyXL::IntegerValue,   :node_name => 'a:buSzPct')
    define_child_node(RubyXL::IntegerValue,   :node_name => 'a:buSzPts')
    define_child_node(RubyXL::BooleanValue,   :node_name => 'a:buFontTx')
    define_child_node(RubyXL::CT_TextFont,    :node_name => 'a:buFont')
    define_child_node(RubyXL::BooleanValue,   :node_name => 'a:buNone')
    define_child_node(RubyXL::CT_TextAutonumberBullet)
    define_child_node(RubyXL::CT_TextCharBullet)
    define_child_node(RubyXL::CT_TextBlipBullet)
    define_child_node(RubyXL::CT_TextTabStop)
    define_child_node(RubyXL::CT_TextCharacterProperties)
    define_child_node(RubyXL::AExtensionStorageArea)
    define_attribute(:marL,         :int)
    define_attribute(:marR,         :int)
    define_attribute(:lvl,          :int)
    define_attribute(:indent,       :int)
    define_attribute(:algn,         RubyXL::ST_TextAlignType)
    define_attribute(:defTabSz,     :int)
    define_attribute(:rtl,          :bool)
    define_attribute(:eaLnBrk,      :bool)
    define_attribute(:fontAlgn,     RubyXL::ST_TextFontAlignType)
    define_attribute(:latinLnBrk,   :bool)
    define_attribute(:hangingPunct, :bool)
    define_element_name 'a:defPPr'
  end

  # http://www.datypic.com/sc/ooxml/e-a_lstStyle-1.html
  class CT_TextListStyle < OOXMLObject
    define_child_node(RubyXL::CT_TextParagraphProperties, :node_name => 'a:defPPr')
    define_child_node(RubyXL::CT_TextParagraphProperties, :node_name => 'a:lvl1pPr')
    define_child_node(RubyXL::CT_TextParagraphProperties, :node_name => 'a:lvl2pPr')
    define_child_node(RubyXL::CT_TextParagraphProperties, :node_name => 'a:lvl3pPr')
    define_child_node(RubyXL::CT_TextParagraphProperties, :node_name => 'a:lvl4pPr')
    define_child_node(RubyXL::CT_TextParagraphProperties, :node_name => 'a:lvl5pPr')
    define_child_node(RubyXL::CT_TextParagraphProperties, :node_name => 'a:lvl6pPr')
    define_child_node(RubyXL::CT_TextParagraphProperties, :node_name => 'a:lvl7pPr')
    define_child_node(RubyXL::CT_TextParagraphProperties, :node_name => 'a:lvl8pPr')
    define_child_node(RubyXL::CT_TextParagraphProperties, :node_name => 'a:lvl9pPr')
    define_child_node(RubyXL::AExtensionStorageArea)
    define_element_name 'a:lstStyle'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_StyleMatrixReference.html
  class CT_StyleMatrixReference < OOXMLObject
    define_child_node(RubyXL::CT_ScRgbColor)
    define_child_node(RubyXL::CT_SRgbColor)
    define_child_node(RubyXL::CT_HslColor)
    define_child_node(RubyXL::CT_SystemColor)
    define_child_node(RubyXL::CT_SchemeColor)
    define_child_node(RubyXL::CT_PresetColor)
    define_attribute(:idx, :int, :required => true)
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_FontReference.html
  class CT_FontReference < OOXMLObject
    define_child_node(RubyXL::CT_ScRgbColor)
    define_child_node(RubyXL::CT_SRgbColor)
    define_child_node(RubyXL::CT_HslColor)
    define_child_node(RubyXL::CT_SystemColor)
    define_child_node(RubyXL::CT_SchemeColor)
    define_child_node(RubyXL::CT_PresetColor)
    define_attribute(:idx, RubyXL::ST_FontCollectionIndex, :required => true)
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_ShapeStyle.html
  class CT_ShapeStyle < OOXMLObject
    define_child_node(RubyXL::CT_StyleMatrixReference, :node_name => 'a:lnRef')
    define_child_node(RubyXL::CT_StyleMatrixReference, :node_name => 'a:fillRef')
    define_child_node(RubyXL::CT_StyleMatrixReference, :node_name => 'a:effectRef')
    define_child_node(RubyXL::CT_FontReference,        :node_name => 'a:fontRef')
    define_element_name 'a:style'
  end

  # http://www.datypic.com/sc/ooxml/t-a_CT_DefaultShapeDefinition.html
  class CT_DefaultShapeDefinition < OOXMLObject
    define_child_node(RubyXL::VisualProperties)
    define_child_node(RubyXL::BodyProperties)
    define_child_node(RubyXL::CT_TextListStyle)
    define_child_node(RubyXL::CT_ShapeStyle)
    define_child_node(RubyXL::AExtensionStorageArea)
  end

  # http://www.datypic.com/sc/ooxml/e-a_objectDefaults-1.html
  class CT_ObjectStyleDefaults < OOXMLObject
    define_child_node(RubyXL::CT_DefaultShapeDefinition, :node_name => 'a:spDef')
    define_child_node(RubyXL::CT_DefaultShapeDefinition, :node_name => 'a:lnDef')
    define_child_node(RubyXL::CT_DefaultShapeDefinition, :node_name => 'a:txDef')
    define_child_node(RubyXL::AExtensionStorageArea)
    define_element_name 'a:objectDefaults'
  end

  # http://www.datypic.com/sc/ooxml/e-a_clrMap-1.html
  class CT_ColorMapping < OOXMLObject
    define_child_node(RubyXL::AExtensionStorageArea)
    define_attribute(:bg1,      RubyXL::ST_ColorSchemeIndex, :required => true)
    define_attribute(:tx1,      RubyXL::ST_ColorSchemeIndex, :required => true)
    define_attribute(:bg2,      RubyXL::ST_ColorSchemeIndex, :required => true)
    define_attribute(:tx2,      RubyXL::ST_ColorSchemeIndex, :required => true)
    define_attribute(:accent1,  RubyXL::ST_ColorSchemeIndex, :required => true)
    define_attribute(:accent2,  RubyXL::ST_ColorSchemeIndex, :required => true)
    define_attribute(:accent3,  RubyXL::ST_ColorSchemeIndex, :required => true)
    define_attribute(:accent4,  RubyXL::ST_ColorSchemeIndex, :required => true)
    define_attribute(:accent5,  RubyXL::ST_ColorSchemeIndex, :required => true)
    define_attribute(:accent6,  RubyXL::ST_ColorSchemeIndex, :required => true)
    define_attribute(:hlink,    RubyXL::ST_ColorSchemeIndex, :required => true)
    define_attribute(:golHlink, RubyXL::ST_ColorSchemeIndex, :required => true)
    define_element_name 'a:clrMap'
  end

  # http://www.datypic.com/sc/ooxml/e-a_extraClrScheme-1.html
  class CT_ColorSchemeAndMapping < OOXMLObject
    define_child_node(RubyXL::CT_ColorScheme)
    define_child_node(RubyXL::CT_ColorMapping)
    define_element_name 'a:extraClrScheme'
  end

  # http://www.datypic.com/sc/ooxml/e-a_extraClrSchemeLst-1.html
  class ExtraColorSchemeList < OOXMLContainerObject
    define_child_node(RubyXL::CT_ColorSchemeAndMapping, :collection => [0..-1])
    define_element_name 'a:extraClrSchemeLst'
  end

  # http://www.datypic.com/sc/ooxml/e-a_custClr-1.html
  class CustomColor < OOXMLObject
    define_child_node(RubyXL::CT_ScRgbColor)
    define_child_node(RubyXL::CT_SRgbColor)
    define_child_node(RubyXL::CT_HslColor)
    define_child_node(RubyXL::CT_SystemColor)
    define_child_node(RubyXL::CT_SchemeColor)
    define_child_node(RubyXL::CT_PresetColor)
    define_attribute(:name, :string, :default => '')
    define_element_name 'a:custClr'
  end

  # http://www.datypic.com/sc/ooxml/e-a_custClrLst-1.html
  class CustomColorList < OOXMLContainerObject
    define_child_node(RubyXL::CustomColor, :collection => [0..-1])
    define_element_name 'a:custClrLst'
  end

  # http://www.datypic.com/sc/ooxml/e-a_theme.html
  class Theme < OOXMLTopLevelObject
    CONTENT_TYPE = 'application/vnd.openxmlformats-officedocument.theme+xml'.freeze
    REL_TYPE     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme'.freeze

    define_attribute(:name, :string, :default => '')
    define_child_node(RubyXL::ThemeElements)
    define_child_node(RubyXL::CT_ObjectStyleDefaults)
    define_child_node(RubyXL::ExtraColorSchemeList)
    define_child_node(RubyXL::CustomColorList)
    define_child_node(RubyXL::AExtensionStorageArea)

    define_element_name 'a:theme'

    set_namespaces('http://schemas.openxmlformats.org/drawingml/2006/main' => 'a')

    def xlsx_path
      ROOT.join('xl', 'theme', 'theme1.xml')
    end

    def get_theme_color(idx)
      color_scheme = a_theme_elements&.a_clr_scheme

      return unless color_scheme

      case idx
      when 0 then color_scheme.a_lt1
      when 1 then color_scheme.a_dk1
      when 2 then color_scheme.a_lt2
      when 3 then color_scheme.a_dk2
      when 4 then color_scheme.a_accent1
      when 5 then color_scheme.a_accent2
      when 6 then color_scheme.a_accent3
      when 7 then color_scheme.a_accent4
      when 8 then color_scheme.a_accent5
      when 9 then color_scheme.a_accent6
      end
    end

    def self.default
      default_theme = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Office Theme">
<a:themeElements>
<a:clrScheme name="Office">
<a:dk1>
<a:sysClr val="windowText" lastClr="000000"/>
</a:dk1>
<a:lt1>
<a:sysClr val="window" lastClr="FFFFFF"/>
</a:lt1>
<a:dk2>
<a:srgbClr val="1F497D"/>
</a:dk2>
<a:lt2>
<a:srgbClr val="EEECE1"/>
</a:lt2>
<a:accent1>
<a:srgbClr val="4F81BD"/>
</a:accent1>
<a:accent2>
<a:srgbClr val="C0504D"/>
</a:accent2>
<a:accent3>
<a:srgbClr val="9BBB59"/>
</a:accent3>
<a:accent4>
<a:srgbClr val="8064A2"/>
</a:accent4>
<a:accent5>
<a:srgbClr val="4BACC6"/>
</a:accent5>
<a:accent6>
<a:srgbClr val="F79646"/>
</a:accent6>
<a:hlink>
<a:srgbClr val="0000FF"/>
</a:hlink>
<a:folHlink>
<a:srgbClr val="800080"/>
</a:folHlink>
</a:clrScheme>
<a:fontScheme name="Office">
<a:majorFont>
<a:latin typeface="Cambria"/>
<a:ea typeface=""/>
<a:cs typeface=""/>
<a:font script="Jpan" typeface="ＭＳ Ｐゴシック"/>
<a:font script="Hang" typeface="맑은 고딕"/>
<a:font script="Hans" typeface="宋体"/>
<a:font script="Hant" typeface="新細明體"/>
<a:font script="Arab" typeface="Times New Roman"/>
<a:font script="Hebr" typeface="Times New Roman"/>
<a:font script="Thai" typeface="Tahoma"/>
<a:font script="Ethi" typeface="Nyala"/>
<a:font script="Beng" typeface="Vrinda"/>
<a:font script="Gujr" typeface="Shruti"/>
<a:font script="Khmr" typeface="MoolBoran"/>
<a:font script="Knda" typeface="Tunga"/>
<a:font script="Guru" typeface="Raavi"/>
<a:font script="Cans" typeface="Euphemia"/>
<a:font script="Cher" typeface="Plantagenet Cherokee"/>
<a:font script="Yiii" typeface="Microsoft Yi Baiti"/>
<a:font script="Tibt" typeface="Microsoft Himalaya"/>
<a:font script="Thaa" typeface="MV Boli"/>
<a:font script="Deva" typeface="Mangal"/>
<a:font script="Telu" typeface="Gautami"/>
<a:font script="Taml" typeface="Latha"/>
<a:font script="Syrc" typeface="Estrangelo Edessa"/>
<a:font script="Orya" typeface="Kalinga"/>
<a:font script="Mlym" typeface="Kartika"/>
<a:font script="Laoo" typeface="DokChampa"/>
<a:font script="Sinh" typeface="Iskoola Pota"/>
<a:font script="Mong" typeface="Mongolian Baiti"/>
<a:font script="Viet" typeface="Times New Roman"/>
<a:font script="Uigh" typeface="Microsoft Uighur"/>
</a:majorFont>
<a:minorFont>
<a:latin typeface="Calibri"/>
<a:ea typeface=""/>
<a:cs typeface=""/>
<a:font script="Jpan" typeface="ＭＳ Ｐゴシック"/>
<a:font script="Hang" typeface="맑은 고딕"/>
<a:font script="Hans" typeface="宋体"/>
<a:font script="Hant" typeface="新細明體"/>
<a:font script="Arab" typeface="Arial"/>
<a:font script="Hebr" typeface="Arial"/>
<a:font script="Thai" typeface="Tahoma"/>
<a:font script="Ethi" typeface="Nyala"/>
<a:font script="Beng" typeface="Vrinda"/>
<a:font script="Gujr" typeface="Shruti"/>
<a:font script="Khmr" typeface="DaunPenh"/>
<a:font script="Knda" typeface="Tunga"/>
<a:font script="Guru" typeface="Raavi"/>
<a:font script="Cans" typeface="Euphemia"/>
<a:font script="Cher" typeface="Plantagenet Cherokee"/>
<a:font script="Yiii" typeface="Microsoft Yi Baiti"/>
<a:font script="Tibt" typeface="Microsoft Himalaya"/>
<a:font script="Thaa" typeface="MV Boli"/>
<a:font script="Deva" typeface="Mangal"/>
<a:font script="Telu" typeface="Gautami"/>
<a:font script="Taml" typeface="Latha"/>
<a:font script="Syrc" typeface="Estrangelo Edessa"/>
<a:font script="Orya" typeface="Kalinga"/>
<a:font script="Mlym" typeface="Kartika"/>
<a:font script="Laoo" typeface="DokChampa"/>
<a:font script="Sinh" typeface="Iskoola Pota"/>
<a:font script="Mong" typeface="Mongolian Baiti"/>
<a:font script="Viet" typeface="Arial"/>
<a:font script="Uigh" typeface="Microsoft Uighur"/>
</a:minorFont>
</a:fontScheme>
<a:fmtScheme name="Office">
<a:fillStyleLst>
<a:solidFill>
<a:schemeClr val="phClr"/>
</a:solidFill>
<a:gradFill rotWithShape="1">
<a:gsLst>
<a:gs pos="0">
<a:schemeClr val="phClr">
<a:tint val="50000"/>
<a:satMod val="300000"/>
</a:schemeClr>
</a:gs>
<a:gs pos="35000">
<a:schemeClr val="phClr">
<a:tint val="37000"/>
<a:satMod val="300000"/>
</a:schemeClr>
</a:gs>
<a:gs pos="100000">
<a:schemeClr val="phClr">
<a:tint val="15000"/>
<a:satMod val="350000"/>
</a:schemeClr>
</a:gs>
</a:gsLst>
<a:lin ang="16200000" scaled="1"/>
</a:gradFill>
<a:gradFill rotWithShape="1">
<a:gsLst>
<a:gs pos="0">
<a:schemeClr val="phClr">
<a:tint val="100000"/>
<a:shade val="100000"/>
<a:satMod val="130000"/>
</a:schemeClr>
</a:gs>
<a:gs pos="100000">
<a:schemeClr val="phClr">
<a:tint val="50000"/>
<a:shade val="100000"/>
<a:satMod val="350000"/>
</a:schemeClr>
</a:gs>
</a:gsLst>
<a:lin ang="16200000" scaled="0"/>
</a:gradFill>
</a:fillStyleLst>
<a:lnStyleLst>
<a:ln w="9525" cap="flat" cmpd="sng" algn="ctr">
<a:solidFill>
<a:schemeClr val="phClr">
<a:shade val="95000"/>
<a:satMod val="105000"/>
</a:schemeClr>
</a:solidFill>
<a:prstDash val="solid"/>
</a:ln>
<a:ln w="25400" cap="flat" cmpd="sng" algn="ctr">
<a:solidFill>
<a:schemeClr val="phClr"/>
</a:solidFill>
<a:prstDash val="solid"/>
</a:ln>
<a:ln w="38100" cap="flat" cmpd="sng" algn="ctr">
<a:solidFill>
<a:schemeClr val="phClr"/>
</a:solidFill>
<a:prstDash val="solid"/>
</a:ln>
</a:lnStyleLst>
<a:effectStyleLst>
<a:effectStyle>
<a:effectLst>
<a:outerShdw blurRad="40000" dist="20000" dir="5400000" rotWithShape="0">
<a:srgbClr val="000000">
<a:alpha val="38000"/>
</a:srgbClr>
</a:outerShdw>
</a:effectLst>
</a:effectStyle>
<a:effectStyle>
<a:effectLst>
<a:outerShdw blurRad="40000" dist="23000" dir="5400000" rotWithShape="0">
<a:srgbClr val="000000">
<a:alpha val="35000"/>
</a:srgbClr>
</a:outerShdw>
</a:effectLst>
</a:effectStyle>
<a:effectStyle>
<a:effectLst>
<a:outerShdw blurRad="40000" dist="23000" dir="5400000" rotWithShape="0">
<a:srgbClr val="000000">
<a:alpha val="35000"/>
</a:srgbClr>
</a:outerShdw>
</a:effectLst>
<a:scene3d>
<a:camera prst="orthographicFront">
<a:rot lat="0" lon="0" rev="0"/>
</a:camera>
<a:lightRig rig="threePt" dir="t">
<a:rot lat="0" lon="0" rev="1200000"/>
</a:lightRig>
</a:scene3d>
<a:sp3d>
<a:bevelT w="63500" h="25400"/>
</a:sp3d>
</a:effectStyle>
</a:effectStyleLst>
<a:bgFillStyleLst>
<a:solidFill>
<a:schemeClr val="phClr"/>
</a:solidFill>
<a:gradFill rotWithShape="1">
<a:gsLst>
<a:gs pos="0">
<a:schemeClr val="phClr">
<a:tint val="40000"/>
<a:satMod val="350000"/>
</a:schemeClr>
</a:gs>
<a:gs pos="40000">
<a:schemeClr val="phClr">
<a:tint val="45000"/>
<a:shade val="99000"/>
<a:satMod val="350000"/>
</a:schemeClr>
</a:gs>
<a:gs pos="100000">
<a:schemeClr val="phClr">
<a:shade val="20000"/>
<a:satMod val="255000"/>
</a:schemeClr>
</a:gs>
</a:gsLst>
<a:path path="circle">
<a:fillToRect l="50000" t="-80000" r="50000" b="180000"/>
</a:path>
</a:gradFill>
<a:gradFill rotWithShape="1">
<a:gsLst>
<a:gs pos="0">
<a:schemeClr val="phClr">
<a:tint val="80000"/>
<a:satMod val="300000"/>
</a:schemeClr>
</a:gs>
<a:gs pos="100000">
<a:schemeClr val="phClr">
<a:shade val="30000"/>
<a:satMod val="200000"/>
</a:schemeClr>
</a:gs>
</a:gsLst>
<a:path path="circle">
<a:fillToRect l="50000" t="50000" r="50000" b="50000"/>
</a:path>
</a:gradFill>
</a:bgFillStyleLst>
</a:fmtScheme>
</a:themeElements>
<a:objectDefaults>
<a:spDef>
<a:spPr/>
<a:bodyPr/>
<a:lstStyle/>
<a:style>
<a:lnRef idx="1">
<a:schemeClr val="accent1"/>
</a:lnRef>
<a:fillRef idx="3">
<a:schemeClr val="accent1"/>
</a:fillRef>
<a:effectRef idx="2">
<a:schemeClr val="accent1"/>
</a:effectRef>
<a:fontRef idx="minor">
<a:schemeClr val="lt1"/>
</a:fontRef>
</a:style>
</a:spDef>
<a:lnDef>
<a:spPr/>
<a:bodyPr/>
<a:lstStyle/>
<a:style>
<a:lnRef idx="2">
<a:schemeClr val="accent1"/>
</a:lnRef>
<a:fillRef idx="0">
<a:schemeClr val="accent1"/>
</a:fillRef>
<a:effectRef idx="1">
<a:schemeClr val="accent1"/>
</a:effectRef>
<a:fontRef idx="minor">
<a:schemeClr val="tx1"/>
</a:fontRef>
</a:style>
</a:lnDef>
</a:objectDefaults>
<a:extraClrSchemeLst/>
</a:theme>'
      self.parse(default_theme)
    end
  end
end
