module Turbo
  module TestAssertions
    module IntegrationTestAssertions
      # Assert that the Turbo Stream request's response body's HTML contains a
      # `<turbo-stream>` element.
      #
      # ==== Options
      #
      # * <tt>:status</tt> [Integer, Symbol] the HTTP response status
      # * <tt>:action</tt> [String] matches the element's <tt>[action]</tt>
      #   attribute
      # * <tt>:target</tt> [String, #to_key] matches the element's
      #   <tt>[target]</tt> attribute. If the value responds to <tt>#to_key</tt>,
      #   the value will be transformed by calling <tt>dom_id</tt>
      # * <tt>:targets</tt> [String] matches the element's <tt>[targets]</tt>
      #   attribute
      #
      #   Given the following HTML response body:
      #
      #     <turbo-stream action="remove" target="message_1"></turbo-stream>
      #
      #   The following assertion would pass:
      #
      #     assert_turbo_stream action: "remove", target: "message_1"
      #
      # You can also pass a block make assertions about the contents of the
      # element. Given the following HTML response body:
      #
      #     <turbo-stream action="replace" target="message_1">
      #       <template>
      #         <p>Hello!</p>
      #       <template>
      #     </turbo-stream>
      #
      #   The following assertion would pass:
      #
      #     assert_turbo_stream action: "replace", target: "message_1" do
      #       assert_select "template p", text: "Hello!"
      #     end
      #
      def assert_turbo_stream(status: :ok, **attributes, &block)
        assert_response status
        assert_equal Mime[:turbo_stream], response.media_type
        super(**attributes, &block)
      end

      # Assert that the Turbo Stream request's response body's HTML does not
      # contain a `<turbo-stream>` element.
      #
      # ==== Options
      #
      # * <tt>:status</tt> [Integer, Symbol] the HTTP response status
      # * <tt>:action</tt> [String] matches the element's <tt>[action]</tt>
      #   attribute
      # * <tt>:target</tt> [String, #to_key] matches the element's
      #   <tt>[target]</tt> attribute. If the value responds to <tt>#to_key</tt>,
      #   the value will be transformed by calling <tt>dom_id</tt>
      # * <tt>:targets</tt> [String] matches the element's <tt>[targets]</tt>
      #   attribute
      #
      #   Given the following HTML response body:
      #
      #     <turbo-stream action="remove" target="message_1"></turbo-stream>
      #
      #   The following assertion would fail:
      #
      #     assert_no_turbo_stream action: "remove", target: "message_1"
      #
      def assert_no_turbo_stream(status: :ok, **attributes)
        assert_response status
        assert_equal Mime[:turbo_stream], response.media_type
        super(**attributes)
      end
    end
  end
end
