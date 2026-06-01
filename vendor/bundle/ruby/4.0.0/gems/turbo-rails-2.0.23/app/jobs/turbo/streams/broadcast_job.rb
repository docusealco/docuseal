# The job that powers the <tt>broadcast_render_later_to</tt> available in <tt>Turbo::Streams::Broadcasts</tt> for rendering
# turbo stream templates.
class Turbo::Streams::BroadcastJob < ActiveJob::Base
  discard_on ActiveJob::DeserializationError

  def perform(stream, **rendering)
    Turbo::StreamsChannel.broadcast_render_to stream, **rendering
  end
end
