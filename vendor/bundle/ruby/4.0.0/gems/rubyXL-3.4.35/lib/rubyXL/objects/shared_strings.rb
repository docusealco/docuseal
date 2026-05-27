require 'rubyXL/objects/ooxml_object'
require 'rubyXL/objects/text'
require 'rubyXL/objects/extensions'

module RubyXL
  # http://www.datypic.com/sc/ooxml/e-ssml_sst.html
  class SharedStringsTable < OOXMLTopLevelObject
    CONTENT_TYPE = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml'.freeze
    REL_TYPE     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings'.freeze

    # According to http://msdn.microsoft.com/en-us/library/office/gg278314.aspx,
    # +count+ and +uniqueCount+ may be either both missing, or both present. Need to validate.
    define_attribute(:uniqueCount, :int)
    define_child_node(RubyXL::RichText, :collection => :with_count, :node_name => 'si', :accessor => :strings)
    define_child_node(RubyXL::ExtensionStorageArea)
    define_element_name 'sst'
    set_namespaces('http://schemas.openxmlformats.org/spreadsheetml/2006/main' => nil)

    def initialize(*params)
      super
      # So far, going by the structure that the original creator had in mind. However,
      # since the actual implementation is now extracted into a separate class,
      # we will be able to transparently change it later if needs be.
      @index_by_content = {}
    end

    def before_write_xml
      super
      self.unique_count = self.count
      self.count > 0
    end

    def [](index)
      strings[index]
    end

    def empty?
      strings.empty?
    end

    def add(v, index = nil)
      index ||= strings.size

      strings[index] =
        case v
        when RubyXL::RichText then v
        when String then RubyXL::RichText.new(:t => RubyXL::Text.new(:value => v))
        when RubyXL::Text               then RubyXL::RichText.new(:t => v)
        when RubyXL::RichTextRun        then RubyXL::RichText.new(:r => [ v ])
        when RubyXL::PhoneticRun        then RubyXL::RichText.new(:r_ph => [ v ])
        when RubyXL::PhoneticProperties then RubyXL::RichText.new(:phonetic_pr => v)
        end

      @index_by_content[v.to_s] = index
    end

    def get_index(str, add_if_missing = false)
      index = @index_by_content[str]
      index = add(str) if index.nil? && add_if_missing
      index
    end

    def xlsx_path
      ROOT.join('xl', 'sharedStrings.xml')
    end
  end
end
