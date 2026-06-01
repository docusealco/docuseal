# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Timezones
    class Iso8601Location < Location
      UTC = 'Z'.freeze

      FIELDS = [
        [:hour].freeze,
        [:hour, :minute].freeze,
        [:hour, :minute, :second].freeze
      ].freeze

      FORMATS = [
        :iso_basic_short,
        :iso_basic_local_short,
        :iso_basic_fixed,
        :iso_basic_local_fixed,
        :iso_basic_full,
        :iso_basic_local_full,
        :iso_extended_fixed,
        :iso_extended_local_fixed,
        :iso_extended_full,
        :iso_extended_local_full
      ].freeze

      def display_name_for(date, fmt, dst = TZInfo::Timezone.default_dst, &block)
        offset = tz.period_for_local(date, dst, &block).offset
        offset_secs = offset.utc_offset + offset.std_offset

        case fmt
          when :iso_basic_short
            format_basic_offset(offset_secs, true, true, true)
          when :iso_basic_local_short
            format_basic_offset(offset_secs, false, true, true)
          when :iso_basic_fixed
            format_basic_offset(offset_secs, true, false, true)
          when :iso_basic_local_fixed
            format_basic_offset(offset_secs, false, false, true)
          when :iso_basic_full
            format_basic_offset(offset_secs, true, false, false)
          when :iso_basic_local_full
            format_basic_offset(offset_secs, false, false, false)
          when :iso_extended_fixed
            format_extended_offset(offset_secs, true, false, true)
          when :iso_extended_local_fixed
            format_extended_offset(offset_secs, false, false, true)
          when :iso_extended_full
            format_extended_offset(offset_secs, true, false, false)
          when :iso_extended_local_full
            format_extended_offset(offset_secs, false, false, false)
        end
      end

      private

      def format_basic_offset(offset, use_utc_indicator, is_short, ignore_seconds)
        format_offset(offset, true, use_utc_indicator, is_short, ignore_seconds)
      end

      def format_extended_offset(offset, use_utc_indicator, is_short, ignore_seconds)
        format_offset(offset, false, use_utc_indicator, is_short, ignore_seconds)
      end

      # This was ported from ICU 64.2, TimeZoneFormat.java, formatOffsetISO8601()
      def format_offset(offset, is_basic, use_utc_indicator, is_short, ignore_seconds)
        abs_offset = offset.abs
        return UTC if use_utc_indicator && abs_offset == 0

        min_fields_idx = is_short ? 0 : 1
        max_fields_idx = ignore_seconds ? 1 : 2
        sep = is_basic ? nil : ':'

        fields = []
        fields << abs_offset / 60 / 60
        fields << (abs_offset / 60) % 60
        fields << abs_offset % 60

        last_idx = max_fields_idx

        while last_idx > min_fields_idx
          if fields[last_idx] != 0
            break
          end

          last_idx -= 1
        end

        buf = ''
        sign = '+'

        if offset < 0
          if 0.upto(last_idx).any? { |i| fields[i] != 0 }
            sign = '-';
          end
        end

        buf << sign

        0.upto(last_idx) do |i|
          buf << sep if sep && i != 0
          buf << '0' if fields[i] < 10
          buf << fields[i].to_s
        end

        buf
      end
    end
  end
end
