class UserAgent
  module Browsers
    class Webkit < Base
      WEBKIT_PRODUCT_REGEXP = /\AAppleWebKit\z/i
      WEBKIT_VERSION_REGEXP = /\A(?<webkit>AppleWebKit)\/(?<version>[\d\.]+)/i

      def self.extend?(agent)
        agent.detect { |useragent| useragent.product =~ WEBKIT_PRODUCT_REGEXP || useragent.detect_comment { |c| c =~ WEBKIT_VERSION_REGEXP } }
      end

      def browser
        if os =~ /Android/
          'Android'
        elsif platform == 'BlackBerry'
          platform
        else
          'Safari'
        end
      end

      def build
        webkit.version
      end

      BuildVersions = {
        "85.7"     => "1.0",
        "85.8.5"   => "1.0.3",
        "85.8.2"   => "1.0.3",
        "124"      => "1.2",
        "125.2"    => "1.2.2",
        "125.4"    => "1.2.3",
        "125.5.5"  => "1.2.4",
        "125.5.6"  => "1.2.4",
        "125.5.7"  => "1.2.4",
        "312.1.1"  => "1.3",
        "312.1"    => "1.3",
        "312.5"    => "1.3.1",
        "312.5.1"  => "1.3.1",
        "312.5.2"  => "1.3.1",
        "312.8"    => "1.3.2",
        "312.8.1"  => "1.3.2",
        "412"      => "2.0",
        "412.6"    => "2.0",
        "412.6.2"  => "2.0",
        "412.7"    => "2.0.1",
        "416.11"   => "2.0.2",
        "416.12"   => "2.0.2",
        "417.9"    => "2.0.3",
        "418"      => "2.0.3",
        "418.8"    => "2.0.4",
        "418.9"    => "2.0.4",
        "418.9.1"  => "2.0.4",
        "419"      => "2.0.4",
        "425.13"   => "2.2",
        "534.52.7" => "5.1.2"
      }.freeze

      # Prior to Safari 3, the user agent did not include a version number
      def version
        str = if product = detect_product('Version')
          product.version
        elsif os =~ /iOS ([\d\.]+)/ && browser == "Safari"
          $1.tr('_', '.')
        else
          BuildVersions[build.to_s]
        end

        Version.new(str)
      end

      def application
        self.reject { |agent| agent.comment.nil? || agent.comment.empty? }.first
      end

      def platform
        return unless application

        if application.comment[0] =~ /Windows/
          'Windows'
        elsif application.comment[0] == 'BB10'
          'BlackBerry'
        elsif application.comment.any? { |c| c =~ /Android/ }
          'Android'
        else
          application.comment[0]
        end
      end

      def webkit
        if product_match = detect { |useragent| useragent.product =~ WEBKIT_PRODUCT_REGEXP }
          product_match
        elsif comment_match = detect_comment_match(WEBKIT_VERSION_REGEXP)
          UserAgent.new(comment_match[:webkit], comment_match[:version])
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
        elsif (os_string = application.comment.detect { |c| c =~ OperatingSystems::IOS_VERSION_REGEX })
          OperatingSystems.normalize_os(os_string)
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
