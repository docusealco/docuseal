require "bigdecimal"
require "date"
require "stringio"
require "time"
require "yaml"
require_relative "multi_xml/concurrency"
require_relative "multi_xml/constants"
require_relative "multi_xml/errors"
require_relative "multi_xml/file_like"
require_relative "multi_xml/helpers"
require_relative "multi_xml/options"
require_relative "multi_xml/options_normalization"
require_relative "multi_xml/parser"
require_relative "multi_xml/parser_resolution"
require_relative "multi_xml/parse_support"

# A generic swappable back-end for parsing XML
#
# MultiXML provides a unified interface for XML parsing across different
# parser libraries. It automatically selects the best available parser
# (Ox, LibXML, Nokogiri, Oga, or REXML) and converts XML to Ruby hashes.
#
# @api public
# @example Parse XML
#   MultiXML.parse('<root><name>John</name></root>')
#   #=> {"root"=>{"name"=>"John"}}
#
# @example Set the parser
#   MultiXML.parser = :nokogiri
module MultiXML
  extend Options

  # Tracks which deprecation warnings have already been emitted so each
  # one fires at most once per process. Stored as a Set rather than a
  # Hash so presence checks have unambiguous semantics for mutation tests.
  DEPRECATION_WARNINGS_SHOWN = Set.new
  private_constant :DEPRECATION_WARNINGS_SHOWN

  # Emit a deprecation warning at most once per process for the given key
  #
  # The warning is tagged with the :deprecated category so callers can
  # silence the whole set with Warning[:deprecated] = false or surface
  # it via ruby -W:deprecated — the standard Ruby idiom for library
  # deprecations since 2.7.
  #
  # @api private
  # @param key [Symbol] identifier for the deprecation (typically the method name)
  # @param message [String] warning message to emit on first call
  # @return [void]
  def self.warn_deprecation_once(key, message)
    Concurrency.synchronize(:deprecation_warnings) do
      return if DEPRECATION_WARNINGS_SHOWN.include?(key)

      Kernel.warn(message, category: :deprecated)
      DEPRECATION_WARNINGS_SHOWN.add(key)
    end
  end

  class << self
    include Helpers
    include ParserResolution
    include ParseSupport

    # Get the current XML parser module
    #
    # Returns the currently configured parser, auto-detecting one if not set.
    # Parsers are checked in order of performance: Ox, LibXML, Nokogiri, Oga, REXML.
    #
    # @api public
    # @return [Module] the current parser module
    # Honors a fiber-local override set by {.with_parser} so concurrent
    # blocks observe their own parser without clobbering the process-wide
    # default. Falls back to the process default when no override is set.
    #
    # @example Get current parser
    #   MultiXML.parser #=> MultiXML::Parsers::Ox
    def parser
      override = Fiber[:multi_xml_parser]
      return override if override

      @parser ||= resolve_parser(detect_parser)
    end

    # Set the XML parser to use
    #
    # @api public
    # @param new_parser [Symbol, String, Module] Parser specification
    #   - Symbol/String: :libxml, :nokogiri, :ox, :rexml, :oga
    #   - Module: Custom parser implementing parse(io) or
    #             parse(io, namespaces: ...) and parse_error
    # @return [Module] the newly configured parser module
    # @example Set parser by symbol
    #   MultiXML.parser = :nokogiri
    # @example Set parser by module
    #   MultiXML.parser = MyCustomParser
    def parser=(new_parser)
      @parser = resolve_parser(new_parser)
    end

    # Parse XML into a Ruby Hash
    #
    # @api public
    # @param xml [String, IO] XML content as a string or IO-like object
    # @param options [Hash] Parsing options
    # @option options [Symbol, String, Module] :parser Parser to use for this call
    # @option options [Boolean] :symbolize_names Convert keys to symbols (default: false)
    # @option options [Array<String>] :disallowed_types Types to reject (default: ['yaml', 'symbol'])
    # @option options [Boolean] :typecast_xml_value Apply type conversions (default: true)
    # @option options [Symbol] :namespaces Namespace handling mode (:strip or :preserve)
    # @return [Hash] Parsed XML as nested hash
    # @raise [ParseError] if XML is malformed
    # @raise [DisallowedTypeError] if XML contains a disallowed type attribute
    # @example Parse simple XML
    #   MultiXML.parse('<root><name>John</name></root>')
    #   #=> {"root"=>{"name"=>"John"}}
    # @example Parse with symbolized names
    #   MultiXML.parse('<root><name>John</name></root>', symbolize_names: true)
    #   #=> {root: {name: "John"}}
    def parse(xml, options = {})
      call_site = OptionsNormalization.normalize_symbolize_option(options)
      global = OptionsNormalization.normalize_symbolize_option(parse_options(call_site))
      options = DEFAULT_OPTIONS.merge(global, call_site)
      namespaces = validate_namespaces_mode(options.fetch(:namespaces))
      io = normalize_input(xml)
      return {} if io.eof?

      result = parse_with_error_handling(io, xml, resolve_parse_parser(options), namespaces)
      apply_postprocessing(result, options)
    end
  end

  # Execute a block with a temporarily-swapped parser
  #
  # The override is stored in fiber-local storage so concurrent fibers
  # and threads each see their own parser without racing on a shared
  # module variable; nested calls save and restore the previous
  # fiber-local value. Matches {MultiJSON.with_adapter}.
  #
  # @api public
  # @param new_parser [Symbol, String, Module] parser to use
  # @yield block to execute with the temporary parser
  # @return [Object] result of the block
  # @example
  #   MultiXML.with_parser(:rexml) { MultiXML.parse("<a>1</a>") }
  def self.with_parser(new_parser)
    previous_override = Fiber[:multi_xml_parser]
    Fiber[:multi_xml_parser] = resolve_parser(new_parser)
    yield
  ensure
    Fiber[:multi_xml_parser] = previous_override
  end
