module Turbo::Streams::ActionHelper
  include ActionView::Helpers::TagHelper

  # Creates a `turbo-stream` tag according to the passed parameters. Examples:
  #
  #   turbo_stream_action_tag "remove", target: "message_1"
  #   # => <turbo-stream action="remove" target="message_1"></turbo-stream>
  #
  #   turbo_stream_action_tag "replace", target: "message_1", template: %(<div id="message_1">Hello!</div>)
  #   # => <turbo-stream action="replace" target="message_1"><template><div id="message_1">Hello!</div></template></turbo-stream>
  #
  #   turbo_stream_action_tag "replace", targets: "message_1", template: %(<div id="message_1">Hello!</div>)
  #   # => <turbo-stream action="replace" targets="message_1"><template><div id="message_1">Hello!</div></template></turbo-stream>
  #
  # The `target:` keyword option will forward `ActionView::RecordIdentifier#dom_id`-compatible arguments to
  # `ActionView::RecordIdentifier#dom_id`
  #
  #   message = Message.find(1)
  #   turbo_stream_action_tag "remove", target: message
  #   # => <turbo-stream action="remove" target="message_1"></turbo-stream>
  #
  #   turbo_stream_action_tag "remove", target: Message
  #   # => <turbo-stream action="remove" target="new_message"></turbo-stream>
  #
  #   message = Message.find(1)
  #   turbo_stream_action_tag "remove", target: [message, :special]
  #   # => <turbo-stream action="remove" target="special_message_1"></turbo-stream>
  def turbo_stream_action_tag(action, target: nil, targets: nil, template: nil, **attributes)
    template = action.to_sym.in?(%i[ remove refresh ]) ? "" : tag.template(template.to_s.html_safe)

    if target = convert_to_turbo_stream_dom_id(target)
      tag.turbo_stream(template, **attributes, action: action, target: target)
    elsif targets = convert_to_turbo_stream_dom_id(targets, include_selector: true)
      tag.turbo_stream(template, **attributes, action: action, targets: targets)
    else
      tag.turbo_stream(template, **attributes, action: action)
    end
  end

  # Creates a `turbo-stream` tag with an `action="refresh"` attribute. Example:
  #
  #   turbo_stream_refresh_tag
  #   # => <turbo-stream action="refresh"></turbo-stream>
  def turbo_stream_refresh_tag(request_id: Turbo.current_request_id, **attributes)
    turbo_stream_action_tag(:refresh, "request-id": request_id.presence, **attributes)
  end

  private
    def convert_to_turbo_stream_dom_id(target, include_selector: false)
      target_array = Array.wrap(target)
      if target_array.any? { |value| value.respond_to?(:to_key) || value.is_a?(Class) }
        "#{"#" if include_selector}#{ActionView::RecordIdentifier.dom_id(*target_array)}"
      else
        target
      end
    end
end
