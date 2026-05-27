module CanCan
  module ModelAdapters
    class Strategies
      class Base
        attr_reader :adapter, :relation, :where_conditions

        delegate(
          :compressed_rules,
          :extract_multiple_conditions,
          :joins,
          :model_class,
          :quoted_primary_key,
          :quoted_aliased_table_name,
          :quoted_table_name,
          to: :adapter
        )
        delegate :connection, :quoted_primary_key, to: :model_class
        delegate :quote_table_name, to: :connection

        def initialize(adapter:, relation:, where_conditions:)
          @adapter = adapter
          @relation = relation
          @where_conditions = where_conditions
        end

        def aliased_table_name
          @aliased_table_name ||= "#{model_class.table_name}_alias"
        end

        def quoted_aliased_table_name
          @quoted_aliased_table_name ||= quote_table_name(aliased_table_name)
        end

        def quoted_table_name
          @quoted_table_name ||= quote_table_name(model_class.table_name)
        end
      end
    end
  end
end
