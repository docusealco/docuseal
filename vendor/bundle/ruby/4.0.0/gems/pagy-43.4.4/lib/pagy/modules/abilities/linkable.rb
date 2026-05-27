# frozen_string_literal: true

require 'uri'

class Pagy
  # Support spaces in placeholder params
  class EscapedValue < String; end

  # Provide the helpers to handle the url and anchor
  module Linkable
    module QueryUtils
      module_function

      # Extracted from Rack::Utils and reformatted for rubocop
      # Allow unescaped Pagy::RawQueryValue
      def build_nested_query(value, prefix = nil)
        case value
        when Array
          value.map { |v| build_nested_query(v, "#{prefix}[]") }.join('&')
        when Hash
          value.map do |k, v|
            build_nested_query(v, prefix ? "#{prefix}[#{k}]" : k)
          end.delete_if(&:empty?).join('&')
        when nil
          escape(prefix)
        else
          raise ArgumentError, 'value must be a Hash' if prefix.nil?

          escaped_value = value.is_a?(EscapedValue) ? value : escape(value)
          "#{escape(prefix)}=#{escaped_value}"
        end
      end

      def escape(str)
        URI.encode_www_form_component(str)
      end
    end

    protected

    # Overridable by classes with composite page param
    def compose_page_param(page) = page

    # Return the URL for the page, relying on the Pagy::Request
    def compose_page_url(page, **options)
      opts      = @options.merge(options)
      params    = @request.params.clone(freeze: false)
      root_key  = opts[:root_key]
      container = if root_key
                    params[root_key] = params[root_key]&.clone(freeze: false) || {}
                  else
                    params
                  end

      { opts[:page_key]  => compose_page_param(page),
        opts[:limit_key] => opts[:client_max_limit] && opts[:limit] }.each do |k, v|
        v ? container[k] = v : container.delete(k)
      end

      opts[:querify]&.(params) # Must modify the params: the returned value is ignored
      fragment = opts[:fragment].to_s.sub(/\A(?=[^#])/, '#') # conditionally prepend '#'

      compose_url(opts[:absolute], opts[:path], params, fragment)
    end

    def compose_url(absolute, path, params, fragment)
      query_string = QueryUtils.build_nested_query(params).sub(/\A(?=.)/, '?') # conditionally prepend '?'
      "#{@request.base_url if absolute}#{path || @request.path}#{query_string}#{fragment}"
    end
  end
end
