# frozen_string_literal: true

class Pagy
  class Keyset
    module Adapters
      # Keyset adapter for ActiveRecord
      module ActiveRecord
        # Extract the keyset from the set
        def extract_keyset
          @set.order_values.each_with_object({}) do |node, keyset|
            keyset[node.value.name.to_sym] ||= node.direction
          end
        end

        # Get the keyset attributes from a record
        def keyset_attributes_from(record)
          record.slice(*@keyset.keys)
        end

        # Get the hash of quoted keyset identifiers
        def quoted_identifiers(table)
          connection = @set.connection
          @keyset.to_h { |column| [column, "#{connection.quote_table_name(table)}.#{connection.quote_column_name(column)}"] }
        end

        # Typecast the attributes
        def typecast(attributes)
          model = @set.model
          {}.tap do |result|
            @keyset.each_key do |k|
              result[k] = model.type_for_attribute(k).cast(attributes[k])
            end
          end
        end

        # Append the missing keyset keys, if the set is restricted by select
        def ensure_select
          return if @set.select_values.empty?

          @set = @set.select(*@keyset.keys)
        end

        # Apply the where predicate to the set
        def apply_where(predicate, arguments)
          @set = @set.where(predicate, **arguments)
        end

        def self.included(including)
          instance_methods(false).each do |method_name|
            including.send(:protected, method_name)
          end
        end
      end
    end
  end
end
