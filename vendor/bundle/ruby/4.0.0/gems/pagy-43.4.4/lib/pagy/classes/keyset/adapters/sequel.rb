# frozen_string_literal: true

class Pagy
  class Keyset
    module Adapters
      # Keyset adapter for sequel
      module Sequel
        # Extract the keyset from the set
        def extract_keyset
          return {} unless @set.opts[:order]

          @set.opts[:order].each_with_object({}) do |item, keyset|
            case item
            when Symbol
              keyset[item] ||= :asc
            when ::Sequel::SQL::OrderedExpression
              keyset[item.expression] ||= (item.descending ? :desc : :asc)
            else
              raise TypeError, "#{item.class.inspect} is not a supported Sequel::SQL::OrderedExpression"
            end
          end
        end

        # Get the keyset attributes from a record
        def keyset_attributes_from(record)
          record.to_hash.slice(*@keyset.keys)
        end

        # Get the hash of quoted keyset identifiers
        def quoted_identifiers(table)
          db = @set.db
          @keyset.to_h { |column| [column, "#{db.quote_identifier(table)}.#{db.quote_identifier(column)}"] }
        end

        # Typecast the attributes
        def typecast(attributes)
          model = @set.model
          db    = @set.db
          {}.tap do |result|
            @keyset.each_key do |k|
              type      = model.db_schema[k].fetch(:type)
              result[k] = db.typecast_value(type, attributes[k])
            end
          end
        end

        # Append the missing keyset keys, if the set is restricted by select
        def ensure_select
          return if @set.opts[:select].nil?

          selected = @set.opts[:select]
          @set = @set.select_append(*@keyset.keys.reject { |c| selected.include?(c) })
        end

        # Apply the where predicate to the set
        def apply_where(predicate, arguments)
          @set = @set.where(::Sequel.lit(predicate, **arguments))
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
