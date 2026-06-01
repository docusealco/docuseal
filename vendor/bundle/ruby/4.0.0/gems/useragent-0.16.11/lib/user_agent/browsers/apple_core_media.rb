class UserAgent
  module Browsers
    # CoreMedia is a framework on iOS and is used by various iOS apps to playback media.
    class AppleCoreMedia < Base
      def self.extend?(agent)
        agent.detect { |useragent| useragent.product == 'AppleCoreMedia' }
      end

      def browser
        "AppleCoreMedia"
      end

      def application
        self.reject { |agent| agent.comment.nil? || agent.comment.empty? }.first
      end

      def platform
        return unless application

        if application.comment[0] =~ /Windows/
          'Windows'
        else
          application.comment[0]
        end
      end

      def security
        Security[application.comment[1]]
      end

      def os
        return unless application

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

      def localization
        return unless application

        application.comment[3]
      end
    end
  end
end
