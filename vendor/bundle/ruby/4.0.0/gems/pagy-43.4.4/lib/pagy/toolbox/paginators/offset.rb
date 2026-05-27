# frozen_string_literal: true

require_relative '../../modules/abilities/countable'

class Pagy
  module OffsetPaginator
    module_function

    # Return the Pagy::Offset instance and results
    def paginate(collection, options)
      options[:page]  ||= options[:request].resolve_page
      options[:limit]   = options[:request].resolve_limit
      options[:count] ||= Countable.get_count(collection, options)

      pagy    = Offset.new(**options)
      records = if collection.instance_of?(Array)
                  collection[pagy.offset, pagy.limit]
                else
                  pagy.records(collection)
                end

      [pagy, records]
    end
  end
end
