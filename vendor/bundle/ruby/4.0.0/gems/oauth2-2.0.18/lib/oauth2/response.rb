# frozen_string_literal: true

require "json"
require "multi_xml"
require "rack"

module OAuth2
  # The Response class handles HTTP responses in the OAuth2 gem, providing methods
  # to access and parse response data in various formats.
  #
  # @since 1.0.0
  class Response
    # Default configuration options for Response instances
    #
    # @return [Hash] The default options hash
    DEFAULT_OPTIONS = {
      parse: :automatic,
      snaky: true,
      snaky_hash_klass: SnakyHash::StringKeyed,
    }.freeze

    # @return [Faraday::Response] The raw Faraday response object
    attr_reader :response

    # @return [Hash] The options hash for this instance
    attr_accessor :options

    # @private
    # Storage for response body parser procedures
    #
    # @return [Hash<Symbol, Proc>] Hash of parser procs keyed by format symbol
    @@parsers = {
      query: ->(body) { Rack::Utils.parse_query(body) },
      text: ->(body) { body },
    }

    # @private
    # Maps content types to parser symbols
    #
    # @return [Hash<String, Symbol>] Hash of content types mapped to parser symbols
    @@content_types = {
      "application/x-www-form-urlencoded" => :query,
      "text/plain" => :text,
    }

    # Adds a new content type parser.
    #
    # @param [Symbol] key A descriptive symbol key such as :json or :query
    # @param [Array<String>, String] mime_types One or more mime types to which this parser applies
    # @yield [String] Block that will be called to parse the response body
    # @yieldparam [String] body The response body to parse
    # @return [void]
    def self.register_parser(key, mime_types, &block)
      key = key.to_sym
      @@parsers[key] = block
      Array(mime_types).each do |mime_type|
        @@content_types[mime_type] = key
      end
    end

    # Initializes a Response instance
    #
    # @param [Faraday::Response] response The Faraday response instance
    # @param [Symbol] parse (:automatic) How to parse the response body
    # @param [Boolean] snaky (true) Whether to convert parsed response to snake_case using SnakyHash
    # @param [Class, nil] snaky_hash_klass (nil) Custom class for snake_case hash conversion
    # @param [Hash] options Additional options for the response
    # @option options [Symbol] :parse (:automatic) Parse strategy (:query, :json, or :automatic)
    # @option options [Boolean] :snaky (true) Enable/disable snake_case conversion
    # @option options [Class] :snaky_hash_klass (SnakyHash::StringKeyed) Class to use for hash conversion
    # @return [OAuth2::Response] The new Response instance
    def initialize(response, parse: :automatic, snaky: true, snaky_hash_klass: nil, **options)
      @response = response
      @options = {
        parse: parse,
        snaky: snaky,
        snaky_hash_klass: snaky_hash_klass,
      }.merge(options)
    end

    # The HTTP response headers
    #
    # @return [Hash] The response headers
    def headers
      response.headers
    end

    # The HTTP response status code
    #
    # @return [Integer] The response status code
    def status
      response.status
    end

    # The HTTP response body
    #
    # @return [String] The response body or empty string if nil
    def body
      response.body || ""
    end

    # The parsed response body
    #
    # @return [Object, SnakyHash::StringKeyed] The parsed response body
    # @return [nil] If no parser is available
    def parsed
      return @parsed if defined?(@parsed)

      @parsed =
        if parser.respond_to?(:call)
          case parser.arity
          when 0
            parser.call
          when 1
            parser.call(body)
          else
            parser.call(body, response)
          end
        end

      if options[:snaky] && @parsed.is_a?(Hash)
        hash_klass = options[:snaky_hash_klass] || DEFAULT_OPTIONS[:snaky_hash_klass]
        @parsed = hash_klass[@parsed]
      end

      @parsed
    end

    # Determines the content type of the response
    #
    # @return [String, nil] The content type or nil if headers are not present
    def content_type
      return unless response.headers

      ((response.headers.values_at("content-type", "Content-Type").compact.first || "").split(";").first || "").strip.downcase
    end

    # Determines the parser to be used for the response body
    #
    # @note The parser can be supplied as the +:parse+ option in the form of a Proc
    #       (or other Object responding to #call) or a Symbol. In the latter case,
    #       the actual parser will be looked up in {@@parsers} by the supplied Symbol.
    #
    # @note If no +:parse+ option is supplied, the lookup Symbol will be determined
    #       by looking up {#content_type} in {@@content_types}.
    #
    # @note If {#parser} is a Proc, it will be called with no arguments, just
    #       {#body}, or {#body} and {#response}, depending on the Proc's arity.
    #
    # @return [Proc, #call] The parser proc or callable object
    # @return [nil] If no suitable parser is found
    def parser
      return @parser if defined?(@parser)

      @parser =
        if options[:parse].respond_to?(:call)
          options[:parse]
        elsif options[:parse]
          @@parsers[options[:parse].to_sym]
        end

      @parser ||= @@parsers[@@content_types[content_type]]
    end
  end
end

# Register XML parser
# @api private
OAuth2::Response.register_parser(:xml, ["text/xml", "application/rss+xml", "application/rdf+xml", "application/atom+xml", "application/xml"]) do |body|
  next body unless body.respond_to?(:to_str)

  MultiXml.parse(body)
end

# Register JSON parser
# @api private
OAuth2::Response.register_parser(:json, ["application/json", "text/javascript", "application/hal+json", "application/vnd.collection+json", "application/vnd.api+json", "application/problem+json"]) do |body|
  next body unless body.respond_to?(:to_str)

  body = body.dup.force_encoding(Encoding::ASCII_8BIT) if body.respond_to?(:force_encoding)
  next body if body.respond_to?(:empty?) && body.empty?

  JSON.parse(body)
end