end

require_relative "multi_xml/deprecated"

# Backward-compatible alias for the legacy MultiXml constant name
#
# Downstream code that still writes MultiXml.parse(...) or
# rescue MultiXml::ParseError continues to work, but emits a one-time
# deprecation warning pointing at MultiXML. Each public method on
# {MultiXML} gets an explicit forwarder defined on this module, and
# constant access resolves via {.const_missing}, so both dotted calls
# and :: constant lookups (including rescue clauses) route through
# the canonical module.
#
# @api public
# @deprecated Use {MultiXML} (all-caps) instead. Will be removed in v1.0.
module MultiXml
  # Forward every public method MultiXML exposes through an explicit
  # singleton method on the legacy MultiXml module, so callers that
  # capture the method as a Method object (``MultiXml.method(:load)``)
  # find this forwarder instead of falling back to inherited methods like
  # ``Kernel#load``. The earlier ``method_missing``-based shim left
  # ``MultiXml.method(:load)`` resolving to ``Kernel#load`` (because
  # ``Module#method`` doesn't consult ``method_missing``) so a captured
  # ``MultiXml.method(:load)`` would interpret the XML payload as a file
  # path and crash with ``LoadError``. Forwarding eagerly fixes the
  # capture path while preserving the one-time deprecation warning each
  # call emits.
  (::MultiXML.public_methods - ::Module.public_methods).each do |forwarded|
    define_singleton_method(forwarded) do |*args, **kwargs, &block|
      ::MultiXML.warn_deprecation_once(:multi_xml_constant,
        "The MultiXml constant is deprecated and will be removed in v1.0. Use MultiXML instead.")
      ::MultiXML.public_send(forwarded, *args, **kwargs, &block)
    end
  end

  class << self
    # Resolve missing constants to their {MultiXML} counterparts
    #
    # The lookup is performed with ``inherit: false`` so a stray
    # top-level ``::ParseError`` constant in the host process (Racc
    # defines one when Nokogiri is loaded) is correctly ignored. Enables
    # rescue MultiXml::ParseError and MultiXml::Parsers::Ox to keep
    # working during the deprecation cycle.
    #
    # @api public
    # @param name [Symbol] constant name
    # @return [Object] the resolved constant from {MultiXML}
    # @example
    #   MultiXml::Parsers::Ox  # returns MultiXML::Parsers::Ox
    def const_missing(name)
      ::MultiXML.warn_deprecation_once(:multi_xml_constant,
        "The MultiXml constant is deprecated and will be removed in v1.0. Use MultiXML instead.")
      ::MultiXML.const_get(name, false)
    end
  end
end
