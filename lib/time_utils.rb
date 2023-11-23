# frozen_string_literal: true

module TimeUtils
  module_function

  def timezone_abbr(timezone, time = Time.current)
    tz_info = TZInfo::Timezone.get(
      ActiveSupport::TimeZone::MAPPING[timezone] || timezone || 'UTC'
    )

    tz_info.abbreviation(time)
  end
end
