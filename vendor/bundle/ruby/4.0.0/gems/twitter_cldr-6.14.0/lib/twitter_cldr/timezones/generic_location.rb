# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Timezones
    class GenericLocation < Location
      DEFAULT_CITY_EXCLUSION_PATTERN = /Etc\/.*|SystemV\/.*|.*\/Riyadh8[7-9]/
      DST_CHECK_RANGE = 184 * 24 * 60 * 60
      UNKNOWN_DEFAULT = 'Unknown'.freeze
      FORMATS = [
        :generic_location,
        :generic_short,
        :generic_long,
        :specific_short,
        :specific_long,
        :exemplar_location
      ].freeze

      Territories = TwitterCldr::Shared::Territories
      Utils = TwitterCldr::Utils

      def display_name_for(date, fmt = :generic_location, dst = TZInfo::Timezone.default_dst, &block)
        case fmt
          when :generic_location
            generic_location_display_name
          when :generic_short
            generic_short_display_name(date, dst, &block) || generic_location_display_name
          when :generic_long
            generic_long_display_name(date, dst, &block) || generic_location_display_name
          when :specific_short
            specific_short_display_name(date, dst, &block)
          when :specific_long
            specific_long_display_name(date, dst, &block)
          when :exemplar_location
            exemplar_city
          else
            raise ArgumentError, "'#{fmt}' is not a valid generic timezone format, "\
              "must be one of #{FORMATS.join(', ')}"
        end
      end

      private

      def generic_location_display_name
        if region_code = ZoneMeta.canonical_country_for(tz.identifier)
          if ZoneMeta.is_primary_region?(region_code, tz_id)
            region_name = Territories.from_territory_code_for_locale(region_code, tz.locale)
            return region_formats[:generic].sub('{0}', region_name || region_code)
          else
            # From ICU source, TimeZoneGenericNames.java, getGenericLocationName():
            #
            # exemplar location should return non-empty String
            # if the time zone is associated with a location
            return region_formats[:generic].sub('{0}', exemplar_city || region_code)
          end
        end
      end

      def generic_short_display_name(date, dst = TZInfo::Timezone.default_dst, &block)
        format_display_name(date, :generic, :short, dst, &block)
      end

      def generic_long_display_name(date, dst = TZInfo::Timezone.default_dst, &block)
        format_display_name(date, :generic, :long, dst, &block)
      end

      def specific_short_display_name(date, dst = TZInfo::Timezone.default_dst, &block)
        format_display_name(date, :specific, :short, dst, &block)
      end

      def specific_long_display_name(date, dst = TZInfo::Timezone.default_dst, &block)
        format_display_name(date, :specific, :long, dst, &block)
      end

      # From ICU source, TimeZoneGenericNames.java, formatGenericNonLocationName():
      #
      # 1. If a generic non-location string is available for the zone, return it.
      # 2. If a generic non-location string is associated with a meta zone and
      #    the zone never use daylight time around the given date, use the standard
      #    string (if available).
      # 3. If a generic non-location string is associated with a meta zone and
      #    the offset at the given time is different from the preferred zone for the
      #    current locale, then return the generic partial location string (if available)
      # 4. If a generic non-location string is not available, use generic location
      #    string.
      #
      def format_display_name(date, type, fmt, dst = TZInfo::Timezone.default_dst, &block)
        date_int = date.strftime('%s').to_i
        period = tz.period_for_local(date, dst, &block)

        flavor = if type == :generic
          :generic
        elsif type == :specific
          period.std_offset > 0 ? :daylight : :standard
        end

        if explicit = (timezone_data[fmt] || {})[flavor]
          return explicit
        end

        if tz_metazone = ZoneMeta.tz_metazone_for(tz_id, date)
          if use_standard?(date_int, period)
            std_name = tz_name_for(fmt, :standard) || mz_name_for(fmt, :standard, tz_metazone.mz_id)
            mz_generic_name = mz_name_for(fmt, :generic, tz_metazone.mz_id)

            # From ICU source, TimeZoneGenericNames.java, formatGenericNonLocationName():
            #
            # In CLDR, the same display name is used for both generic and standard
            # for some meta zones in some locales. This looks like data bugs. For
            # now, we check if the standard name is different from its generic name.
            return std_name if std_name && std_name != mz_generic_name
          end

          mz_name = mz_name_for(fmt, flavor, tz_metazone.mz_id)

          # don't go through all the golden zone logic if we're not computing the
          # generic format
          return mz_name if type == :specific

          golden_zone_id = tz_metazone.metazone.reference_tz_id

          if golden_zone_id != tz_id
            golden_zone = TZInfo::Timezone.get(golden_zone_id)
            golden_period = golden_zone.period_for_local(date)

            if period.utc_offset != golden_period.utc_offset || period.std_offset != golden_period.std_offset
              return nil unless mz_name
              return partial_location_name_for(tz_metazone.metazone, mz_name)
            else
              return mz_name
            end
          else
            return mz_name
          end
        end
      end

      def partial_location_name_for(metazone, mz_name)
        region_code = ZoneMeta.canonical_country_for(tz_id)

        location = if region_code
          if region_code == metazone.reference_region_code
            Territories.from_territory_code_for_locale(region_code)
          else
            exemplar_city
          end
        else
          exemplar_city ? exemplar_city : tz_id
        end

        fallback_formats[:generic]
          .sub('{0}', location)
          .sub('{1}', mz_name || '')
      end

      def target_region_code
        @target_region_code ||= tz.orig_locale.region || tz.max_locale.region
      end

      def exemplar_city
        @exemplar_city ||=
          timezone_data[:city] ||
          default_exemplar_city ||
          unknown_city ||
          UNKNOWN_DEFAULT
      end

      def tz_name_for(fmt, flavor)
        Utils.traverse_hash(timezone_data[:timezones], [tz_id.to_sym, fmt, flavor])
      end

      def mz_name_for(fmt, flavor, mz_id)
        Utils.traverse_hash(metazone_data, [mz_id.to_sym, fmt, flavor])
      end

      def use_standard?(date_int, transition_offset)
        prev_trans = tz.transitions_up_to(Time.at(date_int - DST_CHECK_RANGE)).last
        next_trans = tz.transitions_up_to(Time.at(date_int + DST_CHECK_RANGE)).last

        return false if transition_offset.std_offset != 0
        return false if prev_trans && prev_trans.offset.std_offset != 0
        return false if next_trans && next_trans.offset.std_offset != 0

        true
      end

      def default_exemplar_city
        @default_exemplar_city ||= begin
          return nil if tz_id =~ DEFAULT_CITY_EXCLUSION_PATTERN

          sep = tz_id.rindex('/')

          if sep && sep + 1 < tz_id.length
            return tz_id[(sep + 1)..-1].gsub('_', ' ')
          end

          nil
        end
      end

      def unknown_city
        @unknown_city ||= resource[:timezones][:'Etc/Unknown'][:city]
      end

      def timezone_data
        @timezone_data ||= (resource[:timezones][tz_id.to_sym] || {})
      end

      def metazone_data
        @metazone_data ||= resource[:metazones]
      end

      def region_formats
        @region_format ||= resource[:formats][:region_formats]
      end

      def fallback_formats
        @fallback_formats ||= resource[:formats][:fallback_formats]
      end
    end
  end
end
