# frozen_string_literal: true

module Ferrum
  class Page
    module Screencast
      # Starts sending frames to record screencast to the given block.
      #
      # @param [Hash{Symbol => Object}] opts
      #
      # @option opts [:jpeg, :png] :format
      #   The format the image should be returned in.
      #
      # @option opts [Integer] :quality
      #   The image quality. **Note:** 0-100 works for JPEG only.
      #
      # @option opts [Integer] :max_width
      #   Maximum screencast frame width.
      #
      # @option opts [Integer] :max_height
      #   Maximum screencast frame height.
      #
      # @option opts [Integer] :every_nth_frame
      #   Send every n-th frame.
      #
      # @yield [data, metadata, session_id]
      #   The given block receives the screencast frame along with metadata
      #   about the frame and the screencast session ID.
      #
      # @yieldparam data [String]
      #   Base64-encoded compressed image.
      #
      # @yieldparam metadata [Hash{String => Object}]
      #   Screencast frame metadata.
      #
      # @option metadata [Integer] 'offsetTop'
      #   Top offset in DIP.
      #
      # @option metadata [Integer] 'pageScaleFactor'
      #   Page scale factor.
      #
      # @option metadata [Integer] 'deviceWidth'
      #   Device screen width in DIP.
      #
      # @option metadata [Integer] 'deviceHeight'
      #   Device screen height in DIP.
      #
      # @option metadata [Integer] 'scrollOffsetX'
      #   Position of horizontal scroll in CSS pixels.
      #
      # @option metadata [Integer] 'scrollOffsetY'
      #   Position of vertical scroll in CSS pixels.
      #
      # @option metadata [Float] 'timestamp'
      #   (optional) Frame swap timestamp in seconds since Unix epoch.
      #
      # @yieldparam session_id [Integer]
      #   Frame number.
      #
      # @example
      #   require "base64"
      #
      #   page.go_to("https://apple.com/ipad")
      #
      #   page.start_screencast(format: :jpeg, quality: 75) do |data, metadata|
      #     timestamp = (metadata['timestamp'] * 1000).to_i
      #     File.binwrite("image_#{timestamp}.jpg", Base64.decode64(data))
      #   end
      #
      #   sleep 10
      #
      #   page.stop_screencast
      #
      def start_screencast(**opts)
        options = opts.transform_keys { START_SCREENCAST_KEY_CONV.fetch(_1, _1) }
        response = command("Page.startScreencast", **options)

        if (error_text = response["errorText"]) # https://cs.chromium.org/chromium/src/net/base/net_error_list.h
          raise "Starting screencast failed (#{error_text})"
        end

        on("Page.screencastFrame") do |params|
          data, metadata, session_id = params.values_at("data", "metadata", "sessionId")

          command("Page.screencastFrameAck", sessionId: session_id)

          yield data, metadata, session_id
        end
      end

      # Stops sending frames.
      def stop_screencast
        command("Page.stopScreencast")
      end

      START_SCREENCAST_KEY_CONV = {
        max_width: :maxWidth,
        max_height: :maxHeight,
        every_nth_frame: :everyNthFrame
      }.freeze
    end
  end
end
