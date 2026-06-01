# frozen_string_literal: true

require_relative '../../modules/searcher'

class Pagy
  module SearchkickPaginator
    module_function

    # Paginate from the search object
    def paginate(search, options)
      if search.is_a?(Search::Arguments) # Active mode

        Searcher.wrap(search, options) do
          model, arguments, search_options, block = search

          search_options[:per_page] = options[:limit]
          search_options[:page]     = options[:page]

          method          = options[:search_method] || Searchkick::DEFAULT[:search_method]
          results         = model.send(method, *arguments || '*', **search_options, &block)
          options[:count] = results.total_count

          [Searchkick.new(**options), results]
        end

      else # Passive mode
        options[:limit] = search.respond_to?(:options) ? search.options[:per_page] : search.per_page
        options[:page]  = search.respond_to?(:options) ? search.options[:page]     : search.current_page
        options[:count] = search.total_count

        Searchkick.new(**options)
      end
    end
  end
end
