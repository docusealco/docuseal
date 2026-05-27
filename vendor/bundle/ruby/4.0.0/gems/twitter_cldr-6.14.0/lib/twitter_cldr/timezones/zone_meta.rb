require 'tzinfo'

module TwitterCldr
  module Timezones
    class Metazone
      attr_reader :id

      def initialize(id)
        @id = id
      end

      def reference_region_code
        properties[:territory]
      end

      def reference_tz_id
        # yes, the naming here doesn't really make sense
        properties[:type]
      end

      private

      def properties
        @properties ||= mapzones.find do |mz|
          mz[:other] == id
        end
      end

      def mapzones
        resource[:mapzones]
      end

      def resource
        @resource ||= TwitterCldr.get_resource(:shared, :metazones)
      end
    end

    class TimezoneMetazone
      attr_reader :tz_id, :mz_id, :from, :to

      def includes?(date)
        ts = date.strftime('%s').to_i
        ts >= from_ts && ts < to_ts
      end

      def metazone
        @metazone ||= Metazone.new(mz_id)
      end

      private

      def initialize(tz_id, mz_id, from, to)
        @tz_id = tz_id
        @mz_id = mz_id
        @from = from
        @to = to
      end

      def from_ts
        @from_ts ||= from ? from.to_i : (Float::INFINITY * -1)
      end

      def to_ts
        @to_ts ||= to ? to.to_i : Float::INFINITY
      end
    end

    class ZoneMeta
      WORLD = '001'.freeze

      class << self
        def normalize(tz_id)
          tz_id = tz_id.to_s.strip
          bcp47_aliases[tz_id.to_sym] || tz_id
        end

        def short_name_for(tz_id)
          bcp47_short_names[tz_id.to_sym]
        end

        def canonical_country_for(tz_id)
          region = region_for_tz(tz_id)
          return nil if region == WORLD
          region
        end

        def region_for_tz(tz_id)
          if region = regions_resource[tz_id.to_sym]
            region[:region]
          end
        end

        def is_primary_region?(region_code, tz_id)
          if region = regions_resource[tz_id.to_sym]
            return region[:primary] && region[:region] == region_code
          end

          false
        end

        def tz_metazones_for(tz_id)
          tz_metazone_map[tz_id.to_sym] || []
        end

        def tz_metazone_for(tz_id, date)
          tz_metazones_for(tz_id).find { |mz| mz.includes?(date) }
        end

        private

        def aliases
          @aliases ||= aliases_resource[:zone].each_with_object({}) do |(_, zones), ret|
            ret.merge!(zones)
          end
        end

        def bcp47_aliases
          @bcp47_aliases ||= bcp47_metadata[:aliases]
        end

        def bcp47_short_names
          @bcp47_short_names ||= bcp47_metadata[:short_names]
        end

        def bcp47_metadata
          @bcp47_metadata ||= TwitterCldr.get_resource(:shared, :bcp47_timezone_metadata)
        end

        def primary_zones
          metazones_resource[:primaryzones]
        end

        def tz_metazone_map
          @tz_metazone_map ||= metazones_resource[:timezones].each_with_object({}) do |(tz_id, metazones), ret|
            ret[tz_id] = metazones.map do |mz|
              TimezoneMetazone.new(tz_id, mz[:metazone], mz[:from], mz[:to])
            end
          end
        end

        def metazones_resource
          @metazones_resource ||= TwitterCldr.get_resource(:shared, :metazones)
        end

        def aliases_resource
          @aliases_resource ||= TwitterCldr.get_resource(:shared, :aliases)[:aliases]
        end

        def regions_resource
          @regions_resource ||= TwitterCldr.get_resource(:shared, :timezone_regions)
        end
      end
    end
  end
end
