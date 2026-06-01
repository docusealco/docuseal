module Turbo::SystemTestHelper
  # Delay until every `<turbo-cable-stream-source>` element present in the page
  # is ready to receive broadcasts
  #
  #   test "renders broadcasted Messages" do
  #     message = Message.new content: "Hello, from Action Cable"
  #
  #     visit "/"
  #     click_link "All Messages"
  #     message.save! # execute server-side code to broadcast a Message
  #
  #     assert_text message.content
  #   end
  #
  # By default, calls to `#visit` will wait for all `<turbo-cable-stream-source>`
  # elements to connect. You can control this by modifying the
  # `config.turbo.test_connect_after_actions`. For example, to wait after calls to
  # `#click_link`, add the following to `config/environments/test.rb`:
  #
  #   # config/environments/test.rb
  #   config.turbo.test_connect_after_actions << :click_link
  #
  # To disable automatic connecting, set the configuration to `[]`:
  #
  #   # config/environments/test.rb
  #   config.turbo.test_connect_after_actions = []
  #
  def connect_turbo_cable_stream_sources(**options, &block)
    all(:turbo_cable_stream_source, **options, connected: false, wait: 0).each do |element|
      element.assert_matches_selector(:turbo_cable_stream_source, **options, connected: true, &block)
    end
  end

  # Asserts that a `<turbo-cable-stream-source>` element is present in the
  # document
  #
  # ==== Arguments
  #
  # * <tt>locator</tt> optional locator to determine the element's
  #   `[signed-stream-name]` attribute. Can be of any type that is a valid
  #   argument to <tt>Turbo::Streams::StreamName#signed_stream_name</tt>.
  #
  # ==== Options
  #
  # * <tt>:connected</tt> matches the `[connected]` attribute
  # * <tt>:channel</tt> matches the `[channel]` attribute. Can be a Class,
  #   String, Symbol, or Regexp
  # * <tt>:signed_stream_name</tt> matches the element's `[signed-stream-name]`
  #   attribute. Can be of any type that is a valid
  #   argument to <tt>Turbo::Streams::StreamName#signed_stream_name</tt>.
  #
  # In addition to the filters listed above, accepts any valid Capybara global
  # filter option.
  def assert_turbo_cable_stream_source(...)
    assert_selector(:turbo_cable_stream_source, ...)
  end

  # Asserts that a `<turbo-cable-stream-source>` element is absent from the
  # document
  #
  # ==== Arguments
  #
  # * <tt>locator</tt> optional locator to determine the element's
  #   `[signed-stream-name]` attribute. Can be of any type that is a valid
  #   argument to <tt>Turbo::Streams::StreamName#signed_stream_name</tt>.
  #
  # ==== Options
  #
  # * <tt>:connected</tt> matches the `[connected]` attribute
  # * <tt>:channel</tt> matches the `[channel]` attribute. Can be a Class,
  #   String, Symbol, or Regexp
  # * <tt>:signed_stream_name</tt> matches the element's `[signed-stream-name]`
  #   attribute. Can be of any type that is a valid
  #   argument to <tt>Turbo::Streams::StreamName#signed_stream_name</tt>.
  #
  # In addition to the filters listed above, accepts any valid Capybara global
  # filter option.
  def assert_no_turbo_cable_stream_source(...)
    assert_no_selector(:turbo_cable_stream_source, ...)
  end

  Capybara.add_selector :turbo_cable_stream_source do
    visible :all

    xpath do |locator|
      xpath = XPath.descendant.where(XPath.local_name == "turbo-cable-stream-source")
      xpath.where(SignedStreamNameConditions.new(locator).reduce(:|))
    end

    expression_filter :connected do |xpath, value|
      builder(xpath).add_attribute_conditions(connected: value)
    end

    expression_filter :channel do |xpath, value|
      builder(xpath).add_attribute_conditions(channel: value.try(:name) || value)
    end

    expression_filter :signed_stream_name do |xpath, value|
      case value
      when TrueClass, FalseClass, NilClass, Regexp
        builder(xpath).add_attribute_conditions("signed-stream-name": value)
      else
        xpath.where(SignedStreamNameConditions.new(value).reduce(:|))
      end
    end
  end

  class SignedStreamNameConditions # :nodoc:
    include Turbo::Streams::StreamName, Enumerable

    def initialize(value)
      @value = value
    end

    def attribute
      XPath.attr(:"signed-stream-name")
    end

    def each
      if @value.is_a?(String)
        yield attribute == @value
        yield attribute == signed_stream_name(@value)
      elsif @value.is_a?(Array) || @value.respond_to?(:to_key)
        yield attribute == signed_stream_name(@value)
      elsif @value.present?
        yield attribute == @value
      end
    end
  end
end
