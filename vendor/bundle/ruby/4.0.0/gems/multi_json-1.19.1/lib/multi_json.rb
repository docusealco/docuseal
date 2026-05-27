require_relative "multi_json/options"
require_relative "multi_json/version"
require_relative "multi_json/adapter_error"
require_relative "multi_json/parse_error"
require_relative "multi_json/options_cache"
require_relative "multi_json/adapter_selector"

# A unified interface for JSON libraries in Ruby
#
# MultiJson allows swapping between JSON backends without changing your code.
# It auto-detects available JSON libraries and uses the fastest one available.
#
# @example Basic usage
#   MultiJson.load('{"foo":"bar"}')  #=> {"foo" => "bar"}
#   MultiJson.dump({foo: "bar"})     #=> '{"foo":"bar"}'
#
# @example Specifying an adapter
#   MultiJson.use(:oj)
#   MultiJson.load('{"foo":"bar"}', adapter: :json_gem)
#
# @api public
module MultiJson
  extend Options
  extend AdapterSelector

  # @!visibility private
  module_function

  # @!group Configuration

  # Set default options for both load and dump operations
  #
  # @api private
  # @deprecated Use {.load_options=} and {.dump_options=} instead
  # @param value [Hash] options hash
  # @return [Hash] the options hash
  # @example
  #   MultiJson.default_options = {symbolize_keys: true}
  def default_options=(value)
    Kernel.warn "MultiJson.default_options setter is deprecated\n" \
                "Use MultiJson.load_options and MultiJson.dump_options instead"
    self.load_options = self.dump_options = value
  end

  # Get the default options
  #
  # @api private
  # @deprecated Use {.load_options} or {.dump_options} instead
  # @return [Hash] the current load options
  # @example
  #   MultiJson.default_options  #=> {}
  def default_options
    Kernel.warn "MultiJson.default_options is deprecated\n" \
                "Use MultiJson.load_options or MultiJson.dump_options instead"
    load_options
  end

  # @deprecated These methods are no longer used
  %w[cached_options reset_cached_options!].each do |method_name|
    define_method(method_name) do |*|
      Kernel.warn "MultiJson.#{method_name} method is deprecated and no longer used."
    end
  end

  # Legacy alias for adapter name mappings
  ALIASES = AdapterSelector::ALIASES

  # Maps adapter symbols to their require paths for auto-loading
  REQUIREMENT_MAP = {
    fast_jsonparser: "fast_jsonparser",
    oj: "oj",
    yajl: "yajl",
    jr_jackson: "jrjackson",
    json_gem: "json",
    gson: "gson"
  }.freeze

  class << self
    # Returns the default adapter name (alias for default_adapter)
    #
    # @api public
    # @deprecated Use {.default_adapter} instead
    # @return [Symbol] the default adapter name
    # @example
    #   MultiJson.default_engine  #=> :oj
    alias_method :default_engine, :default_adapter
  end

  # @!endgroup

  # @!group Adapter Management

  # Returns the current adapter class
  #
  # @api private
  # @return [Class] the current adapter class
  # @example
  #   MultiJson.adapter  #=> MultiJson::Adapters::Oj
  def adapter
    @adapter ||= use(nil)
  end

  # Returns the current adapter class (alias for adapter)
  #
  # @api private
  # @deprecated Use {.adapter} instead
  # @return [Class] the current adapter class
  # @example
  #   MultiJson.engine  #=> MultiJson::Adapters::Oj
  alias_method :engine, :adapter

  # Sets the adapter to use for JSON operations
  #
  # @api private
  # @param new_adapter [Symbol, String, Module, nil] adapter specification
  # @return [Class] the loaded adapter class
  # @example
  #   MultiJson.use(:oj)
  def use(new_adapter)
    @adapter = load_adapter(new_adapter)
  ensure
    OptionsCache.reset
  end

  # Sets the adapter to use for JSON operations
  #
  # @api private
  # @return [Class] the loaded adapter class
  # @example
  #   MultiJson.adapter = :json_gem
  alias_method :adapter=, :use

  # Sets the adapter to use for JSON operations
  #
  # @api private
  # @deprecated Use {.adapter=} instead
  # @return [Class] the loaded adapter class
  # @example
  #   MultiJson.engine = :json_gem
  alias_method :engine=, :use
  module_function :adapter=, :engine=

  # @!endgroup

  # @!group JSON Operations

  # Parses a JSON string into a Ruby object
  #
  # @api private
  # @param string [String, #read] JSON string or IO-like object
  # @param options [Hash] parsing options (adapter-specific)
  # @return [Object] parsed Ruby object
  # @raise [ParseError] if parsing fails
  # @example
  #   MultiJson.load('{"foo":"bar"}')  #=> {"foo" => "bar"}
  def load(string, options = {})
    adapter_class = current_adapter(options)
    adapter_class.load(string, options)
  rescue adapter_class::ParseError => e
    raise ParseError.build(e, string)
  end

  # Parses a JSON string into a Ruby object
  #
  # @api private
  # @deprecated Use {.load} instead
  # @return [Object] parsed Ruby object
  # @example
  #   MultiJson.decode('{"foo":"bar"}')  #=> {"foo" => "bar"}
  alias_method :decode, :load
  module_function :decode

  # Returns the adapter to use for the given options
  #
  # @api private
  # @param options [Hash] options that may contain :adapter key
  # @return [Class] adapter class
  # @example
  #   MultiJson.current_adapter(adapter: :oj)  #=> MultiJson::Adapters::Oj
  def current_adapter(options = {})
    options ||= {}
    adapter_override = options[:adapter]
    adapter_override ? load_adapter(adapter_override) : adapter
  end

  # Serializes a Ruby object to a JSON string
  #
  # @api private
  # @param object [Object] object to serialize
  # @param options [Hash] serialization options (adapter-specific)
  # @return [String] JSON string
  # @example
  #   MultiJson.dump({foo: "bar"})  #=> '{"foo":"bar"}'
  def dump(object, options = {})
    current_adapter(options).dump(object, options)
  end

  # Serializes a Ruby object to a JSON string
  #
  # @api private
  # @deprecated Use {.dump} instead
  # @return [String] JSON string
  # @example
  #   MultiJson.encode({foo: "bar"})  #=> '{"foo":"bar"}'
  alias_method :encode, :dump
  module_function :encode

  # Executes a block using the specified adapter
  #
  # @api private
  # @param new_adapter [Symbol, String, Module] adapter to use
  # @yield block to execute with the temporary adapter
  # @return [Object] result of the block
  # @example
  #   MultiJson.with_adapter(:json_gem) { MultiJson.dump({}) }
  def with_adapter(new_adapter)
    previous_adapter = adapter
    self.adapter = new_adapter
    yield
  ensure
    self.adapter = previous_adapter
  end

  # Executes a block using the specified adapter
  #
  # @api private
  # @deprecated Use {.with_adapter} instead
  # @return [Object] result of the block
  # @example
  #   MultiJson.with_engine(:json_gem) { MultiJson.dump({}) }
  alias_method :with_engine, :with_adapter
  module_function :with_engine

  # @!endgroup
end
