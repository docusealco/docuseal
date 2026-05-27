# frozen_string_literal: true

require_relative '../../modules/searcher'

class Pagy
  module MeilisearchPaginator
    module_function

    # Paginate from the search object
    def paginate(search, options)
      if search.is_a?(Search::Arguments) # Active mode

        Searcher.wrap(search, options) do
          model, arguments, search_options = search

          search_options[:hits_per_page] = options[:limit]
          search_options[:page]          = options[:page]

          method          = options[:search_method] || Meilisearch::DEFAULT[:search_method]
          results         = model.send(method, *arguments, search_options)
          options[:count] = results.raw_answer['totalHits']

          [Meilisearch.new(**options), results]
        end

      else # Passive mode
        options[:limit] = search.raw_answer['hitsPerPage']
        options[:page]  = search.raw_answer['page']
        options[:count] = search.raw_answer['totalHits']

        Meilisearch.new(**options)
      end
    end
  end
end
