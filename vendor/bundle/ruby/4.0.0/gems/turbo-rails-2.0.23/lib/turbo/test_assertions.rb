module Turbo
  module TestAssertions
    extend ActiveSupport::Concern

    included do
      # FIXME: Should happen in Rails at a different level
      delegate :dom_id, :dom_class, to: ActionView::RecordIdentifier
    end

    # Assert that the rendered fragment of HTML contains a `<turbo-stream>`
    # element.
    #
    # ==== Options
    #
    # * <tt>:action</tt> [String] matches the element's <tt>[action]</tt>
    #   attribute
    # * <tt>:target</tt> [String, #to_key] matches the element's
    #   <tt>[target]</tt> attribute. If the value responds to <tt>#to_key</tt>,
    #   the value will be transformed by calling <tt>dom_id</tt>
    # * <tt>:targets</tt> [String] matches the element's <tt>[targets]</tt>
    #   attribute
    # * <tt>:count</tt> [Integer] indicates how many turbo streams are expected.
    #   Defaults to <tt>1</tt>.
    #
    #   Given the following HTML fragment:
    #
    #     <turbo-stream action="remove" target="message_1"></turbo-stream>
    #
    #   The following assertion would pass:
    #
    #     assert_turbo_stream action: "remove", target: "message_1"
    #
    # You can also pass a block make assertions about the contents of the
    # element. Given the following HTML fragment:
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
    def assert_turbo_stream(action:, target: nil, targets: nil, count: 1, &block)
      selector =  %(turbo-stream[action="#{action}"])
      selector << %([target="#{target.respond_to?(:to_key) ? dom_id(target) : target}"]) if target
      selector << %([targets="#{targets}"]) if targets
      assert_select selector, count: count, &block
    end

    # Assert that the rendered fragment of HTML does not contain a `<turbo-stream>`
    # element.
    #
    # ==== Options
    #
    # * <tt>:action</tt> [String] matches the element's <tt>[action]</tt>
    #   attribute
    # * <tt>:target</tt> [String, #to_key] matches the element's
    #   <tt>[target]</tt> attribute. If the value responds to <tt>#to_key</tt>,
    #   the value will be transformed by calling <tt>dom_id</tt>
    # * <tt>:targets</tt> [String] matches the element's <tt>[targets]</tt>
    #   attribute
    #
    #   Given the following HTML fragment:
    #
    #     <turbo-stream action="remove" target="message_1"></turbo-stream>
    #
    #   The following assertion would fail:
    #
    #     assert_no_turbo_stream action: "remove", target: "message_1"
    #
    def assert_no_turbo_stream(action:, target: nil, targets: nil)
      selector =  %(turbo-stream[action="#{action}"])
      selector << %([target="#{target.respond_to?(:to_key) ? dom_id(target) : target}"]) if target
      selector << %([targets="#{targets}"]) if targets
      assert_select selector, count: 0
    end

    # Assert that the rendered fragment of HTML contains a `<turbo-frame>`
    # element.
    #
    # ==== Arguments
    #
    # * <tt>ids</tt> [String, Array<String, ActiveRecord::Base>] matches the element's <tt>[id]</tt> attribute
    #
    # ==== Options
    #
    # * <tt>:loading</tt> [String] matches the element's <tt>[loading]</tt>
    #   attribute
    # * <tt>:src</tt> [String] matches the element's <tt>[src]</tt> attribute
    # * <tt>:target</tt> [String] matches the element's <tt>[target]</tt>
    #   attribute
    # * <tt>:count</tt> [Integer] indicates how many turbo frames are expected.
    #   Defaults to <tt>1</tt>.
    #
    #   Given the following HTML fragment:
    #
    #     <turbo-frame id="example" target="_top"></turbo-frame>
    #
    #   The following assertion would pass:
    #
    #     assert_turbo_frame id: "example", target: "_top"
    #
    # You can also pass a block make assertions about the contents of the
    # element. Given the following HTML fragment:
    #
    #     <turbo-frame id="example">
    #       <p>Hello!</p>
    #     </turbo-frame>
    #
    #   The following assertion would pass:
    #
    #     assert_turbo_frame id: "example" do
    #       assert_select "p", text: "Hello!"
    #     end
    #
    def assert_turbo_frame(*ids, loading: nil, src: nil, target: nil, count: 1, &block)
      id = ids.first.respond_to?(:to_key) ? ActionView::RecordIdentifier.dom_id(*ids) : ids.join('_')
      selector = %(turbo-frame[id="#{id}"])
      selector << %([loading="#{loading}"]) if loading
      selector << %([src="#{src}"]) if src
      selector << %([target="#{target}"]) if target
      assert_select selector, count: count, &block
    end

    # Assert that the rendered fragment of HTML does not contain a `<turbo-frame>`
    # element.
    #
    # ==== Arguments
    #
    # * <tt>ids</tt> [String, Array<String, ActiveRecord::Base>] matches the <tt>[id]</tt> attribute
    #
    # ==== Options
    #
    # * <tt>:loading</tt> [String] matches the element's <tt>[loading]</tt>
    #   attribute
    # * <tt>:src</tt> [String] matches the element's <tt>[src]</tt> attribute
    # * <tt>:target</tt> [String] matches the element's <tt>[target]</tt>
    #   attribute
    #
    #   Given the following HTML fragment:
    #
    #     <turbo-frame id="example" target="_top"></turbo-frame>
    #
    #   The following assertion would fail:
    #
    #     assert_no_turbo_frame id: "example", target: "_top"
    #
    def assert_no_turbo_frame(*ids, **options, &block)
      assert_turbo_frame(*ids, **options, count: 0, &block)
    end
  end
end
