# frozen_string_literal: true

module DetectBrowserDevice
  module_function

  MOBILE_USER_AGENT_REGEXP = /
    iPhone         |
    iPod           |
    Android.*Mobile|
    Opera\ Mini    |
    Opera\ Mobi    |
    webOS          |
    IEMobile       |
    Windows\ Phone |
    BlackBerry     |
    BB10           |
    Mobile
  /ix

  TABLET_USER_AGENT_REGEXP = /
    iPad               |
    Android(?!.*Mobile)|
    Tablet             |
    Kindle             |
    PlayBook           |
    Silk
  /ix

  def call(user_agent)
    return if user_agent.blank?

    return 'mobile' if MOBILE_USER_AGENT_REGEXP.match?(user_agent)
    return 'tablet' if TABLET_USER_AGENT_REGEXP.match?(user_agent)

    'desktop'
  end
end
