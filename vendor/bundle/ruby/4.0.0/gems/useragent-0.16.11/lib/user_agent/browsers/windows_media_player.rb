class UserAgent
  module Browsers
    # The user agent used by Windows Media Player or applications which utilize the
    # Windows Media SDK.
    # 
    # @note Both VLC and libavformat impersonate Windows Media Player when they think they
    #       are using MMS (Microsoft Media Services/Windows Media Server).
    class WindowsMediaPlayer < Base
      def self.extend?(agent)
        agent.detect do |useragent|
          %w(NSPlayer Windows-Media-Player WMFSDK).include?(useragent.product) &&
            agent.version != "4.1.0.3856" && # 4.1.0.3856 is libavformat
            agent.version != "7.10.0.3059" && # used by VLC for mmsh support
            agent.version != "7.0.0.1956" # used by VLC for mmstu support
        end
      end

      # The Windows Media Format SDK version
      # 
      # @return [Version, nil] The WMFSDK version
      def wmfsdk_version
        (respond_to?("WMFSDK") && self.send("WMFSDK").version) || nil
      end

      # Check if the client supports the WMFSDK version passed in.
      # 
      # @param [String] version
      #   The WMFSDK version to check for. For example, "9.0", "11.0", "12.0"
      # @return [true, false] Is this media player compatible with the passed WMFSDK version?
      def has_wmfsdk?(version)
        if wmfsdk_version && wmfsdk_version.to_s =~ /\A#{version}/
          return true
        else
          return false
        end
      end

      # @return ["Windows Media Player"] All of the user agents we parse are Windows Media Player
      def browser
        "Windows Media Player"
      end

      # @return ["Windows"] All of the user agents we parse are on Windows
      def platform
        "Windows"
      end

      # @return [true, false] Is this Windows Media Player 6.4 (NSPlayer 4.1) or Media Player 6.0 (NSPlayer 3.2)?
      def classic?
        version.to_a[0] <= 4
      end

      # Check if our parsed OS is a mobile OS
      # 
      # @return [true, false] Is this a mobile Windows Media Player?
      def mobile?
        ["Windows Phone 8", "Windows Phone 8.1"].include?(os)
      end

      # Parses the Windows Media Player version to figure out the host OS version
      # 
      # User agents I have personally found:
      # 
      # Windows 95 with Windows Media Player 6.4::
      #   NSPlayer/4.1.0.3857
      # 
      # Windows 98 SE with Windows Media Player 6.01::
      #   NSPlayer/3.2.0.3564
      # 
      # Womdpws 98 SE with Windows Media Player 6.4::
      #   NSPlayer/4.1.0.3857
      #   NSPlayer/4.1.0.3925
      # 
      # Windows 98 SE with Windows Media Player 7.1::
      #   NSPlayer/7.1.0.3055
      # 
      # Windows 98 SE with Windows Media Player 9.0::
      #   Windows-Media-Player/9.00.00.2980
      #   NSPlayer/9.0.0.2980 WMFSDK/9.0
      # 
      # Windows 2000 with Windows Media Player 6.4::
      #   NSPlayer/4.1.0.3938
      # 
      # Windows 2000 with Windows Media Player 7.1 (downgraded from WMP9)::
      #   NSPlayer/9.0.0.3268
      #   NSPlayer/9.0.0.3268 WMFSDK/9.0
      #   NSPlayer/9.0.0.3270 WMFSDK/9.0
      #   NSPlayer/9.0.0.2980
      # 
      # Windows 2000 with Windows Media Player 9.0::
      #   NSPlayer/9.0.0.3270 WMFSDK/9.0
      #   Windows-Media-Player/9.00.00.3367
      # 
      # Windows XP with Windows Media Player 6.4:: 
      #   NSPlayer/4.1.0.3936
      # 
      # Windows XP with Windows Media Player 9::
      #   NSPlayer/9.0.0.4503
      #   NSPlayer/9.0.0.4503 WMFSDK/9.0
      #   Windows-Media-Player/9.00.00.4503
      # 
      # Windows XP with Windows Media Player 10::
      #   NSPlayer/10.0.0.3802
      #   NSPlayer/10.0.0.3802 WMFSDK/10.0
      #   Windows-Media-Player/10.00.00.3802
      # 
      # Windows XP with Windows Media Player 11::
      #   NSPlayer/11.0.5721.5262
      #   NSPlayer/11.0.5721.5262 WMFSDK/11.0
      #   Windows-Media-Player/11.0.5721.5262
      # 
      # Windows Vista with Windows Media Player 11::
      #   NSPlayer/11.00.6002.18392 WMFSDK/11.00.6002.18392
      #   NSPlayer/11.0.6002.18005
      #   NSPlayer/11.0.6002.18049 WMFSDK/11.0
      #   Windows-Media-Player/11.0.6002.18311
      # 
      # Windows 8.1 with Windows Media Player 12::
      #   NSPlayer/12.00.9600.17031 WMFSDK/12.00.9600.17031
      # 
      # Windows 10 with Windows Media Player 12::
      #   Windows-Media-Player/12.0.9841.0
      #   NSPlayer/12.00.9841.0000 WMFSDK/12.00.9841.0000
      # 
      # Windows Phone 8.1 (Podcasts app)::
      #   NSPlayer/12.00.9651.0000 WMFSDK/12.00.9651.0000
      def os
        # WMP 6.4
        if classic?
          case version.to_a[3]
          when 3564, 3925 then  "Windows 98"
          when 3857 then        "Windows 9x"
          when 3936 then        "Windows XP"
          when 3938 then        "Windows 2000"
          else "Windows"
          end

        # WMP 7/7.1
        elsif version.to_a[0] == 7
          case version.to_a[3]
          when 3055 then "Windows 98"
          else "Windows"
          end

        # WMP 8 was also known as "Windows Media Player for Windows XP"
        elsif version.to_a[0] == 8
          "Windows XP"

        # WMP 9/10
        elsif version.to_a[0] == 9 || version.to_a[0] == 10
          case version.to_a[3]
          when 2980 then              "Windows 98/2000"
          when 3268, 3367, 3270 then  "Windows 2000"
          when 3802, 4503 then        "Windows XP"
          else "Windows"
          end

        # WMP 11/12
        elsif version.to_a[0] == 11 || version.to_a[0] == 12
          case version.to_a[2]
          when 9841, 9858, 9860,
               9879 then              "Windows 10"
          when 9651 then              "Windows Phone 8.1"
          when 9600 then              "Windows 8.1"
          when 9200 then              "Windows 8"
          when 7600, 7601 then        "Windows 7"
          when 6000, 6001, 6002 then  "Windows Vista"
          when 5721 then              "Windows XP"
          else                        "Windows"
          end
        else
          "Windows"
        end
      end
    end
  end
end