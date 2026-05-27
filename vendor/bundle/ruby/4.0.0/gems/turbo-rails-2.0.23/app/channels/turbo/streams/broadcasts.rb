# Provides the broadcast actions in synchronous and asynchronous form for the <tt>Turbo::StreamsChannel</tt>.
# See <tt>Turbo::Broadcastable</tt> for the user-facing API that invokes these methods with most of the paperwork filled out already.
#
# Can be used directly using something like <tt>Turbo::StreamsChannel.broadcast_remove_to :entries, target: 1</tt>.
module Turbo::Streams::Broadcasts
  include Turbo::Streams::ActionHelper

  def broadcast_remove_to(*streamables, **opts)
    broadcast_action_to(*streamables, action: :remove, render: false, **opts)
  end

  def broadcast_replace_to(*streamables, **opts)
    broadcast_action_to(*streamables, action: :replace, **opts)
  end

  def broadcast_update_to(*streamables, **opts)
    broadcast_action_to(*streamables, action: :update, **opts)
  end

  def broadcast_before_to(*streamables, **opts)
    broadcast_action_to(*streamables, action: :before, **opts)
  end

  def broadcast_after_to(*streamables, **opts)
    broadcast_action_to(*streamables, action: :after, **opts)
  end

  def broadcast_append_to(*streamables, **opts)
    broadcast_action_to(*streamables, action: :append, **opts)
  end

  def broadcast_prepend_to(*streamables, **opts)
    broadcast_action_to(*streamables, action: :prepend, **opts)
  end

  def broadcast_refresh_to(*streamables, **attributes)
    broadcast_stream_to(*streamables, content: turbo_stream_refresh_tag(**attributes))
  end

  def broadcast_action_to(*streamables, action:, target: nil, targets: nil, attributes: {}, **rendering)
    broadcast_stream_to(*streamables, content: turbo_stream_action_tag(
      action, target: target, targets: targets, template: render_broadcast_action(rendering), **attributes)
    )
  end

  def broadcast_replace_later_to(*streamables, **opts)
    broadcast_action_later_to(*streamables, action: :replace, **opts)
  end

  def broadcast_update_later_to(*streamables, **opts)
    broadcast_action_later_to(*streamables, action: :update, **opts)
  end

  def broadcast_before_later_to(*streamables, **opts)
    broadcast_action_later_to(*streamables, action: :before, **opts)
  end

  def broadcast_after_later_to(*streamables, **opts)
    broadcast_action_later_to(*streamables, action: :after, **opts)
  end

  def broadcast_append_later_to(*streamables, **opts)
    broadcast_action_later_to(*streamables, action: :append, **opts)
  end

  def broadcast_prepend_later_to(*streamables, **opts)
    broadcast_action_later_to(*streamables, action: :prepend, **opts)
  end

  def broadcast_refresh_later_to(*streamables, request_id: Turbo.current_request_id, **opts)
    stream_name = stream_name_from(streamables)

    refresh_debouncer_for(*streamables, request_id: request_id).debounce do
      Turbo::Streams::BroadcastStreamJob.perform_later stream_name, content: turbo_stream_refresh_tag(request_id: request_id, **opts).to_str # Sidekiq requires job arguments to be valid JSON types, such as String
    end
  end

  def broadcast_action_later_to(*streamables, action:, target: nil, targets: nil, attributes: {}, **rendering)
    streamables.flatten!
    streamables.compact_blank!

    if streamables.present?
      target = convert_to_turbo_stream_dom_id(target)
      targets = convert_to_turbo_stream_dom_id(targets, include_selector: true)
      Turbo::Streams::ActionBroadcastJob.perform_later \
        stream_name_from(streamables), action: action, target: target, targets: targets, attributes: attributes, **rendering
    end
  end

  def broadcast_render_to(*streamables, **rendering)
    broadcast_stream_to(*streamables, content: render_format(:turbo_stream, **rendering))
  end

  def broadcast_render_later_to(*streamables, **rendering)
    Turbo::Streams::BroadcastJob.perform_later stream_name_from(streamables), **rendering
  end

  def broadcast_stream_to(*streamables, content:)
    streamables.flatten!
    streamables.compact_blank!

    if streamables.present?
      ActionCable.server.broadcast stream_name_from(streamables), content
    end
  end

  def refresh_debouncer_for(*streamables, request_id: nil) # :nodoc:
    Turbo::ThreadDebouncer.for("turbo-refresh-debouncer-#{stream_name_from(streamables.including(request_id))}")
  end

  private
    def render_format(format, **rendering)
      ApplicationController.render(formats: [ format ], **rendering)
    end

    def render_broadcast_action(rendering)
      content = rendering.delete(:content)
      html    = rendering.delete(:html)
      render  = rendering.delete(:render)

      if render == false
        nil
      else
        content || html || (render_format(:html, **rendering) if rendering.present?)
      end
    end
end
