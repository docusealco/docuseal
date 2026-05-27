# frozen_string_literal: true

require_relative 'urls_hash'

# Add pagination response headers
class Pagy
  DEFAULT_HEADERS_MAP = { page:  'current-page',
                          limit: 'page-limit',
                          count: 'total-count',
                          pages: 'total-pages' }.freeze

  # Generate a hash of RFC-8288-compliant http headers
  def headers_hash(headers_map: @options[:headers_map] || DEFAULT_HEADERS_MAP, **)
    links = urls_hash(**, absolute: true).map { %(<#{_2}>; rel="#{_1}") }.join(', ')

    headers_map.each_with_object('link' => links) do |(key, name), hash|
      next unless name

      value = case key
              # :nocov:
              when :page  then @page
              when :limit then @limit unless calendar?
              when :pages then @last  if @count
              when :count then @count
                # :nocov:
              end
      hash[name] = value.to_s if value
    end
  end
end
