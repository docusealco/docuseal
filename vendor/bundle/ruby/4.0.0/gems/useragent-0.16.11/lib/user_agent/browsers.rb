require 'user_agent/browsers/base'
require 'user_agent/browsers/chrome'
require 'user_agent/browsers/edge'
require 'user_agent/browsers/gecko'
require 'user_agent/browsers/internet_explorer'
require 'user_agent/browsers/opera'
require 'user_agent/browsers/webkit'
require 'user_agent/browsers/wechat_browser'
require 'user_agent/browsers/windows_media_player'
require 'user_agent/browsers/itunes'
require 'user_agent/browsers/apple_core_media'
require 'user_agent/browsers/libavformat'
require 'user_agent/browsers/playstation'
require 'user_agent/browsers/podcast_addict'
require 'user_agent/browsers/vivaldi'

class UserAgent
  module Browsers
    Security = {
      "N" => :none,
      "U" => :strong,
      "I" => :weak
    }.freeze

    ALL = [
      Edge,
      InternetExplorer,
      Opera,
      WechatBrowser,
      Vivaldi,
      Chrome,
      ITunes,
      PlayStation,
      PodcastAddict,
      Webkit,
      Gecko,
      WindowsMediaPlayer,
      AppleCoreMedia,
      Libavformat,
    ].freeze

    def self.all
      ALL
    end

    def self.extend(array)
      all.each do |extension|
        return extension.new(array) if extension.extend?(array)
      end
      array
    end
  end
end
