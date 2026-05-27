# frozen_string_literal: true

module CanCan
  module ModelAdapters
    class Strategies
      class JoinedAliasExistsSubquery < Base
        def execute!
          model_class
            .joins(
              "JOIN #{quoted_table_name} AS #{quoted_aliased_table_name} ON " \
              "#{quoted_aliased_table_name}.#{quoted_primary_key} = #{quoted_table_name}.#{quoted_primary_key}"
            )
            .where("EXISTS (#{joined_alias_exists_subquery_inner_query.to_sql})")
        end

        def joined_alias_exists_subquery_inner_query
          model_class
            .unscoped
            .select('1')
            .left_joins(joins)
            .where(*where_conditions)
            .where(
              "#{quoted_table_name}.#{quoted_primary_key} = " \
              "#{quoted_aliased_table_name}.#{quoted_primary_key}"
            )
            .limit(1)
        end
      end
    end
  end
end
