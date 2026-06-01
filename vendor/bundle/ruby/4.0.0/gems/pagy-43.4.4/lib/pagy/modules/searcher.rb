# frozen_string_literal: true

class Pagy
  # Relegate internal functions. Make overriding search classes easier.
  module Searcher
    module_function

    # Common search logic
    def wrap(search_arguments, options)
      options[:page] ||= options[:request].resolve_page
      options[:limit]  = options[:request].resolve_limit

      pagy, results = yield

      called  = search_arguments[4..]
      results = results.send(*called) unless called.empty?

      [pagy, results]
    end
  end
end
