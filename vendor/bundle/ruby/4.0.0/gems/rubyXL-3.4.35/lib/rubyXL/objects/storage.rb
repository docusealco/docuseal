module RubyXL
  class GenericStorageObject
    SAVE_ORDER = 0

    attr_accessor :xlsx_path, :data, :generic_storage

    def initialize(file_path, data)
      @xlsx_path = file_path
      @data = data
      @generic_storage = []
    end

    def self.parse_file(zip_file, file_path)
      (entry = zip_file.find_entry(RubyXL::from_root(file_path))) && self.new(file_path, entry.get_input_stream(&:read))
    end

    def add_to_zip(zip_stream)
      return false if @data.nil?
      zip_stream.put_next_entry(RubyXL::from_root(self.xlsx_path))
      zip_stream.write(@data)
      true
    end
  end

  class PrinterSettingsFile < GenericStorageObject
    CONTENT_TYPE = 'application/vnd.openxmlformats-officedocument.spreadsheetml.printerSettings'.freeze
    REL_TYPE     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/printerSettings'.freeze
  end

  class CustomPropertyFile < GenericStorageObject
    CONTENT_TYPE = 'application/vnd.openxmlformats-officedocument.spreadsheetml.customProperty'.freeze
    REL_TYPE     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/customProperty'.freeze
  end

  class DrawingFile < GenericStorageObject
    CONTENT_TYPE = 'application/vnd.openxmlformats-officedocument.drawing+xml'.freeze
    REL_TYPE     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/drawing'.freeze

    include RubyXL::RelationshipSupport

    def attach_relationship(rid, rf)
      case rf
      when RubyXL::ChartFile       then store_relationship(rf) # TODO
      when RubyXL::BinaryImageFile then store_relationship(rf) # TODO
      else store_relationship(rf, :unknown)
      end
    end
  end

  class ChartFile < GenericStorageObject
    CONTENT_TYPE = 'application/vnd.openxmlformats-officedocument.drawingml.chart+xml'.freeze
    REL_TYPE     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/chart'.freeze

    include RubyXL::RelationshipSupport

    def attach_relationship(rid, rf)
      case rf
      when RubyXL::ChartColorsFile     then store_relationship(rf) # TODO
      when RubyXL::ChartStyleFile      then store_relationship(rf) # TODO
      when RubyXL::ChartUserShapesFile then store_relationship(rf) # TODO
      else store_relationship(rf, :unknown)
      end
    end
  end

  class BinaryImageFile < GenericStorageObject
    CONTENT_TYPE = 'image/jpeg'.freeze
    REL_TYPE     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/image'.freeze
  end

  class VMLDrawingFile < GenericStorageObject
    CONTENT_TYPE = 'application/vnd.openxmlformats-officedocument.vmlDrawing'.freeze
