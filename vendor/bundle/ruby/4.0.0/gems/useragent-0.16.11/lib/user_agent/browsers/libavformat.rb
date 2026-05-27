class UserAgent
  module Browsers
    # The user agent utilized by ffmpeg or other projects utilizing libavformat
    class Libavformat < Base
      def self.extend?(agent)
        agent.detect do |useragent|
          useragent.product == "Lavf" || (useragent.product == "NSPlayer" && agent.version == "4.1.0.3856")
        end
      end

      # @return ["libavformat"] To make it easy to pick it out, all of the UAs that Lavf uses have this browser.
      def browser
        "libavformat"
      end

      # @return [nil, Version] If the product is NSPlayer, we don't have a version
      def version
        super unless detect_product("NSPlayer")
      end

      # @return [nil] Lavf doesn't return us anything here
      def os
        nil
      end

      # @return [nil] Lavf doesn't return us anything here
      def platform
        nil
      end
    end
  end
end