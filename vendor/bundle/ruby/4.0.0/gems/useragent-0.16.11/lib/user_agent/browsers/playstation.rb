class UserAgent
  module Browsers
    # Mozilla/5.0 (PLAYSTATION 3 4.75) AppleWebKit/531.22.8 (KHTML, like Gecko)
    # Mozilla/5.0 (PLAYSTATION 3 4.76) AppleWebKit/531.22.8 (KHTML, like Gecko)
    # Mozilla/5.0 (PLAYSTATION 3; 1.00)
    # Mozilla/5.0 (PlayStation Vita 3.52) AppleWebKit/537.73 (KHTML, like Gecko) Silk/3.2
    # Mozilla/5.0 (PlayStation 4 2.57) AppleWebKit/537.73 (KHTML, like Gecko)
    class PlayStation < Base
      def self.extend?(agent)
        !agent.application.nil? && !agent.application.comment.nil? && agent.application.comment.any? && (
          agent.application.comment.first.include?('PLAYSTATION 3') ||
          agent.application.comment.first.include?('PlayStation Vita') ||
          agent.application.comment.first.include?('PlayStation 4')
        )
      end

      # Returns the name of the browser in use.
      # 
      # @return [nil, String] the name of the browser
      def browser
        if application.comment.first.include?('PLAYSTATION 3')
          'PS3 Internet Browser'
        elsif last.product == 'Silk'
          'Silk'
        elsif application.comment.first.include?('PlayStation 4')
          'PS4 Internet Browser'
        else
          nil
        end
      end

      # PS Vita is mobile, others are not.
      # 
      # @return [true, false] is this a mobile browser?
      def mobile?
        platform == 'PlayStation Vita'
      end

      # Returns the operating system in use.
      # 
      # @return [String] the operating system in use
      def os
        application.comment.join(' ')
      end

      # Returns the platform in use.
      # 
      # @return [nil, "PlayStation 3", "PlayStation 4", "PlayStation Vita"] the platform in use
      def platform
        if os.include?('PLAYSTATION 3')
          'PlayStation 3'
        elsif os.include?('PlayStation 4')
          'PlayStation 4'
        elsif os.include?('PlayStation Vita')
          'PlayStation Vita'
        else
          nil
        end
      end

      # Returns the browser version in use. If Silk, returns the version of Silk.
      # Otherwise, returns the PS3/PS4 firmware version.
      # 
      # @return [nil, Version] the version
      def version
        if browser == 'Silk'
          last.version
        elsif platform == 'PlayStation 3'
          Version.new(os.split('PLAYSTATION 3 ').last)
        elsif platform == 'PlayStation 4'
          Version.new(os.split('PlayStation 4 ').last)
        elsif platform == 'PlayStation Vita'
          Version.new(os.split('PlayStation Vita ').last)
        else
          nil
        end
      end
    end
  end
end
