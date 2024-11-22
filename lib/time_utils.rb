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

  DEFAULT_DATE_FORMAT_US = 'MM/DD/YYYY'
  DEFAULT_DATE_FORMAT = 'DD/MM/YYYY'

  US_TIMEZONES = %w[EST CST MST PST HST AKDT].freeze

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

  def parse_date_string(string, pattern)
    pattern = pattern.sub(/Y+/, YEAR_FORMATS)
                     .sub(/M+/, MONTH_FORMATS)
                     .sub(/D+/, DAY_FORMATS)

    Date.strptime(string, pattern)
  end

  def format_date_string(string, format, locale)
    date = Date.parse(string.to_s)

    format ||= locale.to_s.ends_with?('US') ? DEFAULT_DATE_FORMAT_US : DEFAULT_DATE_FORMAT

    i18n_format = format.sub(/D+/, DAY_FORMATS[format[/D+/]])
                        .sub(/M+/, MONTH_FORMATS[format[/M+/]])
                        .sub(/Y+/, YEAR_FORMATS[format[/Y+/]])

    I18n.l(date, format: i18n_format, locale:)
  rescue Date::Error
    string
  end
end
