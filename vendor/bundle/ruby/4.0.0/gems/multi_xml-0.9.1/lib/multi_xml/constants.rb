# Shared constants and converter lambdas used across parser backends.
module MultiXML
  # Hash key for storing text content within element hashes
  #
  # @api public
  # @return [String] the key "__content__" used for text content
  # @example Accessing text content
  #   result = MultiXML.parse('<name>John</name>')
  #   result["name"] #=> "John" (simplified, but internally uses __content__)
  TEXT_CONTENT_KEY = "__content__".freeze

  # Maps Ruby class names to XML type attribute values
  #
  # @api public
  # @return [Hash{String => String}] mapping of Ruby class names to XML types
  # @example Check XML type for a Ruby class
  #   RUBY_TYPE_TO_XML["Integer"] #=> "integer"
  RUBY_TYPE_TO_XML = {
    "Symbol" => "symbol",
    "Integer" => "integer",
    "BigDecimal" => "decimal",
    "Float" => "float",
    "TrueClass" => "boolean",
    "FalseClass" => "boolean",
    "Date" => "date",
    "DateTime" => "datetime",
    "Time" => "datetime",
    "Array" => "array",
    "Hash" => "hash"
  }.freeze

  # XML type attributes disallowed by default for security
  #
  # These types are blocked to prevent code execution vulnerabilities.
  #
  # @api public
  # @return [Array<String>] list of disallowed type names
  # @example Check default disallowed types
  #   DISALLOWED_TYPES #=> ["symbol", "yaml"]
  DISALLOWED_TYPES = %w[symbol yaml].freeze

  # Values that represent false in XML boolean attributes
  #
  # @api public
  # @return [Set<String>] values considered false
  # @example Check false values
  #   FALSE_BOOLEAN_VALUES.include?("0") #=> true
  FALSE_BOOLEAN_VALUES = Set.new(%w[0 false]).freeze

  # Supported values for the :namespaces parse option
  #
  # @api public
  # @return [Array<Symbol>] the valid namespace handling modes
  # @example Parse with namespace preservation
  #   MultiXML.parse(xml, namespaces: :preserve)
  NAMESPACE_MODES = %i[strip preserve].freeze

  # Default parsing options
  #
  # @api public
  # @return [Hash] default options for parse method
  # @example View defaults
  #   DEFAULT_OPTIONS[:symbolize_names] #=> false
  DEFAULT_OPTIONS = {
    typecast_xml_value: true,
    disallowed_types: DISALLOWED_TYPES,
    symbolize_names: false,
    namespaces: :strip
  }.freeze

  # Parser libraries in preference order (fastest first)
  #
  # TruffleRuby's JIT favors pure-Ruby parsers and penalizes FFI-bound
  # ones, so rexml jumps to the head of the list (after ox, which is
  # filtered out of auto-detection by ParserResolution#skip_on_platform?)
  # and nokogiri falls to last.
  #
  # @api public
  # @return [Array<Array>] pairs of [require_path, parser_symbol]
  # @example View parser order
  #   PARSER_PREFERENCE.first #=> ["ox", :ox]
  # :nocov:
  PARSER_PREFERENCE = if RUBY_ENGINE == "truffleruby"
    [
      ["ox", :ox],
      ["rexml/document", :rexml],
      ["libxml-ruby", :libxml],
      ["oga", :oga],
      ["nokogiri", :nokogiri]
    ].freeze
  else
    [
      ["ox", :ox],
      ["libxml-ruby", :libxml],
      ["nokogiri", :nokogiri],
      ["oga", :oga],
      ["rexml/document", :rexml]
    ].freeze
  end
  # :nocov:

  # Parses datetime strings, trying Time first then DateTime
  #
  # @api private
  # @return [Proc] lambda that parses datetime strings
  PARSE_DATETIME = lambda do |string|
    Time.parse(string).utc
  rescue ArgumentError
    begin
      DateTime.parse(string).to_time.utc
    rescue ArgumentError, NoMethodError
      MultiXML.send(:parse_iso_week_datetime, string)
    end
  end

  # Regex matching ISO week dates like YYYY-Www or YYYY-Www-d.
  #
  # @api private
  ISO_WEEK_DATE = /\A(?<year>\d{4})-W(?<week>\d{2})(?:-(?<day>\d))?\z/
  private_constant :ISO_WEEK_DATE

  # Parse YYYY-Www[-d] ISO week dates into a UTC Time
  #
  # @api private
  # @param string [String] ISO week date string
  # @return [Time] UTC midnight for the given ISO week date
  # @raise [ArgumentError] if the string is not a supported ISO week date
  def self.parse_iso_week_datetime(string)
    match = ISO_WEEK_DATE.match(string)
    raise ArgumentError, "invalid date" unless match

    date = Date.commercial(Integer(match[:year]), Integer(match[:week]), Integer(match[:day] || "1"))
    Time.utc(date.year, date.month, date.day)
  end
  private_class_method :parse_iso_week_datetime

  # Creates a file-like StringIO from base64-encoded content
  #
  # @api private
  # @return [Proc] lambda that creates file objects
  FILE_CONVERTER = lambda do |content, entity|
    StringIO.new(content.unpack1("m")).tap do |io|
      io.extend(FileLike)
      file_io = io # : FileIO
      file_io.original_filename = entity["name"]
      file_io.content_type = entity["content_type"]
    end
  end

  # Type converters for XML type attributes
  #
  # Maps type attribute values to lambdas that convert string content.
  # Converters with arity 2 receive the content and the full entity hash.
  #
  # @api public
  # @return [Hash{String => Proc}] mapping of type names to converter procs
  # @example Using a converter
  #   TYPE_CONVERTERS["integer"].call("42") #=> 42
  TYPE_CONVERTERS = {
    "symbol" => ->(s) { s.to_sym },
    "string" => :to_s.to_proc,
    "integer" => :to_i.to_proc,
    "float" => :to_f.to_proc,
    "double" => :to_f.to_proc,
    "decimal" => ->(s) { BigDecimal(s) },
    "boolean" => ->(s) { !FALSE_BOOLEAN_VALUES.include?(s.strip) },
    "date" => Date.method(:parse),
    "datetime" => PARSE_DATETIME,
    "dateTime" => PARSE_DATETIME,
    "base64Binary" => ->(s) { s.unpack1("m") },
    "binary" => ->(s, entity) { (entity["encoding"] == "base64") ? s.unpack1("m") : s },
    "file" => FILE_CONVERTER,
    "yaml" => lambda do |string|
      YAML.safe_load(string, permitted_classes: [Symbol, Date, Time])
    rescue ArgumentError, Psych::SyntaxError
      string
    end
  }.freeze
end
