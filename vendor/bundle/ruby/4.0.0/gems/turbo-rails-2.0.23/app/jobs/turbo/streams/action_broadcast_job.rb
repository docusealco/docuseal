# The job that powers all the <tt>broadcast_$action_later</tt> broadcasts available in <tt>Turbo::Streams::Broadcasts</tt>.
class Turbo::Streams::ActionBroadcastJob < ActiveJob::Base
  discard_on ActiveJob::DeserializationError
  
  def perform(stream, action:, target:, attributes: {}, **rendering)
    Turbo::StreamsChannel.broadcast_action_to stream, action: action, target: target, attributes: attributes, **rendering
  end
end
