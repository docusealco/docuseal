class UserAgent
  module Browsers
    class Gecko < Base
      def self.extend?(agent)
        agent.application && agent.application.product == "Mozilla"
      end

      GeckoBrowsers = %w(
        PaleMoon
        Firefox
        Camino
        Iceweasel
        Seamonkey
      ).freeze

      def browser
        GeckoBrowsers.detect { |browser| respond_to?(browser) } || super
      end

      def version
        v = send(browser).version
        v.nil? ? super : v
      end

      def platform
        if comment = application.comment
          if comment[0] == 'compatible' || comment[0] == 'Mobile'
            nil
          elsif /^Windows / =~ comment[0]
            'Windows'
          else
            comment[0]
          end
        end
      end

      def security
        Security[application.comment[1]] || :strong
      end

      def os
        if comment = application.comment
          i = if comment[1] == 'U'
                2
              elsif /^Windows / =~ comment[0] || /^Android/ =~ comment[0]
                0
              elsif comment[0] == 'Mobile'
                nil
              else
                1
              end

          return nil if i.nil?
          
          OperatingSystems.normalize_os(comment[i])
        end
      end

      def localization
        if comment = application.comment
          comment[3]
        end
      end
    end
  end
end
