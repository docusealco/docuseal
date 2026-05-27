# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'fileutils'
require 'time'
require 'tzinfo/data'

module TwitterCldr
  module Resources

    class TimezoneTestsImporter < Importer
      TEST_TIME = Time.utc(2019, 11, 17, 0, 0, 0)

      requirement :icu, Versions.icu_version
      output_path File.join(TwitterCldr::SPEC_DIR, 'timezones', 'tests')
      locales TwitterCldr.supported_locales
      ruby_engine :jruby

      TYPES = [
        :LOCALIZED_GMT,
        :LOCALIZED_GMT_SHORT,
        :GENERIC_LOCATION,
        :GENERIC_LONG,
        :GENERIC_SHORT,
        :SPECIFIC_LONG,
        :SPECIFIC_SHORT,
        :ISO_BASIC_SHORT,
        :ISO_BASIC_LOCAL_SHORT,
        :ISO_BASIC_FIXED,
        :ISO_BASIC_LOCAL_FIXED,
        :ISO_BASIC_FULL,
        :ISO_BASIC_LOCAL_FULL,
        :ISO_EXTENDED_FIXED,
        :ISO_EXTENDED_LOCAL_FIXED,
        :ISO_EXTENDED_FULL,
        :ISO_EXTENDED_LOCAL_FULL,
        :ZONE_ID_SHORT,
        :EXEMPLAR_LOCATION
      ]

      def execute
        check_tzdata_versions

        output_path = params.fetch(:output_path)
        FileUtils.mkdir_p(output_path)

        params[:locales].each do |locale|
          output_file = File.join(output_path, "#{locale}.yml")

          File.write(
            output_file, YAML.dump(generate_test_cases_for_locale(locale))
          )
        end
      end

      private

      def check_tzdata_versions
        resource_bundle = requirements[:icu].get_class('com.ibm.icu.util.UResourceBundle')
        icu_data = requirements[:icu].get_class('com.ibm.icu.impl.ICUData')
        zone_info_res_field = requirements[:icu]
          .get_class('com.ibm.icu.impl.OlsonTimeZone')
          .java_class
          .declared_field(:ZONEINFORES)

        zone_info_res_field.accessible = true
        zone_info_res = zone_info_res_field.value(nil)

        bundle = resource_bundle.getBundleInstance(
          icu_data.const_get(:ICU_BASE_NAME), zone_info_res
        )

        icu_tz_version = bundle.get('TZVersion').getString
        tzinfo_version = TZInfo::Data::Version::TZDATA

        if icu_tz_version != tzinfo_version
          raise RuntimeError, 'Timezone database versions do not match. ICU is using '\
            "#{icu_tz_version} and the tzinfo-data gem is using #{tzinfo_version}."
        end
      end

      def generate_test_cases_for_locale(locale)
        ulocale = ulocale_class.new(locale.to_s)

        TZInfo::Timezone.all_identifiers.each_with_object({}) do |tz_id, ret|
          next if tz_id == 'Factory'

          tz = tz_class.getTimeZone(tz_id)
          offset = tz.getRawOffset

          ret[tz_id] = {
            offset: offset,
            **test_cases_for_zone_and_locale(tz, ulocale)
          }
        end
      end

      def test_cases_for_zone_and_locale(tz, locale)
        tz_format = timezone_format_class.getInstance(locale)
        date = TEST_TIME.to_i * 1000

        TYPES.each_with_object({}) do |style_sym, ret|
          style_const = style.const_get(style_sym)
          ret[style_sym] = tz_format.format(style_const, tz, date)
        end
      end

      def tz_class
        @tz_class ||= requirements[:icu].get_class('com.ibm.icu.util.TimeZone')
      end

      def ulocale_class
        @ulocale_class ||= requirements[:icu].get_class('com.ibm.icu.util.ULocale')
      end

      def timezone_format_class
        @timezone_format ||= requirements[:icu].get_class('com.ibm.icu.text.TimeZoneFormat')
      end

      def style
        @style ||= timezone_format_class.const_get(:Style)
      end
    end

  end
end
