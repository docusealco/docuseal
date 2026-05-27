require 'zip'
require 'rubyXL/objects/relationships'
require 'rubyXL/objects/document_properties'
require 'rubyXL/objects/content_types'
require 'rubyXL/objects/workbook'

module RubyXL
  class WorkbookRoot
    @@debug = $DEBUG

    attr_accessor :source_file_path, :content_types, :rels_hash

    include RubyXL::RelationshipSupport

    define_relationship(RubyXL::ThumbnailFile,          :thumbnail)
    define_relationship(RubyXL::CorePropertiesFile,     :core_properties)
    define_relationship(RubyXL::DocumentPropertiesFile, :document_properties)
    define_relationship(RubyXL::CustomPropertiesFile,   :custom_properties)
    define_relationship(RubyXL::Workbook,               :workbook)

    def related_objects
      [ content_types, thumbnail, core_properties, document_properties, custom_properties, workbook ]
    end

    def self.default
      obj = self.new
      obj.document_properties    = RubyXL::DocumentPropertiesFile.new
      obj.core_properties        = RubyXL::CorePropertiesFile.new
      obj.relationship_container = RubyXL::OOXMLRelationshipsFile.new
      obj.content_types          = RubyXL::ContentTypes.new
      obj
    end

    # Write <tt>.xlsx</tt> to a stream (useful for sending over HTTP)
    def stream
      stream = Zip::OutputStream.write_buffer(suppress_extra_fields: true) { |zipstream|
        self.rels_hash = {}
        self.relationship_container.owner = self
        collect_related_objects.compact.each { |obj|
          puts "<-- DEBUG: adding relationship to #{obj.class}" if @@debug
          obj.root = self if obj.respond_to?(:root=)
          self.rels_hash[obj.class] ||= []
          self.rels_hash[obj.class] << obj
        }

        self.rels_hash.keys.sort_by{ |c| c::SAVE_ORDER }.each { |klass|
          puts "<-- DEBUG: saving related #{klass} files" if @@debug
          self.rels_hash[klass].select! { |obj|
            puts "<-- DEBUG:   > #{obj.xlsx_path}" if @@debug
            obj.add_to_zip(zipstream)
          }
        }
      }
      stream.rewind
      stream
    end

    def xlsx_path
      OOXMLTopLevelObject::ROOT
    end

    def self.parse_zip_file(zip_file)
      root = self.new
      root.content_types = RubyXL::ContentTypes.parse_file(zip_file, ContentTypes::XLSX_PATH)
      root.load_relationships(zip_file, OOXMLTopLevelObject::ROOT)

      wb = root.workbook
      wb.root = root

      wb.sheets.each_with_index { |sheet, i|
        sheet_obj = wb.relationship_container.related_files[sheet.r_id]

        wb.worksheets[i] = sheet_obj # Must be done first so the sheet becomes aware of its number
        sheet_obj.workbook = wb

        sheet_obj.sheet_name = sheet.name
        sheet_obj.sheet_id = sheet.sheet_id
        sheet_obj.state = sheet.state
      }

      root
    end
  end
end
