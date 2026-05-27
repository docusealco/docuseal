class UserAgent
  module Browsers
    # The user agent for iTunes
    # 
    # Some user agents:
    # iTunes/10.6.1 (Macintosh; Intel Mac OS X 10.7.3) AppleWebKit/534.53.11
    # iTunes/12.0.1 (Macintosh; OS X 10.10) AppleWebKit/0600.1.25
    # iTunes/11.1.5 (Windows; Microsoft Windows 7 x64 Business Edition Service Pack 1 (Build 7601)) AppleWebKit/537.60.15
    # iTunes/12.0.1 (Windows; Microsoft Windows 8 x64 Home Premium Edition (Build 9200)) AppleWebKit/7600.1017.0.24
    # iTunes/12.0.1 (Macintosh; OS X 10.10.1) AppleWebKit/0600.1.25 
    class ITunes < Webkit
      def self.extend?(agent)
        agent.detect { |useragent| useragent.product == "iTunes" }
      end

      # @return ["iTunes"] Always return iTunes as the browser
      def browser
        "iTunes"
      end

      # @return [Version] The version of iTunes in use
      def version
        self.iTunes.version
      end

      # @return [nil] nil - not included in the user agent
      def security
        nil
      end

      # @return [nil, Version] The WebKit version in use if we have it
      def build
        super if webkit
      end

      # Parses the operating system in use.
      # 
      # @return [String] The operating system
      def os
        full_os = self.full_os

        if application && application.comment[0] =~ /Windows/
          if full_os =~ /Windows 8\.1/
            "Windows 8.1"
          elsif full_os =~ /Windows 8/
            "Windows 8"
          elsif full_os =~ /Windows 7/
            "Windows 7"
          elsif full_os =~ /Windows Vista/
            "Windows Vista"
          elsif full_os =~ /Windows XP/
            "Windows XP"
          else
            "Windows"
          end
        else
          super
        end
      end

      # Parses the operating system in use.
      # 
      # @return [String] The operating system
      def full_os
        if application && application.comment && application.comment.length > 1
          full_os = application.comment[1]

          full_os = "#{full_os})" if full_os =~ /\(Build [0-9][0-9][0-9][0-9]\z/ # The regex chops the ) off :(

          full_os
        end
      end
    end
  end
end
