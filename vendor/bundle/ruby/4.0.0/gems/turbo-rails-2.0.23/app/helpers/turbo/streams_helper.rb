module Turbo::StreamsHelper
  # Returns a new <tt>Turbo::Streams::TagBuilder</tt> object that accepts stream actions and renders them as
  # the template tags needed to send across the wire. This object is automatically yielded to turbo_stream.erb templates.
  #
  # When responding to HTTP requests, controllers can declare `turbo_stream` format response templates in that same
  # style as `html` and `json` response formats. For example, consider a `MessagesController` that responds to both
  # `text/html` and `text/vnd.turbo-stream.html` requests along with a `.turbo_stream.erb` action template:
  #
  #   def create
  #     @message = Message.create!(params.require(:message).permit(:content))
  #     respond_to do |format|
  #       format.turbo_stream
  #       format.html { redirect_to messages_url }
  #     end
  #   end
  #
  #   <%# app/views/messages/create.turbo_stream.erb %>
  #   <%= turbo_stream.append "messages", @message %>
  #
  #   <%= turbo_stream.replace "new_message" do %>
  #     <%= render partial: "new_message", locals: { room: @room } %>
  #   <% end %>
  #
  # When a `app/views/messages/create.turbo_stream.erb` template exists, the
  # `MessagesController#create` will respond to `text/vnd.turbo-stream.html`
  # requests by rendering the `messages/create.turbo_stream.erb` view template and transmitting the response
  def turbo_stream
    Turbo::Streams::TagBuilder.new(self)
  end

  # Used in the view to create a subscription to a stream identified by the <tt>streamables</tt> running over the
  # <tt>Turbo::StreamsChannel</tt>. The stream name being generated is safe to embed in the HTML sent to a user without
  # fear of tampering, as it is signed using <tt>Turbo.signed_stream_verifier</tt>. Example:
  #
  #   # app/views/entries/index.html.erb
  #   <%= turbo_stream_from Current.account, :entries %>
  #   <div id="entries">New entries will be appended to this target</div>
  #
  # The example above will process all turbo streams sent to a stream name like <tt>account:5:entries</tt>
  # (when Current.account.id = 5). Updates to this stream can be sent like
  # <tt>entry.broadcast_append_to entry.account, :entries, target: "entries"</tt>.
  #
  # Custom channel class name can be passed using <tt>:channel</tt> option (either as a String
  # or a class name):
  #
  #   <%= turbo_stream_from "room", channel: RoomChannel %>
  #
  # It is also possible to pass additional parameters to the channel by passing them through `data` attributes:
  #
  #   <%= turbo_stream_from "room", channel: RoomChannel, data: {room_name: "room #1"} %>
  #
  # Raises an +ArgumentError+ if all streamables are blank
  #
  #   <%= turbo_stream_from("") %> # => ArgumentError: streamables can't be blank
  #   <%= turbo_stream_from("", nil) %> # => ArgumentError: streamables can't be blank
  def turbo_stream_from(*streamables, **attributes)
    raise ArgumentError, "streamables can't be blank" unless streamables.any?(&:present?)
    attributes[:channel] = attributes[:channel]&.to_s || "Turbo::StreamsChannel"
    attributes[:"signed-stream-name"] = Turbo::StreamsChannel.signed_stream_name(streamables)

    tag.turbo_cable_stream_source(**attributes)
  end
end
