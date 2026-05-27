require 'rubyXL/objects/ooxml_object'
require 'rubyXL/objects/simple_types'
require 'rubyXL/objects/extensions'

# Connections
# https://msdn.microsoft.com/en-us/library/dd908547(v=office.12).aspx
# http://www.datypic.com/sc/ooxml/s-sml-externalConnections.xsd.html

module RubyXL
  # http://www.datypic.com/sc/ooxml/e-ssml_dbPr-1.html
  class OdbcOleDbProperties < OOXMLObject
    define_attribute(:connection,    RubyXL::ST_Xstring, :required => true)
    define_attribute(:command,       RubyXL::ST_Xstring)
    define_attribute(:serverCommand, RubyXL::ST_Xstring)
    define_attribute(:commandType,   :uint, :default => 2)

    define_element_name 'dbPr'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_olapPr-1.html
  class OlapProperties < OOXMLObject
    define_attribute(:local,              :bool, :default => false)
    define_attribute(:localConnection,    RubyXL::ST_Xstring)
    define_attribute(:localRefresh,       :bool, :default => true)
    define_attribute(:sendLocale,         :bool, :default => false)
    define_attribute(:rowDrillCount,      :uint)
    define_attribute(:serverFill,         :bool, :default => true)
    define_attribute(:serverNumberFormat, :bool, :default => true)
    define_attribute(:serverFont,         :bool, :default => true)
    define_attribute(:serverFontColor,    :bool, :default => true)

    define_element_name 'olapPr'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_s-1.html
  # TODO: ssml:m & ssml:x... but how?
  class ConnectionTable < OOXMLObject
    define_attribute(:v, RubyXL::ST_Xstring, :required => true)

    define_element_name 's'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_tables-1.html
  class ConnectionTables < OOXMLObject
    define_child_node(RubyXL::ConnectionTable, :collection => :with_count, :accessor => :tables, :node_name => :table)
    define_element_name 'tables'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_webPr-1.html
  class WebQueryProperties < OOXMLObject
    define_attribute(:xml,         :bool, :default => false)
    define_attribute(:sourceData,  :bool, :default => false)
    define_attribute(:parsePre,    :bool, :default => false)
    define_attribute(:consecutive, :bool, :default => false)
    define_attribute(:firstRow,    :bool, :default => false)
    define_attribute(:xl97,        :bool, :default => false)
    define_attribute(:textDates,   :bool, :default => false)
    define_attribute(:xl2000,      :bool, :default => false)
    define_attribute(:url,         RubyXL::ST_Xstring)
    define_attribute(:post,        RubyXL::ST_Xstring)
    define_attribute(:htmlTables,  :bool, :default => false)
    define_attribute(:htmlFormat,  ssml:ST_HtmlFmt, :default => 'none')
    define_attribute(:editPage,    RubyXL::ST_Xstring)

    define_child_node(RubyXL::ConnectionTables)

    define_element_name 'webPr'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_textField-1.html
  class ConnectionTextField < OOXMLObject
    define_attribute(:type, RubyXL::ST_ExternalConnectionType, :default => 'general')
    define_attribute(:position, :uint, :default => 0)
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_textFields-1.html
  class ConnectionTextFields < OOXMLObject
    define_child_node(RubyXL::ConnectionTextField, :collection => :with_count, :accessor => :text_fields, :node_name => :textField)

    define_element_name 'textFields'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_textPr-1.html
  class TextImportSettings < OOXMLObject
    define_attribute(:prompt, :bool, :default => true)
    define_attribute(:fileType,    RubyXL::ST_FileType, :default => 'win')
    define_attribute(:codePage,    :uint, :default => 1252)
    define_attribute(:firstRow,    :uint, :default => 1)
    define_attribute(:sourceFile,  RubyXL::ST_Xstring, :default => '')
    define_attribute(:delimited,   :bool, :default => true)
    define_attribute(:decimal,     RubyXL::ST_Xstring,  :default => '.')
    define_attribute(:thousands,   RubyXL::ST_Xstring,  :default => ',')
    define_attribute(:tab,         :bool, :default => true)
    define_attribute(:space,       :bool, :default => false)
    define_attribute(:comma,       :bool, :default => false)
    define_attribute(:semicolon,   :bool, :default => false)
    define_attribute(:consecutive, :bool, :default => false)
    define_attribute(:qualifier,   ssml:ST_Qualifier, :default => 'doubleQuote')
    define_attribute(:delimiter,   RubyXL::ST_Xstring)

    define_child_node(RubyXL::ConnectionTextFields)

    define_element_name 'textPr'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_parameter-1.html
  class QueryParameter < OOXMLObject
    define_attribute(:name,            RubyXL::ST_Xstring)
    define_attribute(:sqlType,         :int, :default => 0)
    define_attribute(:parameterType,   RubyXL::ST_ParameterType, :default => 'prompt')
    define_attribute(:refreshOnChange, :bool, :default => false)
    define_attribute(:prompt,          RubyXL::ST_Xstring)
    define_attribute(:boolean,         :bool)
    define_attribute(:double,          :double)
    define_attribute(:integer,         :int)
    define_attribute(:string,          RubyXL::ST_Xstring)
    define_attribute(:cell,            RubyXL::ST_Xstring)
    define_element_name 'parameter'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_parameters-1.html
  class QueryParameters < OOXMLObject
    define_child_node(RubyXL::QueryParameter, :collection => :with_count, :accessor => :parameters, :node_name => :parameter)
    define_element_name 'parameters'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_connection-1.html
  class Connection < OOXMLObject
    define_attribute(:id,                    :uint, :required => true)
    define_attribute(:sourceFile,            RubyXL::ST_Xstring)
    define_attribute(:odcFile,               RubyXL::ST_Xstring)
    define_attribute(:keepAlive,             :bool, :default => false)
    define_attribute(:interval,              :uint, :default => 0)
    define_attribute(:name,                  RubyXL::ST_Xstring)
    define_attribute(:description,           RubyXL::ST_Xstring)
    define_attribute(:type,                  :uint)
    define_attribute(:reconnectionMethod,    :uint, :default => 1)
    define_attribute(:refreshedVersion,      :uint, :required => true)
    define_attribute(:minRefreshableVersion, :uint, :default => 0)
    define_attribute(:savePassword,          :bool, :default => false)
    define_attribute(:new,                   :bool, :default => false)
    define_attribute(:deleted,               :bool, :default => false)
    define_attribute(:onlyUseConnectionFile, :bool, :default => false)
    define_attribute(:background,            :bool, :default => false)
    define_attribute(:refreshOnLoad,         :bool, :default => false)
    define_attribute(:saveData,              :bool, :default => false)
    define_attribute(:credentials,           RubyXL::ST_CredMethod, :default => 'integrated')
    define_attribute(:singleSignOnId,        RubyXL::ST_Xstring)

    define_child_node(RubyXL::OdbcOleDbProperties)
    define_child_node(RubyXL::OlapProperties)
    define_child_node(RubyXL::WebQueryProperties)
    define_child_node(RubyXL::TextImportSettings)
    define_child_node(RubyXL::QueryParameters)
    define_child_node(RubyXL::ExtensionStorageArea)

    define_element_name 'connection'
  end

  # http://www.datypic.com/sc/ooxml/e-ssml_connections.html
  class Connections < OOXMLTopLevelObject
    CONTENT_TYPE = 'application/vnd.openxmlformats-officedocument.spreadsheetml.connections+xml'.freeze
    REL_TYPE     = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/connections'.freeze

    define_child_node(RubyXL::Connection, :collection => true, :accessor => :connections)

    define_element_name 'connections'

    set_namespaces('http://schemas.openxmlformats.org/spreadsheetml/2006/main' => nil)

    def xlsx_path
      ROOT.join('xl', 'connections.xml')
    end
  end
end
