require 'rubyXL/objects/ooxml_object'
require 'rubyXL/objects/simple_types'

module RubyXL
  # http://www.datypic.com/sc/ooxml/e-ssml_f-1.html
  class Formula < OOXMLObject
    define_attribute(:_,    :string, :accessor => :expression)
    define_attribute(:t,    RubyXL::ST_CellFormulaType, :default => 'normal')
    define_attribute(:aca,  :bool, :default => false)
    define_attribute(:ref,  :ref)
    define_attribute(:dt2D, :bool,   :default => false)
    define_attribute(:dtr,  :bool,   :default => false)
    define_attribute(:del1, :bool,   :default => false)
    define_attribute(:del2, :bool,   :default => false)
    define_attribute(:r1,   :ref)
    define_attribute(:r2,   :ref)
    define_attribute(:ca,   :bool, :default => false)
    define_attribute(:si,   :int)
    define_attribute(:bx,   :bool, :default => false)
    define_element_name 'f'
  end
end
