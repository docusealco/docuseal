class Turbo::Streams::BroadcastStreamJob < ActiveJob::Base
  discard_on ActiveJob::DeserializationError

  def perform(stream, content:)
    Turbo::StreamsChannel.broadcast_stream_to(stream, content: content)
  end
end
