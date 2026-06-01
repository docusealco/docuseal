# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Shared

    module TerritoriesContainment

      class << self

        # Returns true if the first territory contains the second one. Returns false otherwise.
        # Raises an ArgumentError exception if one of the territories is invalid.
        def contains?(parent_code, child_code)
          validate_territory(parent_code)
          validate_territory(child_code)

          immediate_children = children(parent_code)

          immediate_children.include?(child_code) ||
            immediate_children.any? { |immediate_child| contains?(immediate_child, child_code) }
        end

        # Returns the immediate parent of the territory with the given code.
        # Raises an ArgumentError exception if the territory code is invalid.
        def parents(territory_code)
          validate_territory(territory_code)

          parents_map[territory_code]
        end

        # Returns the immediate parent of the territory with the given code.
        # Raises an ArgumentError exception if the territory code is invalid.
        def children(territory_code)
          validate_territory(territory_code)

          containment_map[territory_code]
        end

        def containment_map
          @containment_map ||= get_resource.inject(Hash.new { |h, k| h[k] = [] }) do |memo, (territory, children)|
            memo[territory.to_s] = children[:contains].map(&:to_s)
            memo
          end
        end

        protected

        def validate_territory(territory_code)
          raise unknown_territory_exception(territory_code) unless parents_map.include?(territory_code)
        end

        def unknown_territory_exception(territory_code)
          ArgumentError.new("unknown territory code #{territory_code.inspect}")
        end

        def parents_map
          @parents_map ||= containment_map.inject({}) do |memo, (territory, children)|
            # make sure that the top-level territories are explicitly present in the map (with [] as their parent)
            memo[territory] = [] unless memo.include?(territory)

            children.each do |child|
              memo[child] = [] unless memo.include?(child)
              memo[child] << territory # do not override
            end

            memo
          end
        end

        def get_resource
          TwitterCldr.get_resource(:shared, :territories_containment)[:territories]
        end

      end

    end
  end
end

