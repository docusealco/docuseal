# frozen_string_literal: true

require_relative '../../modules/abilities/countable'

class Pagy
  module CountishPaginator
    module_function

    # Return the Offset::Countish instance and records
    def paginate(collection, options)
      options[:page] ||= options[:request].resolve_page(force_integer: false)

      if options[:page].is_a?(String)
        page, count, epoch = options[:page].split.map(&:to_i)
        options[:page]     = page
      end

      options[:limit] = options[:request].resolve_limit
      setup_options(count, epoch, collection, options)

      pagy = Offset::Countish.new(**options)
      [pagy, pagy.records(collection)]
    end

    # Get the count from the page and set epoch when ttl (Time To Live) requires it
    def setup_options(count, epoch, collection, options)
      now     = Time.now.to_i
      ongoing = !options[:ttl] || (epoch && epoch <= now && now < (epoch + options[:ttl]))

      if !options[:count] && count && ongoing
        options[:count] = count
        options[:epoch] = epoch if options[:ttl]
      else # recount
        options[:count] ||= Countable.get_count(collection, options)
        options[:epoch]   = now if options[:ttl]
      end
    end
  end
end
