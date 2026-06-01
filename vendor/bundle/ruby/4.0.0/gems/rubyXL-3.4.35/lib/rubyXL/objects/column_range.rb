require 'rubyXL/objects/ooxml_object'

module RubyXL
  # http://www.datypic.com/sc/ooxml/e-ssml_col-1.html
  class ColumnRange < OOXMLObject
    define_attribute(:min,          :uint, :required => true)
    define_attribute(:max,          :uint, :required => true)
    define_attribute(:width,        :double)
    define_attribute(:style,        :uint, :default => 0, :accessor => :style_index)
    define_attribute(:hidden,       :bool, :default => false)
    define_attribute(:bestFit,      :bool, :default => false)
    define_attribute(:customWidth,  :bool, :default => false)
    define_attribute(:phonetic,     :bool, :default => false)
    define_attribute(:outlineLevel, :int,  :default => 0)
    define_attribute(:collapsed,    :bool, :default => false)
    define_element_name 'col'

    def delete_column(col_index)
      col = col_index + 1
      self.min -= 1 if min >= col
      self.max -= 1 if max >= col
    end

    def insert_column(col_index)
      col = col_index + 1
      self.min += 1 if min >= col
      self.max += 1 if max >= col - 1
    end

    def include?(col_index)
      ((min - 1)..(max - 1)).include?(col_index)
    end

    def self.chars2raw(width_in_chars)
      ((width_in_chars + (5.0 / RubyXL::Font::MAX_DIGIT_WIDTH)) * 256).to_i / 256.0
    end

    DEFAULT_WIDTH = 8
  end

  class ColumnRanges < OOXMLContainerObject
    define_child_node(RubyXL::ColumnRange, :collection => true)

    define_element_name 'cols'

    # Locate an existing column range, make a new one if not found,
    # or split existing column range into multiples.
    def get_range(col_index)
      col_num = col_index + 1

      old_range = self.locate_range(col_index)

      if old_range.nil? then
        new_range = RubyXL::ColumnRange.new(width: RubyXL::ColumnRange.chars2raw(RubyXL::ColumnRange::DEFAULT_WIDTH))
      else
        if old_range.min == col_num && old_range.max == col_num then
          return old_range # Single column range, OK to change in place
        elsif old_range.min == col_num then
          new_range = old_range.dup
          old_range.min += 1
        elsif old_range.max == col_num then
          new_range = old_range.dup
          old_range.max -= 1
        else
          prior_range = old_range.dup
          prior_range.max = col_index # col_num - 1
          self << prior_range

          old_range.min = col_num + 1

          new_range = RubyXL::ColumnRange.new
        end
      end

      new_range.min = new_range.max = col_num
      self << new_range
      return new_range
    end

    def locate_range(col_index)
      self.find { |range| range.include?(col_index) }
    end

    def insert_column(col_index)
      self.each { |range| range.insert_column(col_index) }
    end

    def before_write_xml
      self.sort_by!(&:min)
      !self.empty?
    end
  end
end
