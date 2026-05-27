# frozen_string_literal: true

require_relative '../../modules/searcher'

class Pagy
  module ElasticsearchRailsPaginator
    module_function

    # Paginate from the search object
    def paginate(search, options)
      if search.is_a?(Search::Arguments)  # Active mode

        Searcher.wrap(search, options) do
          model, arguments, search_options = search

          search_options[:size] = options[:limit]
          search_options[:from] = options[:limit] * ((options[:page] || 1) - 1)

          method          = options[:search_method] || ElasticsearchRails::DEFAULT[:search_method]
          response_object = model.send(method, *arguments, **search_options)
          options[:count] = total_count_from(response_object)

          [ElasticsearchRails.new(**options), response_object]
        end

      else # Passive mode
        from, size      = pagination_params_from(search)
        options[:limit] = size
        options[:page]  = ((from || 0) / options[:limit]) + 1
        options[:count] = total_count_from(search)

        ElasticsearchRails.new(**options)
      end
    end

    # Get from and size params from the response object, supporting different versions of ElasticsearchRails
    def pagination_params_from(response_object)
      definition = response_object.search.definition
      definition = definition.to_hash if definition.respond_to?(:to_hash)
      container  = (definition.is_a?(Hash) && (definition[:body] || definition)) || response_object.search.options
      from       = (container[:from] || container['from']).to_i
      size       = (container[:size] || container['size']).to_i
      size       = 10 if size.zero?

      [from, size]
    end

    # Get the count from the response object, supporting different versions of ElasticsearchRails
    def total_count_from(response_object)
      total = response_object.instance_eval do
                respond_to?(:response) ? response['hits']['total'] : raw_response['hits']['total']
              end

      total.is_a?(Hash) ? total['value'] : total
    end
  end
end
