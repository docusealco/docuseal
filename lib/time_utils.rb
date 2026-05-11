# frozen_string_literal: true

module TimeUtils
  MONTH_FORMATS = {
    'M' => '%-m',
    'MM' => '%m',
    'MMM' => '%b',
    'MMMM' => '%B'
  }.freeze

  DAY_FORMATS = {
    'D' => '%-d',
    'DD' => '%d'
  }.freeze

  YEAR_FORMATS = {
    'YYYY' => '%Y',
    'YYY' => '%Y',
    'YY' => '%y'
  }.freeze

  HOUR_FORMATS = {
    'H' => '%-H',
    'HH' => '%H',
    'h' => '%-I',
    'hh' => '%I'
  }.freeze

  MINUTE_FORMATS = {
    'm' => '%-M',
    'mm' => '%M'
  }.freeze

  SECOND_FORMATS = {
    's' => '%-S',
    'ss' => '%S'
  }.freeze

  AMPM_FORMATS = {
    'A' => '%p',
    'a' => '%P'
  }.freeze

  TIMEZONE_FORMATS = {
    'z' => '%Z'
  }.freeze

  TIME_FORMATS = HOUR_FORMATS.merge(MINUTE_FORMATS)
                             .merge(SECOND_FORMATS)
                             .merge(AMPM_FORMATS)
                             .freeze

  ALL_FORMATS = MONTH_FORMATS.merge(DAY_FORMATS)
                             .merge(YEAR_FORMATS)
                             .merge(TIME_FORMATS)
                             .merge(TIMEZONE_FORMATS)
                             .freeze

  TOKEN_REGEX = /MMMM|MMM|MM|M|DD|D|YYYY|YYY|YY|HH|hh|H|h|mm|m|ss|s|A|a|z/

  MONTH_ONLY_VALUE_REGEX = /\A\d{4}-\d{2}\z/

  DEFAULT_DATE_FORMAT_US = 'MM/DD/YYYY'
  DEFAULT_DATE_FORMAT = 'DD/MM/YYYY'

  US_TIMEZONES = %w[EST EDT CST CDT MST MDT PST PDT HST HDT AKST AKDT].freeze

  module_function

  def timezone_abbr(timezone, time = Time.current)
    tz_info = TZInfo::Timezone.get(
      ActiveSupport::TimeZone::MAPPING[timezone] || timezone || 'UTC'
    )

    tz_info.abbreviation(time)
  end

  def parse_time_value(value)
    if value.is_a?(Integer)
      Time.zone.at(value.to_s.first(10).to_i)
    elsif value.present?
      Time.zone.parse(value)
    end
  end

  def format_with_time?(format)
    format.to_s.match?(/[HhAasz]/)
  end

  def month_only_format?(format)
    format.to_s.present? && !format.to_s.match?(/[DdHhAasz]/)
  end

  def format_date_preview(format, locale, timezone)
    format = format.upcase if format && !format_with_time?(format)
    format = format.presence || (locale.to_s.ends_with?('US') ? DEFAULT_DATE_FORMAT_US : DEFAULT_DATE_FORMAT)

    preview_pattern = format.gsub(TOKEN_REGEX) { |token| TIME_FORMATS.key?(token) ? '--' : ALL_FORMATS[token] }

    I18n.l(Time.current.in_time_zone(timezone.presence || Time.zone.name), format: preview_pattern, locale:)
  end

  def current_date_value(format, timezone)
    tz = timezone.presence || Time.zone.name

    if format_with_time?(format)
      Time.current.utc.iso8601
    elsif month_only_format?(format)
      Time.current.in_time_zone(tz).strftime('%Y-%m')
    else
      Time.current.in_time_zone(tz).to_date.to_s
    end
  end

  def parse_date_string(string, pattern)
    with_time = format_with_time?(pattern)
    pattern = pattern.upcase unless with_time
    pattern = pattern.gsub(TOKEN_REGEX, ALL_FORMATS)

    with_time ? Time.zone.strptime(string, pattern) : Date.strptime(string, pattern)
  end

  def format_date_string(string, format, locale, timezone: nil)
    format = format.upcase if format && !format_with_time?(format)
    format = format.presence || (locale.to_s.ends_with?('US') ? DEFAULT_DATE_FORMAT_US : DEFAULT_DATE_FORMAT)

    date =
      if format_with_time?(format)
        Time.iso8601(string.to_s).in_time_zone(timezone.presence || Time.zone.name)
      elsif string.to_s.match?(MONTH_ONLY_VALUE_REGEX)
        year, month = string.to_s.split('-').map(&:to_i)

        Date.new(year, month, 1)
      else
        Date.parse(string.to_s)
      end

    I18n.l(date, format: format.gsub(TOKEN_REGEX, ALL_FORMATS), locale:)
  rescue ArgumentError
    string
  end
end
