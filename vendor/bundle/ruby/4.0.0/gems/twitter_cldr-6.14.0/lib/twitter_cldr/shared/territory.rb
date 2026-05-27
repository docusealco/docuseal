# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Shared

    class Territory
      attr_reader :code

      def initialize(territory_code)
        @code = territory_code
      end

      def contains?(territory_code)
        TerritoriesContainment.contains?(code, territory_code)
      end

      def parents
        TerritoriesContainment.parents(code)
      end

      def children
        TerritoriesContainment.children(code)
      end

    end
  end
end

