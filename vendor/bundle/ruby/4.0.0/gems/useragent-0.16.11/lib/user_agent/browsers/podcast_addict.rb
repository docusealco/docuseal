class UserAgent
  module Browsers
    # Podcast Addict - Dalvik/1.6.0 (Linux; U; Android 4.4.2; LG-D631 Build/KOT49I.D63110b)
    # Podcast Addict - Dalvik/2.1.0 (Linux; U; Android 5.1; XT1093 Build/LPE23.32-21.3)
    # Podcast Addict - Mozilla/5.0 (Linux; U; Android 4.2.2; en-us; ALCATEL ONE TOUCH Fierce Build/JDQ39) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.2 Mobile Safari/534.30
    # Podcast Addict - Mozilla/5.0 (Linux; U; Android 4.2.2; en-ca; ALCATEL ONE TOUCH 6040A Build/JDQ39) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.2 Mobile Safari/534.30
    # Podcast Addict - Dalvik/2.1.0 (Linux; U; Android M Build/MPZ79M)
    class PodcastAddict < Base
      def self.extend?(agent)
        agent.length >= 3 && agent[0].product == 'Podcast' && agent[1].product == 'Addict' && agent[2].product == '-'
      end

      def browser
        'Podcast Addict'
      end

      # If we can figure out the device, return it.
      # 
      # @return [nil, String] the device model
      def device
        return nil unless length >= 4
        return nil unless self[3].comment.last.include?(' Build/')

        self[3].comment.last.split(' Build/').first
      end

      # If we can figure out the device build, return it.
      # 
      # @return [nil, String] the device build
      def device_build
        return nil unless length >= 4
        return nil unless self[3].comment.last.include?(' Build/')

        self[3].comment.last.split(' Build/').last
      end

      # Returns the localization, if known. We currently only know this for certain devices.
      # 
      # @return [nil, String] the localization
      def localization
        return nil unless length >= 4
        return nil unless self[3].comment.last.include?('ALCATEL ')
        return nil unless self[3].comment.length >= 5

        self[3].comment[3]
      end

      # This is a mobile app, always return true.
      # 
      # @return [true]
      def mobile?
        true
      end

      # Gets the operating system (some variant of Android, if we're certain that is the case)
      # 
      # @return [nil, String] the operating system
      def os
        return nil unless length >= 4

        # comment[0] = 'Linux'
        # comment[1] = 'U'
        # comment[2] = 'Android x.y.z' except when there are only 3 tokens, then we don't know the version
        if (self[3].product == 'Dalvik' || self[3].product == 'Mozilla') && self[3].comment.length > 3
          self[3].comment[2]
        elsif (self[3].product == 'Dalvik' || self[3].product == 'Mozilla') && self[3].comment.length == 3
          'Android'
        else
          nil
        end
      end

      # Gets the platform (Android, if we're certain)
      # 
      # @return [nil, "Android"] the platform
      def platform
        if os.include?('Android')
          'Android'
        else
          nil
        end
      end


      # Get the security level reported
      # 
      # @return [:weak, :strong, :none] the security level
      def security
        return nil unless length >= 4
        return nil unless self[3].product == 'Dalvik' || self[3].product == 'Mozilla'

        Security[self[3].comment[1]]
      end

      # We aren't provided with the version :(
      #
      # @return [nil]
      def version
        nil
      end
    end
  end
end