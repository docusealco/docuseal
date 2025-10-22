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
    return :mobile if mobile?(user_agent)
    return :tablet if tablet?(user_agent)

    :desktop
  end

  def mobile?(user_agent)
    user_agent.to_s =~ MOBILE_USER_AGENT_REGEXP
  end

  def tablet?(user_agent)
    user_agent.to_s =~ TABLET_USER_AGENT_REGEXP
  end
end
