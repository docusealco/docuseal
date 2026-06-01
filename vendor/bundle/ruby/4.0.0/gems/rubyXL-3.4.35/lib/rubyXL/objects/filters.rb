require 'rubyXL/objects/ooxml_object'
require 'rubyXL/objects/simple_types'
require 'rubyXL/objects/extensions'

module RubyXL
  # http://www.datypic.com/sc/ooxml/e-ssml_dateGroupItem-1.html
  class DateGroupItem < OOXMLObject
    define_attribute(:year,   :int, :required => true)
    define_attribute(:month,  :int)
    define_attribute(:day,    :int)
    define_attribute(:hour,   :int)
    define_attribute(:minute, :int)
    define_attribute(:second, :int)
    define_attribute(:dateTimeGrouping, RubyXL::ST_DateTimeGrouping)
    define_element_name 'dateGroupItem'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_filters-1.html
  class FilterContainer < OOXMLObject
    define_attribute(:blank,        :bool, :default => false)
    define_attribute(:calendarType, RubyXL::ST_CalendarType, :default => 'none')
    define_child_node(RubyXL::StringValue,   :collection => true, :accessor => :filters, :node_name => :filter)
    define_child_node(RubyXL::DateGroupItem, :collection => true, :accessor => :date_group_items)
    define_element_name 'filters'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_top10-1.html
  class Top10 < OOXMLObject
    define_attribute(:top,       :bool,  :default  => true)
    define_attribute(:percent,   :bool,  :default  => false)
    define_attribute(:val,       :double, :required => true)
    define_attribute(:filterVal, :double)
    define_element_name 'top10'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_customFilter-1.html
  class CustomFilter < OOXMLObject
    define_attribute(:operator, RubyXL::ST_FilterOperator, :default => 'equal')
    define_attribute(:val, :string)
    define_element_name 'customFilter'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_customFilters-1.html
  class CustomFilters < OOXMLContainerObject
    define_attribute(:and, :bool, :default => false)
    define_child_node(RubyXL::CustomFilter, :collection => true)
    define_element_name 'customFilters'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_dynamicFilter-1.html
  class DynamicFilter < OOXMLObject
    define_attribute(:type,   RubyXL::ST_DynamicFilterType, :required => true)
    define_attribute(:val,    :double)
    define_attribute(:maxVal, :double)
    define_element_name 'dynamicFilter'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_colorFilter-1.html
  class ColorFilter < OOXMLObject
    define_attribute(:dxfId,     :string)
    define_attribute(:cellColor, :bool)
    define_element_name 'colorFilter'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_iconFilter-1.html
  class IconFilter < OOXMLObject
    define_attribute(:iconSet, RubyXL::ST_IconSetType)
    define_attribute(:iconId,  :int)
    define_element_name 'iconFilter'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_filterColumn-1.html
  class AutoFilterColumn < OOXMLObject
    define_attribute(:colId,        :int,  :required => true)
    define_attribute(:hiddenButton, :bool, :default  => false)
    define_attribute(:showButton,   :bool, :default  => true)
    define_child_node(RubyXL::FilterContainer)
    define_child_node(RubyXL::Top10)
    define_child_node(RubyXL::CustomFilters)
    define_child_node(RubyXL::DynamicFilter)
    define_child_node(RubyXL::ColorFilter)
    define_child_node(RubyXL::IconFilter)
    define_child_node(RubyXL::ExtensionStorageArea)
    define_element_name 'filterColumn'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_sortCondition-1.html
  class SortCondition < OOXMLObject
    define_attribute(:descending, :bool, :default => false)
    define_attribute(:sortBy,     RubyXL::ST_SortBy, :default => 'value')
    define_attribute(:ref,        :ref, :required => true)
    define_attribute(:customList, :string)
    define_attribute(:dxfId,      :int)
    define_attribute(:iconSet,    RubyXL::ST_IconSetType, :required => true, :default => '3Arrows')
    define_attribute(:iconId,     :int)
    define_element_name 'sortCondition'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_sortState-2.html
  class SortState < OOXMLObject
    define_attribute(:columnSort,    :bool,   :default  => false)
    define_attribute(:caseSensitive, :bool,   :default  => false)
    define_attribute(:sortMethod,    RubyXL::ST_SortMethod, :default => 'none')
    define_attribute(:ref,           :ref,    :required => true)
    define_child_node(RubyXL::SortCondition,  :collection => true)
    define_child_node(RubyXL::ExtensionStorageArea)
    define_element_name 'sortState'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_autoFilter-2.html
  class AutoFilter < OOXMLObject
    define_attribute(:ref, :ref)
    define_child_node(RubyXL::AutoFilterColumn)
    define_child_node(RubyXL::SortState)
    define_child_node(RubyXL::ExtensionStorageArea)
    define_element_name 'autoFilter'
  end
end
