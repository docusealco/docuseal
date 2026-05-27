# frozen_string_literal: true

class Pagy
  DEFAULT_DATA_KEYS = %i[url_template first_url previous_url current_url page_url next_url last_url
                         count page limit last in from to previous next options].freeze

  # Generate a hash of the wanted internal data
  def data_hash(data_keys: @options[:data_keys] || DEFAULT_DATA_KEYS, **)
    template = compose_page_url(PAGE_TOKEN, **)
    to_url   = ->(page) { template.sub(PAGE_TOKEN, page.to_s) if page }

    data_keys -= %i[count limit] if calendar?

    data_keys.each_with_object({}) do |key, data|
      value = case key
              when :url_template           then template
              when :first_url              then compose_page_url(nil, **)
              when :previous_url           then to_url.(@previous)
              when :current_url, :page_url then to_url.(@page)
              when :next_url               then to_url.(@next)
              when :last_url               then to_url.(@last)
              else send(key)
              end
      data[key] = value if value
    rescue NoMethodError
      raise OptionError.new(self, :data_keys, 'to contain known keys/methods', key)
    end
  end
end
