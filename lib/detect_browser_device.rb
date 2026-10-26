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

  WINDOWS_USER_AGENT_REGEXP = /
    Windows|
    Win64  |
    Win32  |
    WOW64
  /ix

  ANDROID_USER_AGENT_REGEXP = /
    Android|
    Silk   |
    Kindle
  /ix

  IOS_USER_AGENT_REGEXP = /
    iPhone|
    iPad  |
    iPod  |
    iOS
  /ix

  MACOS_USER_AGENT_REGEXP = /
    Macintosh   |
    Mac\ OS\ X  |
    MacIntel
  /ix

  LINUX_USER_AGENT_REGEXP = /
    Linux  |
    X11    |
    CrOS   |
    Ubuntu |
    Fedora |
    FreeBSD|
    OpenBSD|
    NetBSD
  /ix

  SDK_USER_AGENT_REGEXP = /\ADocuSeal (?<sdk>Ruby|Python|PHP|Java|C#|JS|Go|CLI) v/i

  def call(user_agent)
    return if user_agent.blank?

    return 'mobile' if MOBILE_USER_AGENT_REGEXP.match?(user_agent)
    return 'tablet' if TABLET_USER_AGENT_REGEXP.match?(user_agent)

    'desktop'
  end

  def os(user_agent)
    return if user_agent.blank?

    sdk = user_agent[SDK_USER_AGENT_REGEXP, :sdk]

    return sdk.downcase if sdk

    case user_agent
    when WINDOWS_USER_AGENT_REGEXP then 'windows'
    when ANDROID_USER_AGENT_REGEXP then 'android'
    when IOS_USER_AGENT_REGEXP then 'ios'
    when MACOS_USER_AGENT_REGEXP then 'macos'
    when LINUX_USER_AGENT_REGEXP then 'linux'
    else 'other'
    end
  end
end
