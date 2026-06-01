# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Timezones
    class GmtLocation < Location
      FORMATS = [:long_gmt, :short_gmt].freeze
      DEFAULT_FORMAT = :long_gmt
      DEFAULT_GMT_ZERO_FORMAT = 'GMT'.freeze

      def display_name_for(date, format = DEFAULT_FORMAT, dst = TZInfo::Timezone.default_dst, &block)
        offset = tz.period_for_local(date, dst, &block).offset
        offset_secs = offset.utc_offset + offset.std_offset
        return gmt_zero_format if offset_secs == 0

        gmt_format.sub('{0}', format_offset(offset_secs, format))
      end

      private

      def format_offset(offset_secs, format)
        positive = offset_secs >= 0
        offset_secs = offset_secs.abs
        offset_hour ||= offset_secs / 60 / 60
        offset_min ||= (offset_secs / 60) % 60
        offset_sec ||= offset_secs % 60

        tokens = hour_format(positive ? :positive : :negative)
        format_tokens(tokens, format, offset_hour, offset_min, offset_sec)
      end

      def format_tokens(tokens, format, hour, min, sec)
        ''.tap do |result|
          tokens.each do |token|
            case token.type
              when :plaintext
                result << token.value
              when :pattern
                case token.value[0]
                  when 'H'
                    result << offset_digits(hour, format == :short_gmt ? 1 : 2)
                    break if min == 0 && sec == 0 && format == :short_gmt
                  when 'm'
                    result << offset_digits(min, 2)
                    break if sec == 0 && format == :short_gmt
                  when 's'
                    result << offset_digits(sec, 2)
                end
            end
          end
        end
      end

      def offset_digits(n, min_digits)
        number_system.transliterate(n.to_s.rjust(min_digits, '0'))
      end

      def number_system
        @number_system ||= TwitterCldr::Shared::NumberingSystem.for_locale(tz.locale)
      end

      def hour_format(type)
        case type
          when :positive
            hour_formats.first
          else
            hour_formats.last
        end
      end

      def hour_formats
        @hour_formats ||= resource[:formats][:hour_formats][:generic]
          .split(';')
          .map do |pat|
            TwitterCldr::Tokenizers::TimeTokenizer.tokenizer.tokenize(pat)
          end
      end

      def gmt_zero_format
        @gmt_zero_format ||= resource[:formats][:gmt_zero_formats][:generic] ||
          DEFAULT_GMT_ZERO_FORMAT
      end

      def gmt_format
        @gmt_format ||= resource[:formats][:gmt_formats][:generic]
      end
    end
  end
end
