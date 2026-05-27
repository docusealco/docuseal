module CanCan
  module ModelAdapters
    class Strategies
      class LeftJoin < Base
        def execute!
          relation.left_joins(joins).distinct
        end
      end
    end
  end
end
