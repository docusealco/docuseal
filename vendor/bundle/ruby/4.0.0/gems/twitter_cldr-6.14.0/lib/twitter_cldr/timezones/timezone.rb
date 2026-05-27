# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'singleton'

module TwitterCldr
  module Timezones
    class Timezone
      include Singleton

      ALL_FORMATS = (
        GenericLocation::FORMATS +
        GmtLocation::FORMATS +
        Iso8601Location::FORMATS +
        [:zone_id, :zone_id_short]
      ).freeze

      GENERIC_TO_GMT_MAP = {
        generic_location: :long_gmt,
        generic_short:    :short_gmt,
        generic_long:     :long_gmt,
        specific_short:   :short_gmt,
        specific_long:    :long_gmt
      }.freeze

      UNKNOWN = 'unk'.freeze

      class << self
        def instance(tz_id, locale = TwitterCldr.locale)
          cache["#{tz_id}:#{locale}"] ||= new(tz_id, locale)
        end

        private

        def cache
          @cache ||= {}
        end
      end

      attr_reader :orig_tz, :tz, :locale

      def initialize(tz_id, locale)
        @orig_tz = TZInfo::Timezone.get(tz_id)
        @tz = TZInfo::Timezone.get(ZoneMeta.normalize(tz_id))
        @locale = locale
      end

      def display_name_for(date, format = :generic_location, dst = TZInfo::Timezone.default_dst, &block)
        case format
          when *GenericLocation::FORMATS
            generic_location.display_name_for(date, format, dst, &block) ||
              gmt_location.display_name_for(date, GENERIC_TO_GMT_MAP[format], dst, &block)

          when *GmtLocation::FORMATS
            gmt_location.display_name_for(date, format, dst, &block)

          when *Iso8601Location::FORMATS
            iso_location.display_name_for(date, format, dst, &block)

          when :zone_id
            identifier

          when :zone_id_short
            ZoneMeta.short_name_for(identifier) || UNKNOWN

          else
            raise ArgumentError, "'#{format}' is not a valid timezone format, "\
              "must be one of #{ALL_FORMATS.join(', ')}"
        end
      end

      def identifier
        tz.identifier
      end

      def period_for_local(*args, &block)
        tz.period_for_local(*args, &block)
      end

      def period_for_utc(time)
        tz.period_for_utc(time)
      end

      def transitions_up_to(date)
        tz.transitions_up_to(date)
      end

      def orig_locale
        @orig_locale ||= TwitterCldr::Shared::Locale.new(locale)
      end

      def max_locale
        @max_locale ||= orig_locale.maximize
      end

      def generic_location
        @generic_location ||= GenericLocation.new(self)
      end

      def gmt_location
        @gmt_location ||= GmtLocation.new(self)
      end

      def iso_location
        @iso_location ||= Iso8601Location.new(self)
      end
    end
  end
end
