# Turbo streams can be broadcasted directly from models that include this module (this is automatically done for Active Records if ActiveJob is loaded).
# This makes it convenient to execute both synchronous and asynchronous updates, and render directly from callbacks in models
# or from controllers or jobs that act on those models. Here's an example:
#
#   class Clearance < ApplicationRecord
#     belongs_to :petitioner, class_name: "Contact"
#     belongs_to :examiner,   class_name: "User"
#
#     after_create_commit :broadcast_later
#
#     private
#       def broadcast_later
#         broadcast_prepend_later_to examiner.identity, :clearances
#       end
#   end
#
# This is an example from {HEY}[https://hey.com], and the clearance is the model that drives
# {the screener}[https://hey.com/features/the-screener/], which gives users the power to deny first-time senders (petitioners)
# access to their attention (as the examiner). When a new clearance is created upon receipt of an email from a first-time
# sender, that'll trigger the call to broadcast_later, which in turn invokes <tt>broadcast_prepend_later_to</tt>.
#
# That method enqueues a <tt>Turbo::Streams::ActionBroadcastJob</tt> for the prepend, which will render the partial for clearance
# (it knows which by calling Clearance#to_partial_path, which in this case returns <tt>clearances/_clearance.html.erb</tt>),
# send that to all users that have subscribed to updates (using <tt>turbo_stream_from(examiner.identity, :clearances)</tt> in a view)
# using the <tt>Turbo::StreamsChannel</tt> under the stream name derived from <tt>[ examiner.identity, :clearances ]</tt>,
# and finally prepend the result of that partial rendering to the target identified with the dom id "clearances"
# (which is derived by default from the plural model name of the model, but can be overwritten).
#
# You can also choose to render html instead of a partial inside of a broadcast
# you do this by passing the +html:+ option to any broadcast method that accepts the **rendering argument. Example:
#
#   class Message < ApplicationRecord
#     belongs_to :user
#
#     after_create_commit :update_message_count
#
#     private
#       def update_message_count
#         broadcast_update_to(user, :messages, target: "message-count", html: "<p> #{user.messages.count} </p>")
#       end
#   end
#
# If you want to render a template instead of a partial, e.g. ('messages/index' or 'messages/show'), you can use the +template:+ option.
# Again, only to any broadcast method that accepts the +**rendering+ argument. Example:
#
#   class Message < ApplicationRecord
#     belongs_to :user
#
#     after_create_commit :update_message
#
#     private
#       def update_message
#         broadcast_replace_to(user, :message, target: "message", template: "messages/show", locals: { message: self })
#       end
#   end
#
# If you want to render a renderable object you can use the +renderable:+ option.
#
#   class Message < ApplicationRecord
#     belongs_to :user
#
#     after_create_commit :update_message
#
#     private
#       def update_message
#         broadcast_replace_to(user, :message, target: "message", renderable: MessageComponent.new)
#       end
#   end
#
# There are seven basic actions you can broadcast: <tt>after</tt>, <tt>append</tt>, <tt>before</tt>,
# <tt>prepend</tt>, <tt>remove</tt>, <tt>replace</tt>, and
# <tt>update</tt>. As a rule, you should use the <tt>_later</tt> versions of everything except for remove when broadcasting
# within a real-time path, like a controller or model, since all those updates require a rendering step, which can slow down
# execution. You don't need to do this for remove, since only the dom id for the model is used.
#
# In addition to the seven basic actions, you can also use <tt>broadcast_render</tt>,
# <tt>broadcast_render_to</tt> <tt>broadcast_render_later</tt>, and <tt>broadcast_render_later_to</tt>
# to render a turbo stream template with multiple actions.
#
# == Page refreshes
#
# You can broadcast "page refresh" stream actions. This will make subscribed clients reload the
# page. For pages that configure morphing and scroll preservation, this will translate into smooth
# updates when it only updates the content that changed.
#
# This approach is an alternative to fine-grained stream actions targeting specific DOM elements. It
# offers good fidelity with a much simpler programming model. As a tradeoff, the fidelity you can reach
# is often not as high as with targeted stream actions since it renders the entire page again.
#
# The +broadcasts_refreshes+ class method configures the model to broadcast a "page refresh" on creates,
# updates, and destroys to a stream name derived at runtime by the <tt>stream</tt> symbol invocation. Examples
#
#   class Board < ApplicationRecord
#     broadcasts_refreshes
#   end
#
# In this example, when a board is created, updated, or destroyed, a Turbo Stream for a
# page refresh will be broadcasted to all clients subscribed to the "boards" stream.
#
# This works great in hierarchical structures, where the child record touches parent records automatically
# to invalidate the cache:
#
#   class Column < ApplicationRecord
#     belongs_to :board, touch: true # +Board+ will trigger a page refresh on column changes
#   end
#
# You can also specify the streamable declaratively by passing a symbol to the +broadcasts_refreshes_to+ method:
#
#   class Column < ApplicationRecord
#     belongs_to :board
#     broadcasts_refreshes_to :board
#   end
#
# For more granular control, you can also broadcast a "page refresh" to a stream name derived
# from the passed <tt>streamables</tt> by using the instance-level methods <tt>broadcast_refresh_to</tt> or
# <tt>broadcast_refresh_later_to</tt>. These methods are particularly useful when you want to trigger
# a page refresh for more specific scenarios. Example:
#
#   class Clearance < ApplicationRecord
#     belongs_to :petitioner, class_name: "Contact"
#     belongs_to :examiner,   class_name: "User"
#
#     after_create_commit :broadcast_refresh_later
#
#     private
#       def broadcast_refresh_later
#         broadcast_refresh_later_to examiner.identity, :clearances
#       end
#   end
#
# In this example, a "page refresh" is broadcast to the stream named "identity:<identity-id>:clearances"
# after a new clearance is created. All clients subscribed to this stream will refresh the page to reflect
# the changes.
#
# When broadcasting page refreshes, Turbo will automatically debounce multiple calls in a row to only broadcast the last one.
# This is meant for scenarios where you process records in mass. Because of the nature of such signals, it makes no sense to
# broadcast them repeatedly and individually.
# == Suppressing broadcasts
#
# Sometimes, you need to disable broadcasts in certain scenarios. You can use <tt>.suppressing_turbo_broadcasts</tt> to create
# execution contexts where broadcasts are disabled:
#
#   class Message < ApplicationRecord
#     after_create_commit :update_message
#
#     private
#       def update_message
#         broadcast_replace_to(user, :message, target: "message", renderable: MessageComponent.new)
#       end
#   end
#
#   Message.suppressing_turbo_broadcasts do
#     Message.create!(board: board) # This won't broadcast the replace action
#   end
module Turbo::Broadcastable
  extend ActiveSupport::Concern

  included do
    thread_mattr_accessor :suppressed_turbo_broadcasts, instance_accessor: false
    delegate :suppressed_turbo_broadcasts?, to: "self.class"
  end

  module ClassMethods
    # Configures the model to broadcast creates, updates, and destroys to a stream name derived at runtime by the
    # <tt>stream</tt> symbol invocation. By default, the creates are appended to a dom id target name derived from
    # the model's plural name. The insertion can also be made to be a prepend by overwriting <tt>inserts_by</tt> and
    # the target dom id overwritten by passing <tt>target</tt>. Examples:
    #
    #   class Message < ApplicationRecord
    #     belongs_to :board
    #     broadcasts_to :board
    #   end
    #
    #   class Message < ApplicationRecord
    #     belongs_to :board
    #     broadcasts_to ->(message) { [ message.board, :messages ] }, inserts_by: :prepend, target: "board_messages"
    #   end
    #
    #   class Message < ApplicationRecord
    #     belongs_to :board
    #     broadcasts_to ->(message) { [ message.board, :messages ] }, partial: "messages/custom_message"
    #   end
    def broadcasts_to(stream, inserts_by: :append, target: broadcast_target_default, **rendering)
      after_create_commit  -> { broadcast_action_later_to(stream.try(:call, self) || send(stream), action: inserts_by, target: target.try(:call, self) || target, **rendering) }
      after_update_commit  -> { broadcast_replace_later_to(stream.try(:call, self) || send(stream), **rendering) }
      after_destroy_commit -> { broadcast_remove_to(stream.try(:call, self) || send(stream)) }
    end

    # Same as <tt>#broadcasts_to</tt>, but the designated stream for updates and destroys is automatically set to
    # the current model, for creates - to the model plural name, which can be overriden by passing <tt>stream</tt>.
    def broadcasts(stream = model_name.plural, inserts_by: :append, target: broadcast_target_default, **rendering)
      after_create_commit  -> { broadcast_action_later_to(stream, action: inserts_by, target: target.try(:call, self) || target, **rendering) }
      after_update_commit  -> { broadcast_replace_later(**rendering) }
      after_destroy_commit -> { broadcast_remove }
    end

    # Configures the model to broadcast a "page refresh" on creates, updates, and destroys to a stream
    # name derived at runtime by the <tt>stream</tt> symbol invocation. Examples:
    #
    #   class Message < ApplicationRecord
    #     belongs_to :board
    #     broadcasts_refreshes_to :board
    #   end
    #
    #   class Message < ApplicationRecord
    #     belongs_to :board
    #     broadcasts_refreshes_to ->(message) { [ message.board, :messages ] }
    #   end
    def broadcasts_refreshes_to(stream)
      after_commit -> { broadcast_refresh_later_to(stream.try(:call, self) || send(stream)) }
    end

    # Same as <tt>#broadcasts_refreshes_to</tt>, but the designated stream for page refreshes is automatically set to
    # the current model, for creates - to the model plural name, which can be overriden by passing <tt>stream</tt>.
    def broadcasts_refreshes(stream = model_name.plural)
      after_create_commit  -> { broadcast_refresh_later_to(stream) }
      after_update_commit  -> { broadcast_refresh_later }
      after_destroy_commit -> { broadcast_refresh }
    end

    # All default targets will use the return of this method. Overwrite if you want something else than <tt>model_name.plural</tt>.
    def broadcast_target_default
      model_name.plural
    end

    # Executes +block+ preventing both synchronous and asynchronous broadcasts from this model.
    def suppressing_turbo_broadcasts(&block)
      original, self.suppressed_turbo_broadcasts = self.suppressed_turbo_broadcasts, true
      yield
    ensure
      self.suppressed_turbo_broadcasts = original
    end

    def suppressed_turbo_broadcasts?
      suppressed_turbo_broadcasts
    end
  end

  # Remove this broadcastable model from the dom for subscribers of the stream name identified by the passed streamables.
  # Example:
  #
  #   # Sends <turbo-stream action="remove" target="clearance_5"></turbo-stream> to the stream named "identity:2:clearances"
  #   clearance.broadcast_remove_to examiner.identity, :clearances
  def broadcast_remove_to(*streamables, target: self, **rendering)
    Turbo::StreamsChannel.broadcast_remove_to(*streamables, **extract_options_and_add_target(rendering, target: target)) unless suppressed_turbo_broadcasts?
  end

  # Same as <tt>#broadcast_remove_to</tt>, but the designated stream is automatically set to the current model.
  def broadcast_remove(**rendering)
    broadcast_remove_to self, **rendering
  end

  # Replace this broadcastable model in the dom for subscribers of the stream name identified by the passed
  # <tt>streamables</tt>. The rendering parameters can be set by appending named arguments to the call. Examples:
  #
  #   # Sends <turbo-stream action="replace" target="clearance_5"><template><div id="clearance_5">My Clearance</div></template></turbo-stream>
  #   # to the stream named "identity:2:clearances"
  #   clearance.broadcast_replace_to examiner.identity, :clearances
  #
  #   # Sends <turbo-stream action="replace" target="clearance_5"><template><div id="clearance_5">Other partial</div></template></turbo-stream>
  #   # to the stream named "identity:2:clearances"
  #   clearance.broadcast_replace_to examiner.identity, :clearances, partial: "clearances/other_partial", locals: { a: 1 }
  #
  #   # Sends <turbo-stream action="replace" method="morph" target="clearance_5"><template><div id="clearance_5">Other partial</div></template></turbo-stream>
  #   # to the stream named "identity:2:clearances"
  #   clearance.broadcast_replace_to examiner.identity, :clearance, attributes: { method: :morph }, partial: "clearances/other_partial", locals: { a: 1 }
  def broadcast_replace_to(*streamables, **rendering)
    Turbo::StreamsChannel.broadcast_replace_to(*streamables, **extract_options_and_add_target(rendering, target: self)) unless suppressed_turbo_broadcasts?
  end

  # Same as <tt>#broadcast_replace_to</tt>, but the designated stream is automatically set to the current model.
  def broadcast_replace(**rendering)
    broadcast_replace_to self, **rendering
  end

  # Update this broadcastable model in the dom for subscribers of the stream name identified by the passed
  # <tt>streamables</tt>. The rendering parameters can be set by appending named arguments to the call. Examples:
  #
  #   # Sends <turbo-stream action="update" target="clearance_5"><template><div id="clearance_5">My Clearance</div></template></turbo-stream>
  #   # to the stream named "identity:2:clearances"
  #   clearance.broadcast_update_to examiner.identity, :clearances
  #
  #   # Sends <turbo-stream action="update" target="clearance_5"><template><div id="clearance_5">Other partial</div></template></turbo-stream>
  #   # to the stream named "identity:2:clearances"
  #   clearance.broadcast_update_to examiner.identity, :clearances, partial: "clearances/other_partial", locals: { a: 1 }
  #
  #   # sends <turbo-stream action="update" method="morph" target="clearance_5"><template><div id="clearance_5">Other partial</div></template></turbo-stream>
  #   # to the stream named "identity:2:clearances"
  #   clearance.broadcast_update_to examiner.identity, :clearances, attributes: { method: :morph }, partial: "clearances/other_partial", locals: { a: 1 }
  def broadcast_update_to(*streamables, **rendering)
    Turbo::StreamsChannel.broadcast_update_to(*streamables, **extract_options_and_add_target(rendering, target: self)) unless suppressed_turbo_broadcasts?
  end

  # Same as <tt>#broadcast_update_to</tt>, but the designated stream is automatically set to the current model.
  def broadcast_update(**rendering)
    broadcast_update_to self, **rendering
  end

  # Insert a rendering of this broadcastable model before the target identified by it's dom id passed as <tt>target</tt>
  # for subscribers of the stream name identified by the passed <tt>streamables</tt>. The rendering parameters can be set by
  # appending named arguments to the call. Examples:
  #
  #   # Sends <turbo-stream action="before" target="clearance_5"><template><div id="clearance_4">My Clearance</div></template></turbo-stream>
  #   # to the stream named "identity:2:clearances"
  #   clearance.broadcast_before_to examiner.identity, :clearances, target: "clearance_5"
  #
  #   # Sends <turbo-stream action="before" target="clearance_5"><template><div id="clearance_4">Other partial</div></template></turbo-stream>
  #   # to the stream named "identity:2:clearances"
  #   clearance.broadcast_before_to examiner.identity, :clearances, target: "clearance_5",
  #     partial: "clearances/other_partial", locals: { a: 1 }
  def broadcast_before_to(*streamables, target: nil, targets: nil, **rendering)
    raise ArgumentError, "at least one of target or targets is required" unless target || targets

    Turbo::StreamsChannel.broadcast_before_to(*streamables, **extract_options_and_add_target(rendering.merge(target: target, targets: targets))) unless suppressed_turbo_broadcasts?
  end

  # Insert a rendering of this broadcastable model after the target identified by it's dom id passed as <tt>target</tt>
  # for subscribers of the stream name identified by the passed <tt>streamables</tt>. The rendering parameters can be set by
  # appending named arguments to the call. Examples:
  #
  #   # Sends <turbo-stream action="after" target="clearance_5"><template><div id="clearance_6">My Clearance</div></template></turbo-stream>
  #   # to the stream named "identity:2:clearances"
  #   clearance.broadcast_after_to examiner.identity, :clearances, target: "clearance_5"
  #
  #   # Sends <turbo-stream action="after" target="clearance_5"><template><div id="clearance_6">Other partial</div></template></turbo-stream>
  #   # to the stream named "identity:2:clearances"
  #   clearance.broadcast_after_to examiner.identity, :clearances, target: "clearance_5",
  #     partial: "clearances/other_partial", locals: { a: 1 }
  def broadcast_after_to(*streamables, target: nil, targets: nil, **rendering)
    raise ArgumentError, "at least one of target or targets is required" unless target || targets

    Turbo::StreamsChannel.broadcast_after_to(*streamables, **extract_options_and_add_target(rendering.merge(target: target, targets: targets))) unless suppressed_turbo_broadcasts?
  end

  # Append a rendering of this broadcastable model to the target identified by it's dom id passed as <tt>target</tt>
  # for subscribers of the stream name identified by the passed <tt>streamables</tt>. The rendering parameters can be set by
  # appending named arguments to the call. Examples:
  #
  #   # Sends <turbo-stream action="append" target="clearances"><template><div id="clearance_5">My Clearance</div></template></turbo-stream>
  #   # to the stream named "identity:2:clearances"
  #   clearance.broadcast_append_to examiner.identity, :clearances, target: "clearances"
  #
  #   # Sends <turbo-stream action="append" target="clearances"><template><div id="clearance_5">Other partial</div></template></turbo-stream>
  #   # to the stream named "identity:2:clearances"
  #   clearance.broadcast_append_to examiner.identity, :clearances, target: "clearances",
  #     partial: "clearances/other_partial", locals: { a: 1 }
  def broadcast_append_to(*streamables, target: broadcast_target_default, **rendering)
    Turbo::StreamsChannel.broadcast_append_to(*streamables, **extract_options_and_add_target(rendering, target: target)) unless suppressed_turbo_broadcasts?
  end

  # Same as <tt>#broadcast_append_to</tt>, but the designated stream is automatically set to the current model.
  def broadcast_append(target: broadcast_target_default, **rendering)
    broadcast_append_to self, target: target, **rendering
  end

  # Prepend a rendering of this broadcastable model to the target identified by it's dom id passed as <tt>target</tt>
  # for subscribers of the stream name identified by the passed <tt>streamables</tt>. The rendering parameters can be set by
  # appending named arguments to the call. Examples:
  #
  #   # Sends <turbo-stream action="prepend" target="clearances"><template><div id="clearance_5">My Clearance</div></template></turbo-stream>
  #   # to the stream named "identity:2:clearances"
  #   clearance.broadcast_prepend_to examiner.identity, :clearances, target: "clearances"
  #
  #   # Sends <turbo-stream action="prepend" target="clearances"><template><div id="clearance_5">Other partial</div></template></turbo-stream>
  #   # to the stream named "identity:2:clearances"
  #   clearance.broadcast_prepend_to examiner.identity, :clearances, target: "clearances",
  #     partial: "clearances/other_partial", locals: { a: 1 }
  def broadcast_prepend_to(*streamables, target: broadcast_target_default, **rendering)
    Turbo::StreamsChannel.broadcast_prepend_to(*streamables, **extract_options_and_add_target(rendering, target: target)) unless suppressed_turbo_broadcasts?
  end

  # Same as <tt>#broadcast_prepend_to</tt>, but the designated stream is automatically set to the current model.
  def broadcast_prepend(target: broadcast_target_default, **rendering)
    broadcast_prepend_to self, target: target, **rendering
  end

  #  Broadcast a "page refresh" to the stream name identified by the passed <tt>streamables</tt>. Example:
  #
  #   # Sends <turbo-stream action="refresh"></turbo-stream> to the stream named "identity:2:clearances"
  #   clearance.broadcast_refresh_to examiner.identity, :clearances
  def broadcast_refresh_to(*streamables, **attributes)
    Turbo::StreamsChannel.broadcast_refresh_to(*streamables, **attributes) unless suppressed_turbo_broadcasts?
  end

  #  Same as <tt>#broadcast_refresh_to</tt>, but the designated stream is automatically set to the current model.
  def broadcast_refresh
    broadcast_refresh_to self
  end

  # Broadcast a named <tt>action</tt>, allowing for dynamic dispatch, instead of using the concrete action methods. Examples:
  #
  #   # Sends <turbo-stream action="prepend" target="clearances"><template><div id="clearance_5">My Clearance</div></template></turbo-stream>
  #   # to the stream named "identity:2:clearances"
  #   clearance.broadcast_action_to examiner.identity, :clearances, action: :prepend, target: "clearances"
  def broadcast_action_to(*streamables, action:, target: broadcast_target_default, attributes: {}, **rendering)
    Turbo::StreamsChannel.broadcast_action_to(*streamables, action: action, attributes: attributes, **extract_options_and_add_target(rendering, target: target)) unless suppressed_turbo_broadcasts?
  end

  # Same as <tt>#broadcast_action_to</tt>, but the designated stream is automatically set to the current model.
  def broadcast_action(action, target: broadcast_target_default, attributes: {}, **rendering)
    broadcast_action_to self, action: action, target: target, attributes: attributes, **rendering
  end

  # Same as <tt>broadcast_replace_to</tt> but run asynchronously via a <tt>Turbo::Streams::BroadcastJob</tt>.
  def broadcast_replace_later_to(*streamables, **rendering)
    Turbo::StreamsChannel.broadcast_replace_later_to(*streamables, **extract_options_and_add_target(rendering, target: self)) unless suppressed_turbo_broadcasts?
  end

  # Same as <tt>#broadcast_replace_later_to</tt>, but the designated stream is automatically set to the current model.
  def broadcast_replace_later(**rendering)
    broadcast_replace_later_to self, **rendering
  end

  # Same as <tt>broadcast_update_to</tt> but run asynchronously via a <tt>Turbo::Streams::BroadcastJob</tt>.
  def broadcast_update_later_to(*streamables, **rendering)
    Turbo::StreamsChannel.broadcast_update_later_to(*streamables, **extract_options_and_add_target(rendering, target: self)) unless suppressed_turbo_broadcasts?
  end

  # Same as <tt>#broadcast_update_later_to</tt>, but the designated stream is automatically set to the current model.
  def broadcast_update_later(**rendering)
    broadcast_update_later_to self, **rendering
  end

  # Same as <tt>broadcast_append_to</tt> but run asynchronously via a <tt>Turbo::Streams::BroadcastJob</tt>.
  def broadcast_append_later_to(*streamables, target: broadcast_target_default, **rendering)
    Turbo::StreamsChannel.broadcast_append_later_to(*streamables, **extract_options_and_add_target(rendering, target: target)) unless suppressed_turbo_broadcasts?
  end

  # Same as <tt>#broadcast_append_later_to</tt>, but the designated stream is automatically set to the current model.
  def broadcast_append_later(target: broadcast_target_default, **rendering)
    broadcast_append_later_to self, target: target, **rendering
  end

  # Same as <tt>broadcast_prepend_to</tt> but run asynchronously via a <tt>Turbo::Streams::BroadcastJob</tt>.
  def broadcast_prepend_later_to(*streamables, target: broadcast_target_default, **rendering)
    Turbo::StreamsChannel.broadcast_prepend_later_to(*streamables, **extract_options_and_add_target(rendering, target: target)) unless suppressed_turbo_broadcasts?
  end

  # Same as <tt>#broadcast_prepend_later_to</tt>, but the designated stream is automatically set to the current model.
  def broadcast_prepend_later(target: broadcast_target_default, **rendering)
    broadcast_prepend_later_to self, target: target, **rendering
  end

  #  Same as <tt>broadcast_refresh_to</tt> but run asynchronously via a <tt>Turbo::Streams::BroadcastJob</tt>.
  def broadcast_refresh_later_to(*streamables, **attributes)
    Turbo::StreamsChannel.broadcast_refresh_later_to(*streamables, request_id: Turbo.current_request_id, **attributes) unless suppressed_turbo_broadcasts?
  end

  #  Same as <tt>#broadcast_refresh_later_to</tt>, but the designated stream is automatically set to the current model.
  def broadcast_refresh_later
    broadcast_refresh_later_to self
  end

  # Same as <tt>broadcast_action_to</tt> but run asynchronously via a <tt>Turbo::Streams::BroadcastJob</tt>.
  def broadcast_action_later_to(*streamables, action:, target: broadcast_target_default, attributes: {}, **rendering)
    Turbo::StreamsChannel.broadcast_action_later_to(*streamables, action: action, attributes: attributes, **extract_options_and_add_target(rendering, target: target)) unless suppressed_turbo_broadcasts?
  end

  # Same as <tt>#broadcast_action_later_to</tt>, but the designated stream is automatically set to the current model.
  def broadcast_action_later(action:, target: broadcast_target_default, attributes: {}, **rendering)
    broadcast_action_later_to self, action: action, target: target, attributes: attributes, **rendering
  end

  # Render a turbo stream template with this broadcastable model passed as the local variable. Example:
  #
  #   # Template: entries/_entry.turbo_stream.erb
  #   <%= turbo_stream.remove entry %>
  #
  #   <%= turbo_stream.append "entries", entry if entry.active? %>
  #
  # Sends:
  #
  #   <turbo-stream action="remove" target="entry_5"></turbo-stream>
  #   <turbo-stream action="append" target="entries"><template><div id="entry_5">My Entry</div></template></turbo-stream>
  #
  # ...to the stream named "entry:5".
  #
  # Note that rendering inline via this method will cause template rendering to happen synchronously. That is usually not
  # desireable for model callbacks, certainly not if those callbacks are inside of a transaction. Most of the time you should
  # be using +broadcast_render_later+, unless you specifically know why synchronous rendering is needed.
  def broadcast_render(**rendering)
    broadcast_render_to self, **rendering
  end

  # Same as <tt>broadcast_render</tt> but run with the added option of naming the stream using the passed
  # <tt>streamables</tt>.
  #
  # Note that rendering inline via this method will cause template rendering to happen synchronously. That is usually not
  # desireable for model callbacks, certainly not if those callbacks are inside of a transaction. Most of the time you should
  # be using +broadcast_render_later_to+, unless you specifically know why synchronous rendering is needed.
  def broadcast_render_to(*streamables, **rendering)
    Turbo::StreamsChannel.broadcast_render_to(*streamables, **extract_options_and_add_target(rendering, target: self)) unless suppressed_turbo_broadcasts?
  end

  # Same as <tt>broadcast_render_to</tt> but run asynchronously via a <tt>Turbo::Streams::BroadcastJob</tt>.
  def broadcast_render_later(**rendering)
    broadcast_render_later_to self, **rendering
  end

  # Same as <tt>broadcast_render_later</tt> but run with the added option of naming the stream using the passed
  # <tt>streamables</tt>.
  def broadcast_render_later_to(*streamables, **rendering)
    Turbo::StreamsChannel.broadcast_render_later_to(*streamables, **extract_options_and_add_target(rendering)) unless suppressed_turbo_broadcasts?
  end

  private
    def broadcast_target_default
      self.class.broadcast_target_default
    end

    def extract_options_and_add_target(rendering = {}, target: broadcast_target_default)
      broadcast_rendering_with_defaults(rendering).tap do |options|
        options[:target] = target if !options.key?(:target) && !options.key?(:targets)
      end
    end

    def broadcast_rendering_with_defaults(options)
      options.tap do |o|
        # Add the current instance into the locals with the element name (which is the un-namespaced name)
        # as the key. This parallels how the ActionView::ObjectRenderer would create a local variable.
        o[:locals] = (o[:locals] || {}).reverse_merge(model_name.element.to_sym => self)

        if o[:html] || o[:partial]
          return o
        elsif o[:template] || o[:renderable]
          o[:layout] = false
        elsif o[:render] == false
          return o
        else
          # if none of these options are passed in, it will set a partial from #to_partial_path
          o[:partial] ||= to_partial_path
        end
      end
    end
end
