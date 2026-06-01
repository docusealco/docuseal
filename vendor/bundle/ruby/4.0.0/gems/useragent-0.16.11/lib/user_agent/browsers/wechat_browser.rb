class UserAgent
  module Browsers
    class WechatBrowser < Base
      def self.extend?(agent)
        agent.detect { |useragent| useragent.product =~ /MicroMessenger/i }
      end

      def browser
        'Wechat Browser'
      end

      def version
        micro_messenger = detect_product("MicroMessenger")
        Version.new(micro_messenger.version)
      end

      def platform
        return unless application && application.comment

        if application.comment[0] =~ /iPhone/
          'iPhone'
        elsif application.comment.any? { |c| c =~ /Android/ }
          'Android'
        else
          application.comment[0]
        end
      end

      def os
        return unless application && application.comment

        if application.comment[0] =~ /Windows NT/
          OperatingSystems.normalize_os(application.comment[0])
        elsif application.comment[2].nil?
          OperatingSystems.normalize_os(application.comment[1])
        elsif application.comment[1] =~ /Android/
          OperatingSystems.normalize_os(application.comment[1])
        else
          OperatingSystems.normalize_os(application.comment[2])
        end
      end
    end
  end
end
