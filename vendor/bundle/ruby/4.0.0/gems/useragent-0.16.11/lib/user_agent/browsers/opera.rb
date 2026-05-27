class UserAgent
  module Browsers
    class Opera < Base
      def self.extend?(agent)
        (agent.first && agent.first.product == 'Opera') ||
          (agent.application && agent.application.product == 'Opera') ||
            (agent.last && agent.last.product == 'OPR')
      end

      def browser
        'Opera'
      end

      def version
        if mini?
          Version.new(application.comment.detect{|c| c =~ /Opera Mini/}[/Opera Mini\/([\d\.]+)/, 1]) rescue Version.new
        elsif product = detect_product('Version')
          Version.new(product.version)
        elsif product = detect_product('OPR')
          Version.new(product.version)
        else
          super
        end
      end

      def platform
        return unless application.comment

        if application.comment[0] =~ /Windows/
          "Windows"
        else
          application.comment[0]
        end
      end

      def security
        if application.comment.nil?
          :strong
        elsif macintosh?
          Security[application.comment[2]]
        elsif mini?
          Security[application.comment[-2]]
        else
          Security[application.comment[1]]
        end
      end

      def mobile?
        mini?
      end

      def os
        return unless application.comment

        if application.comment[0] =~ /Windows/
          OperatingSystems.normalize_os(application.comment[0])
        else
          application.comment[1]
        end
      end

      def localization
        return unless application.comment

        if macintosh?
          application.comment[3]
        else
          application.comment[2]
        end
      end

      private
        def mini?
          /Opera Mini/ === application
        end

        def macintosh?
          platform == 'Macintosh'
        end
    end
  end
end
