class UserAgent
  module Browsers
    class Edge < Base
      OS_REGEXP = /Windows NT [\d\.]+|Windows Phone (OS )?[\d\.]+/

      def self.extend?(agent)
        agent.last && agent.last.product == "Edge"
      end

      def browser
        "Edge"
      end

      def version
        last.version
      end

      def platform
        "Windows"
      end

      def os
        OperatingSystems.normalize_os(os_comment)
      end

      private

      def os_comment
        detect_comment_match(OS_REGEXP).to_s
      end
    end
  end
end
