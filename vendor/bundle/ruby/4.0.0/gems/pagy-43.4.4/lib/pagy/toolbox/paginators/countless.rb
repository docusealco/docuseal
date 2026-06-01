# frozen_string_literal: true

class Pagy
  module CountlessPaginator
    module_function

    # Return the Offset::Countless instance and records
    def paginate(collection, options)
      options[:page] ||= options[:request].resolve_page(force_integer: false) # accept nil and strings

      if options[:page].is_a?(String)
        page, last     = options[:page].split.map(&:to_i) # ' ' separator, (encoded as '+' by Countless#compose_page_param)
        options[:page] = page
        options[:last] = last if last&.positive?
      end

      options[:limit] = options[:request].resolve_limit

      pagy = Offset::Countless.new(**options)
      [pagy, pagy.records(collection)]
    end
  end
end
