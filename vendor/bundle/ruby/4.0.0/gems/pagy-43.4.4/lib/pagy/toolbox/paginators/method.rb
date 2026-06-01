# frozen_string_literal: true

require_relative '../../classes/request'

class Pagy
  paginators = { offset:              :OffsetPaginator,
                 countless:           :CountlessPaginator,
                 countish:            :CountishPaginator,
                 keyset:              :KeysetPaginator,
                 keynav_js:           :KeynavJsPaginator,
                 calendar:            :CalendarPaginator,
                 elasticsearch_rails: :ElasticsearchRailsPaginator,
                 meilisearch:         :MeilisearchPaginator,
                 searchkick:          :SearchkickPaginator,
                 typesense_rails:     :TypesenseRailsPaginator }.freeze

  path = Pathname.new(__dir__)
  paginators.each { |symbol, name| autoload name, path.join(symbol.to_s) }

  # Pagy::Method defines the #pagy method to be included in the app controller/view.
  Method = Module.new do
             protected

             define_method :pagy do |paginator = :offset, collection, **options|
               arguments = if paginator == :calendar
                             [self, collection, options]
                           else
                             [collection, options = Pagy::OPTIONS.merge(options)]
                           end

               options[:root_key]  = 'page' if options[:jsonapi] # enforce 'page' root_key for JSON:API
               options[:request] ||= request                     # user set request or self.request
               options[:request]   = Request.new(options)        # Pagy::Request

               Pagy.const_get(paginators[paginator]).paginate(*arguments)
             end
           end
end
