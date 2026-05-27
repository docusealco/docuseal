require 'rubyXL/objects/ooxml_object'
require 'rubyXL/objects/simple_types'
require 'rubyXL/objects/formula'

module RubyXL
  # http://www.datypic.com/sc/ooxml/e-ssml_dataValidation-1.html
  class DataValidation < OOXMLObject
    define_attribute(:type,             RubyXL::ST_DataValidationType,       :default => 'none')
    define_attribute(:errorStyle,       RubyXL::ST_DataValidationErrorStyle, :default => 'stop')
    define_attribute(:imeMode,          RubyXL::ST_DataValidationImeMode,    :default => 'noControl')
    define_attribute(:operator,         RubyXL::ST_DataValidationOperator,   :default => 'between')
    define_attribute(:allowBlank,       :bool, :default => false)
    # Documentation lies. This property should have been called "HIDE dropdown",
    #   since that's what happens when it is set to true.
    define_attribute(:showDropDown,     :bool, :default => false)
    define_attribute(:showInputMessage, :bool, :default => false)
    define_attribute(:showErrorMessage, :bool, :default => false)
    define_attribute(:errorTitle,       :string)
    define_attribute(:error,            :string)
    define_attribute(:promptTitle,      :string)
    define_attribute(:prompt,           :string)
    define_attribute(:sqref,            :sqref, :required => true)

    define_child_node(RubyXL::Formula, :node_name => :formula1)
    define_child_node(RubyXL::Formula, :node_name => :formula2)
    define_element_name 'dataValidation'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_dataValidations-1.html
  class DataValidations < OOXMLContainerObject
    define_attribute(:disablePrompts, :bool, :default => false)
    define_attribute(:xWindow,        :int)
    define_attribute(:yWindow,        :int)
    define_child_node(RubyXL::DataValidation, :collection => :with_count)
    define_element_name 'dataValidations'
  end
end
