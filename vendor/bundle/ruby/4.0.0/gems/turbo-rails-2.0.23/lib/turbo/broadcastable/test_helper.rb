module Turbo
  module Broadcastable
    module TestHelper
      extend ActiveSupport::Concern

      included do
        include ActionCable::TestHelper

        include Turbo::Streams::StreamName
      end

      # Asserts that `<turbo-stream>` elements were broadcast over Action Cable
      #
      # ==== Arguments
      #
      # * <tt>stream_name_or_object</tt> the objects used to generate the
      #   channel Action Cable name, or the name itself
      # * <tt>&block</tt> optional block executed before the
      #   assertion
      #
      # ==== Options
      #
      # * <tt>count:</tt> the number of `<turbo-stream>` elements that are
      # expected to be broadcast
      #
      # Asserts `<turbo-stream>` elements were broadcast:
      #
      #     message = Message.find(1)
      #     message.broadcast_replace_to "messages"
      #
      #     assert_turbo_stream_broadcasts "messages"
      #
      # Asserts that two `<turbo-stream>` elements were broadcast:
      #
      #     message = Message.find(1)
      #     message.broadcast_replace_to "messages"
      #     message.broadcast_remove_to "messages"
      #
      #     assert_turbo_stream_broadcasts "messages", count: 2
      #
      # You can pass a block to run before the assertion:
      #
      #     message = Message.find(1)
      #
      #     assert_turbo_stream_broadcasts "messages" do
      #       message.broadcast_append_to "messages"
      #     end
      #
      # In addition to a String, the helper also accepts an Object or Array to
      # determine the name of the channel the elements are broadcast to:
      #
      #     message = Message.find(1)
      #
      #     assert_turbo_stream_broadcasts message do
      #       message.broadcast_replace
      #     end
      #
      def assert_turbo_stream_broadcasts(stream_name_or_object, count: nil, &block)
        payloads = capture_turbo_stream_broadcasts(stream_name_or_object, &block)
        stream_name = stream_name_from(stream_name_or_object)

        if count.nil?
          assert_not_empty payloads, "Expected at least one broadcast on #{stream_name.inspect}, but there were none"
        else
          broadcasts = "Turbo Stream broadcast".pluralize(count)

          assert count == payloads.count, "Expected #{count} #{broadcasts} on #{stream_name.inspect}, but there were #{payloads.count}"
        end
      end

      # Asserts that no `<turbo-stream>` elements were broadcast over Action Cable
      #
      # ==== Arguments
      #
      # * <tt>stream_name_or_object</tt> the objects used to generate the
      #   channel Action Cable name, or the name itself
      # * <tt>&block</tt> optional block executed before the
      #   assertion
      #
      # Asserts that no `<turbo-stream>` elements were broadcast:
      #
      #     message = Message.find(1)
      #     message.broadcast_replace_to "messages"
      #
      #     assert_no_turbo_stream_broadcasts "messages" # fails with MiniTest::Assertion error
      #
      # You can pass a block to run before the assertion:
      #
      #     message = Message.find(1)
      #
      #     assert_no_turbo_stream_broadcasts "messages" do
      #       # do something other than broadcast to "messages"
      #     end
      #
      # In addition to a String, the helper also accepts an Object or Array to
      # determine the name of the channel the elements are broadcast to:
      #
      #     message = Message.find(1)
      #
      #     assert_no_turbo_stream_broadcasts message do
      #       # do something other than broadcast to "message_1"
      #     end
      #
      def assert_no_turbo_stream_broadcasts(stream_name_or_object, &block)
        block&.call

        stream_name = stream_name_from(stream_name_or_object)

        payloads = broadcasts(stream_name)

        assert payloads.empty?, "Expected no broadcasts on #{stream_name.inspect}, but there were #{payloads.count}"
      end

      # Captures any `<turbo-stream>` elements that were broadcast over Action Cable
      #
      # ==== Arguments
      #
      # * <tt>stream_name_or_object</tt> the objects used to generate the
      #   channel Action Cable name, or the name itself
      # * <tt>&block</tt> optional block to capture broadcasts during execution
      #
      # Returns any `<turbo-stream>` elements that have been broadcast as an
      # Array of <tt>Nokogiri::XML::Element</tt> instances
      #
      #     message = Message.find(1)
      #     message.broadcast_append_to "messages"
      #     message.broadcast_prepend_to "messages"
      #
      #     turbo_streams = capture_turbo_stream_broadcasts "messages"
      #
      #     assert_equal "append", turbo_streams.first["action"]
      #     assert_equal "prepend", turbo_streams.second["action"]
      #
      # You can pass a block to limit the scope of the broadcasts being captured:
      #
      #     message = Message.find(1)
      #
      #     turbo_streams = capture_turbo_stream_broadcasts "messages" do
      #       message.broadcast_append_to "messages"
      #     end
      #
      #     assert_equal "append", turbo_streams.first["action"]
      #
      # In addition to a String, the helper also accepts an Object or Array to
      # determine the name of the channel the elements are broadcast to:
      #
      #     message = Message.find(1)
      #
      #     replace, remove = capture_turbo_stream_broadcasts message do
      #       message.broadcast_replace
      #       message.broadcast_remove
      #     end
      #
      #     assert_equal "replace", replace["action"]
      #     assert_equal "replace", remove["action"]
      #
      def capture_turbo_stream_broadcasts(stream_name_or_object, &block)
        stream_name = stream_name_from(stream_name_or_object)
        payloads = if block_given?
          new_broadcasts_from(broadcasts(stream_name), stream_name, "capture_turbo_stream_broadcasts", &block)
        else
          broadcasts(stream_name)
        end

        payloads.flat_map do |payload|
          html = ActiveSupport::JSON.decode(payload)
          document = Nokogiri::HTML5.parse(html)

          document.at("body").element_children
        end
      end
    end
  end
end
