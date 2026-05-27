# frozen_string_literal: true

class Pagy
  # Provide the helpers to count a collection
  module Countable
    module_function

    # Get the collection count
    def get_count(collection, options)
      return collection.size if collection.instance_of?(Array)
      return collection.count unless defined?(::ActiveRecord) && collection.is_a?(::ActiveRecord::Relation)

      count = if options[:count_over] && !collection.group_values.empty?
                # COUNT(*) OVER ()
                sql = Arel.star.count.over(Arel::Nodes::Grouping.new([]))
                collection.unscope(:order).pick(sql).to_i
              else
                collection.count(:all)
              end

      count.is_a?(Hash) ? count.size : count
    end
  end
end
