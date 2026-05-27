require 'rubyXL/objects/ooxml_object'

module RubyXL
  class ContentTypeDefault < OOXMLObject
    define_attribute(:Extension,   :string)
    define_attribute(:ContentType, :string)
    define_element_name 'Default'
  end

  class ContentTypeOverride < OOXMLObject
    define_attribute(:PartName, :string)
    define_attribute(:ContentType, :string)
    define_element_name 'Override'
  end

  class ContentTypes < OOXMLTopLevelObject
    SAVE_ORDER = 999  # Must be saved last, so it has time to accumulate overrides from all others.
    XLSX_PATH = ROOT.join('[Content_Types].xml')

    define_child_node(RubyXL::ContentTypeDefault,  :collection => true, :accessor => :defaults)
    define_child_node(RubyXL::ContentTypeOverride, :collection => true, :accessor => :overrides)

    set_namespaces('http://schemas.openxmlformats.org/package/2006/content-types' => nil)
    define_element_name 'Types'

    def xlsx_path
      XLSX_PATH
    end

    def before_write_xml
      content_types_by_ext = {}

      # Collect all extensions and corresponding content types
      root.rels_hash.each_pair { |klass, objects|
        objects.each { |obj|
          next unless klass.const_defined?(:CONTENT_TYPE)
          ext = obj.xlsx_path.extname[1..-1]
          next if ext.nil?
          content_types_by_ext[ext] ||= []
          content_types_by_ext[ext] << klass::CONTENT_TYPE
        }
      }

      self.defaults = [ RubyXL::ContentTypeDefault.new(:extension => 'xml', :content_type => 'application/xml') ]

      # Determine which content types are used most often, and add them to the list of defaults
      content_types_by_ext.each_pair { |ext, content_types_arr|
        next if ext.nil? || defaults.any? { |d| d.extension == ext }
        most_frequent_ct = content_types_arr.group_by { |ct| ct }.values.max_by(&:size).first
        defaults << RubyXL::ContentTypeDefault.new(:extension => ext, :content_type => most_frequent_ct)
      }

      self.overrides = []

      # Add overrides for the files with known extensions but different content types.
      root.rels_hash.each_pair { |klass, objects|
        objects.each { |obj|
          obj_content_type = case
                             when obj.respond_to?(:content_type) then obj.content_type
                             when defined?(klass::CONTENT_TYPE)  then klass::CONTENT_TYPE
                             else next
                             end

          ext = obj.xlsx_path.extname[1..-1]
          next if defaults.any? { |d| (d.extension == ext) && (d.content_type == obj_content_type) }
          overrides << RubyXL::ContentTypeOverride.new(:part_name    => obj.xlsx_path,
                                                       :content_type => obj_content_type)
        }
      }

      true
    end
  end
end