#    CONTENT_TYPE = 'application/vnd.openxmlformats-officedocument.drawingml.chart+xml'.freeze
    REL_TYPE = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/vmlDrawing'.freeze

    include RubyXL::RelationshipSupport

    define_relationship(RubyXL::BinaryImageFile)
  end

  class ChartColorsFile < GenericStorageObject
    CONTENT_TYPE = 'application/vnd.ms-office.chartcolorstyle+xml'.freeze
    REL_TYPE     = 'http://schemas.microsoft.com/office/2011/relationships/chartColorStyle'.freeze
  end

  class ChartStyleFile < GenericStorageObject
    CONTENT_TYPE = 'application/vnd.ms-office.chartstyle+xml'.freeze
    REL_TYPE     = 'http://schemas.microsoft.com/office/2011/relationships/chartStyle'.freeze
  end

  class TableFile < GenericStorageObject
    CONTENT_TYPE = 'application/vnd.openxmlformats-officedocument.spreadsheetml.table+xml'.freeze
    REL_TYPE     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/table'.freeze
  end

  class ControlPropertiesFile < GenericStorageObject
    CONTENT_TYPE = 'application/vnd.ms-excel.controlproperties+xml'.freeze
    REL_TYPE     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/ctrlProp'.freeze
  end

  class PivotCacheRecordsFile < GenericStorageObject
    CONTENT_TYPE = 'application/vnd.openxmlformats-officedocument.spreadsheetml.pivotCacheRecords+xml'.freeze
    REL_TYPE     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/pivotCacheRecords'.freeze
  end

  class PivotCacheDefinitionFile < GenericStorageObject
    CONTENT_TYPE = 'application/vnd.openxmlformats-officedocument.spreadsheetml.pivotCacheDefinition+xml'.freeze
    REL_TYPE     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/pivotCacheDefinition'.freeze

    include RubyXL::RelationshipSupport

    define_relationship(RubyXL::PivotCacheRecordsFile)
  end

  class PivotTableFile < GenericStorageObject
    CONTENT_TYPE = 'application/vnd.openxmlformats-officedocument.spreadsheetml.pivotTable+xml'.freeze
    REL_TYPE     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/pivotTable'.freeze

    include RubyXL::RelationshipSupport

    define_relationship(RubyXL::PivotCacheDefinitionFile)
  end

  class HyperlinkRelFile < GenericStorageObject
    REL_TYPE     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink'.freeze
  end

  class ThumbnailFile < GenericStorageObject
    REL_TYPE     = 'http://schemas.openxmlformats.org/package/2006/relationships/metadata/thumbnail'.freeze
    CONTENT_TYPE = 'image/x-wmf'.freeze
  end

  class ChartUserShapesFile < GenericStorageObject
    CONTENT_TYPE = 'application/vnd.openxmlformats-officedocument.drawingml.chartshapes+xml'.freeze
    REL_TYPE     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/chartUserShapes'.freeze
  end

  class CustomPropertiesFile < GenericStorageObject
    CONTENT_TYPE = 'application/vnd.openxmlformats-officedocument.custom-properties+xml'.freeze
    REL_TYPE     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/custom-properties'.freeze
  end

  class MacrosFile < GenericStorageObject
    CONTENT_TYPE = 'application/vnd.ms-office.vbaProject'.freeze
    REL_TYPE     = 'http://schemas.microsoft.com/office/2006/relationships/vbaProject'.freeze
  end

  class CustomXMLFile < GenericStorageObject
    REL_TYPE     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/customXml'.freeze
  end

  class SlicerFile < GenericStorageObject
    CONTENT_TYPE = 'application/vnd.ms-excel.slicer+xml'.freeze
    REL_TYPE     = 'http://schemas.microsoft.com/office/2007/relationships/slicer'.freeze
  end

  class SlicerCacheFile < GenericStorageObject
    CONTENT_TYPE = 'application/vnd.ms-excel.slicerCache+xml'.freeze
    REL_TYPE     = 'http://schemas.microsoft.com/office/2007/relationships/slicerCache'.freeze
  end

  class OLEObjectFile < GenericStorageObject
    CONTENT_TYPE = 'application/vnd.openxmlformats-officedocument.oleObject'.freeze
    REL_TYPE     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/oleObject'.freeze
  end

  class SheetMetadata < GenericStorageObject
    CONTENT_TYPE = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheetMetadata+xml'.freeze
    REL_TYPE     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/sheetMetadata'.freeze
  end

  class PersonMetadata < GenericStorageObject
    CONTENT_TYPE = 'application/vnd.ms-excel.person+xml'.freeze
    REL_TYPE     = 'http://schemas.microsoft.com/office/2017/10/relationships/person'.freeze
  end

  class ActiveX < GenericStorageObject
    REL_TYPE     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/control'.freeze

    include RubyXL::RelationshipSupport

    def attach_relationship(rid, rf)
      case rf
      when RubyXL::ChartFile then store_relationship(rf) # TODO
      else store_relationship(rf, :unknown)
      end
    end
  end

  class ActiveXBinary < GenericStorageObject
    REL_TYPE = 'http://schemas.microsoft.com/office/2006/relationships/activeXControlBinary'.freeze
  end
end
