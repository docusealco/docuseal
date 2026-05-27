# frozen_string_literal: true

class Pagy
  module Search
    class Arguments < Array
      def respond_to_missing?(*) = true

      def method_missing(*) = push(*)
    end

    # Collect the search arguments to pass to the actual search
    def pagy_search(*arguments, **options, &block)
      Arguments.new([self, arguments, options, block])
    end
  end

  # Search classes do not use OFFSET for querying a DB;
  # however, they use the same positional technique used by Offset
  class SearchBase < Offset
    DEFAULT = { search_method: :search }.freeze

    def search? = true
  end

  class ElasticsearchRails < SearchBase; end

  class Meilisearch < SearchBase
    DEFAULT = { search_method: :ms_search }.freeze
  end

  class Searchkick < SearchBase; end

  class TypesenseRails < SearchBase; end
end
