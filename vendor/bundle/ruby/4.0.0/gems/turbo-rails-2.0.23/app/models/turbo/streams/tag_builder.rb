# This tag builder is used both for inline controller turbo actions (see <tt>Turbo::Streams::TurboStreamsTagBuilder</tt>) and for
# turbo stream templates. This object plays together with any normal Ruby you'd run in an ERB template, so you can iterate, like:
#
#   <% # app/views/postings/destroy.turbo_stream.erb %>
#   <% @postings.each do |posting| %>
#     <%= turbo_stream.remove posting %>
#   <% end %>
#
# Or string several separate updates together:
#
#   <% # app/views/entries/_entry.turbo_stream.erb %>
#   <%= turbo_stream.remove entry %>
#
#   <%= turbo_stream.append "entries" do %>
#     <% # format is automatically switched, such that _entry.html.erb partial is rendered, not _entry.turbo_stream.erb %>
#     <%= render partial: "entries/entry", locals: { entry: entry } %>
#   <% end %>
#
# Or you can render the HTML that should be part of the update inline:
#
#   <% # app/views/topics/merges/_merge.turbo_stream.erb %>
#   <%= turbo_stream.append dom_id(topic_merge) do %>
#     <%= link_to topic_merge.topic.name, topic_path(topic_merge.topic) %>
#   <% end %>
#
# To integrate with custom actions, extend this class in response to the :turbo_streams_tag_builder load hook:
#
#   ActiveSupport.on_load :turbo_streams_tag_builder do
#     def highlight(target)
#       action :highlight, target
#     end
#
#     def highlight_all(targets)
#       action_all :highlight, targets
#     end
#   end
#
#   turbo_stream.highlight "my-element"
#   # => <turbo-stream action="highlight" target="my-element"><template></template></turbo-stream>
#
#   turbo_stream.highlight_all ".my-selector"
#   # => <turbo-stream action="highlight" targets=".my-selector"><template></template></turbo-stream>
class Turbo::Streams::TagBuilder
  include Turbo::Streams::ActionHelper

  def initialize(view_context)
    @view_context = view_context
    @view_context.formats |= [:html]
  end

  # Removes the <tt>target</tt> from the dom. The target can either be a dom id string or an object that responds to
  # <tt>to_key</tt>, which is then called and passed through <tt>ActionView::RecordIdentifier.dom_id</tt> (all Active Records
  # do). Examples:
  #
  #   <%= turbo_stream.remove "clearance_5" %>
  #   <%= turbo_stream.remove clearance %>
  def remove(target)
    action :remove, target, allow_inferred_rendering: false
  end

  # Removes the <tt>targets</tt> from the dom. The targets can either be a CSS selector string or an object that responds to
  # <tt>to_key</tt>, which is then called and passed through <tt>ActionView::RecordIdentifier.dom_id</tt> (all Active Records
  # do). Examples:
  #
  #   <%= turbo_stream.remove_all ".clearance_item" %>
  #   <%= turbo_stream.remove_all clearance %>
  def remove_all(targets)
    action_all :remove, targets, allow_inferred_rendering: false
  end

  # Replace the <tt>target</tt> in the dom with either the <tt>content</tt> passed in, a rendering result determined
  # by the <tt>rendering</tt> keyword arguments, the content in the block, or the rendering of the target as a record. Examples:
  #
  #   <%= turbo_stream.replace "clearance_5", "<div id='clearance_5'>Replace the dom target identified by clearance_5</div>" %>
  #   <%= turbo_stream.replace clearance %>
  #   <%= turbo_stream.replace clearance, partial: "clearances/clearance", locals: { title: "Hello" } %>
  #   <%= turbo_stream.replace "clearance_5" do %>
  #     <div id='clearance_5'>Replace the dom target identified by clearance_5</div>
  #   <% end %>
  #   <%= turbo_stream.replace clearance, "<div>Morph the dom target</div>", method: :morph %>
  def replace(target, content = nil, method: nil, **rendering, &block)
    action :replace, target, content, method: method, **rendering, &block
  end

  # Replace the <tt>targets</tt> in the dom with either the <tt>content</tt> passed in, a rendering result determined
  # by the <tt>rendering</tt> keyword arguments, the content in the block, or the rendering of the target as a record. Examples:
  #
  #   <%= turbo_stream.replace_all ".clearance_item", "<div class='clearance_item'>Replace the dom target identified by the class clearance_item</div>" %>
  #   <%= turbo_stream.replace_all clearance %>
  #   <%= turbo_stream.replace_all clearance, partial: "clearances/clearance", locals: { title: "Hello" } %>
  #   <%= turbo_stream.replace_all ".clearance_item" do %>
  #     <div class='.clearance_item'>Replace the dom target identified by the class clearance_item</div>
  #   <% end %>
  #   <%= turbo_stream.replace_all clearance, "<div>Morph the dom target</div>", method: :morph %>
  def replace_all(targets, content = nil, method: nil, **rendering, &block)
    action_all :replace, targets, content, method: method, **rendering, &block
  end

  # Insert the <tt>content</tt> passed in, a rendering result determined by the <tt>rendering</tt> keyword arguments,
  # the content in the block, or the rendering of the target as a record before the <tt>target</tt> in the dom. Examples:
  #
  #   <%= turbo_stream.before "clearance_5", "<div id='clearance_4'>Insert before the dom target identified by clearance_5</div>" %>
  #   <%= turbo_stream.before clearance %>
  #   <%= turbo_stream.before clearance, partial: "clearances/clearance", locals: { title: "Hello" } %>
  #   <%= turbo_stream.before "clearance_5" do %>
  #     <div id='clearance_4'>Insert before the dom target identified by clearance_5</div>
  #   <% end %>
  def before(target, content = nil, **rendering, &block)
    action :before, target, content, **rendering, &block
  end

  # Insert the <tt>content</tt> passed in, a rendering result determined by the <tt>rendering</tt> keyword arguments,
  # the content in the block, or the rendering of the target as a record before the <tt>targets</tt> in the dom. Examples:
  #
  #   <%= turbo_stream.before_all ".clearance_item", "<div class='clearance_item'>Insert before the dom target identified by the class clearance_item</div>" %>
  #   <%= turbo_stream.before_all clearance %>
  #   <%= turbo_stream.before_all clearance, partial: "clearances/clearance", locals: { title: "Hello" } %>
  #   <%= turbo_stream.before_all ".clearance_item" do %>
  #     <div class='clearance_item'>Insert before the dom target identified by clearance_item</div>
  #   <% end %>
  def before_all(targets, content = nil, **rendering, &block)
    action_all :before, targets, content, **rendering, &block
  end

  # Insert the <tt>content</tt> passed in, a rendering result determined by the <tt>rendering</tt> keyword arguments,
  # the content in the block, or the rendering of the target as a record after the <tt>target</tt> in the dom. Examples:
  #
  #   <%= turbo_stream.after "clearance_5", "<div id='clearance_6'>Insert after the dom target identified by clearance_5</div>" %>
  #   <%= turbo_stream.after clearance %>
  #   <%= turbo_stream.after clearance, partial: "clearances/clearance", locals: { title: "Hello" } %>
  #   <%= turbo_stream.after "clearance_5" do %>
  #     <div id='clearance_6'>Insert after the dom target identified by clearance_5</div>
  #   <% end %>
  def after(target, content = nil, **rendering, &block)
    action :after, target, content, **rendering, &block
  end

  # Insert the <tt>content</tt> passed in, a rendering result determined by the <tt>rendering</tt> keyword arguments,
  # the content in the block, or the rendering of the target as a record after the <tt>targets</tt> in the dom. Examples:
  #
  #   <%= turbo_stream.after_all ".clearance_item", "<div class='clearance_item'>Insert after the dom target identified by the class clearance_item</div>" %>
  #   <%= turbo_stream.after_all clearance %>
  #   <%= turbo_stream.after_all clearance, partial: "clearances/clearance", locals: { title: "Hello" } %>
  #   <%= turbo_stream.after_all "clearance_item" do %>
  #     <div class='clearance_item'>Insert after the dom target identified by the class clearance_item</div>
  #   <% end %>
  def after_all(targets, content = nil, **rendering, &block)
    action_all :after, targets, content, **rendering, &block
  end

  # Update the <tt>target</tt> in the dom with either the <tt>content</tt> passed in or a rendering result determined
  # by the <tt>rendering</tt> keyword arguments, the content in the block, or the rendering of the target as a record. Examples:
  #
  #   <%= turbo_stream.update "clearance_5", "Update the content of the dom target identified by clearance_5" %>
  #   <%= turbo_stream.update clearance %>
  #   <%= turbo_stream.update clearance, partial: "clearances/unique_clearance", locals: { title: "Hello" } %>
  #   <%= turbo_stream.update "clearance_5" do %>
  #     Update the content of the dom target identified by clearance_5
  #   <% end %>
  #   <%= turbo_stream.update clearance, "<div>Morph the dom target</div>", method: :morph %>
  def update(target, content = nil, method: nil, **rendering, &block)
    action :update, target, content, method: method, **rendering, &block
  end

  # Update the <tt>targets</tt> in the dom with either the <tt>content</tt> passed in or a rendering result determined
  # by the <tt>rendering</tt> keyword arguments, the content in the block, or the rendering of the targets as a record. Examples:
  #
  #   <%= turbo_stream.update_all "clearance_item", "Update the content of the dom target identified by the class clearance_item" %>
  #   <%= turbo_stream.update_all clearance %>
  #   <%= turbo_stream.update_all clearance, partial: "clearances/new_clearance", locals: { title: "Hello" } %>
  #   <%= turbo_stream.update_all "clearance_item" do %>
  #     Update the content of the dom target identified by the class clearance_item
  #   <% end %>
  #   <%= turbo_stream.update_all clearance, "<div>Morph the dom target</div>", method: :morph %>
  def update_all(targets, content = nil, method: nil, **rendering, &block)
    action_all :update, targets, content, method: method, **rendering, &block
  end

  # Append to the target in the dom identified with <tt>target</tt> either the <tt>content</tt> passed in or a
  # rendering result determined by the <tt>rendering</tt> keyword arguments, the content in the block,
  # or the rendering of the content as a record. Examples:
  #
  #   <%= turbo_stream.append "clearances", "<div id='clearance_5'>Append this to .clearances</div>" %>
  #   <%= turbo_stream.append "clearances", clearance %>
  #   <%= turbo_stream.append "clearances", partial: "clearances/unique_clearance", locals: { clearance: clearance } %>
  #   <%= turbo_stream.append "clearances" do %>
  #     <div id='clearance_5'>Append this to .clearances</div>
  #   <% end %>
  def append(target, content = nil, **rendering, &block)
    action :append, target, content, **rendering, &block
  end

  # Append to the targets in the dom identified with <tt>targets</tt> either the <tt>content</tt> passed in or a
  # rendering result determined by the <tt>rendering</tt> keyword arguments, the content in the block,
  # or the rendering of the content as a record. Examples:
  #
  #   <%= turbo_stream.append_all ".clearances", "<div class='clearance_item'>Append this to .clearance_group</div>" %>
  #   <%= turbo_stream.append_all ".clearances", clearance %>
  #   <%= turbo_stream.append_all ".clearances", partial: "clearances/new_clearance", locals: { clearance: clearance } %>
  #   <%= turbo_stream.append_all ".clearances" do %>
  #     <div id='clearance_item'>Append this to .clearances</div>
  #   <% end %>
  def append_all(targets, content = nil, **rendering, &block)
    action_all :append, targets, content, **rendering, &block
  end

  # Prepend to the target in the dom identified with <tt>target</tt> either the <tt>content</tt> passed in or a
  # rendering result determined by the <tt>rendering</tt> keyword arguments or the content in the block,
  # or the rendering of the content as a record. Examples:
  #
  #   <%= turbo_stream.prepend "clearances", "<div id='clearance_5'>Prepend this to .clearances</div>" %>
  #   <%= turbo_stream.prepend "clearances", clearance %>
  #   <%= turbo_stream.prepend "clearances", partial: "clearances/unique_clearance", locals: { clearance: clearance } %>
  #   <%= turbo_stream.prepend "clearances" do %>
  #     <div id='clearance_5'>Prepend this to .clearances</div>
  #   <% end %>
  def prepend(target, content = nil, **rendering, &block)
    action :prepend, target, content, **rendering, &block
  end

  # Prepend to the targets in the dom identified with <tt>targets</tt> either the <tt>content</tt> passed in or a
  # rendering result determined by the <tt>rendering</tt> keyword arguments or the content in the block,
  # or the rendering of the content as a record. Examples:
  #
  #   <%= turbo_stream.prepend_all ".clearances", "<div class='clearance_item'>Prepend this to .clearances</div>" %>
  #   <%= turbo_stream.prepend_all ".clearances", clearance %>
  #   <%= turbo_stream.prepend_all ".clearances", partial: "clearances/new_clearance", locals: { clearance: clearance } %>
  #   <%= turbo_stream.prepend_all ".clearances" do %>
  #     <div class='clearance_item'>Prepend this to .clearances</div>
  #   <% end %>
  def prepend_all(targets, content = nil, **rendering, &block)
    action_all :prepend, targets, content, **rendering, &block
  end

  # Creates a `turbo-stream` tag with an `[action="refresh"`] attribute and a
  # `[request-id]` attribute that defaults to `Turbo.current_request_id`:
  #
  #   turbo_stream.refresh
  #   # => <turbo-stream action="refresh" request-id="ef083d55-7516-41b1-ad28-16f553399c6a"></turbo-stream>
  #
  #   turbo_stream.refresh request_id: "abc123"
  #   # => <turbo-stream action="refresh" request-id="abc123"></turbo-stream>
  def refresh(...)
    turbo_stream_refresh_tag(...)
  end

  # Send an action of the type <tt>name</tt> to <tt>target</tt>. Options described in the concrete methods.
  def action(name, target, content = nil, method: nil, allow_inferred_rendering: true, **rendering, &block)
    template = render_template(target, content, allow_inferred_rendering: allow_inferred_rendering, **rendering, &block)

    turbo_stream_action_tag name, target: target, template: template, method: method
  end

  # Send an action of the type <tt>name</tt> to <tt>targets</tt>. Options described in the concrete methods.
  def action_all(name, targets, content = nil, method: nil, allow_inferred_rendering: true, **rendering, &block)
    template = render_template(targets, content, allow_inferred_rendering: allow_inferred_rendering, **rendering, &block)

    turbo_stream_action_tag name, targets: targets, template: template, method: method
  end

  private
    def render_template(target, content = nil, allow_inferred_rendering: true, **rendering, &block)
      case
      when target.respond_to?(:render_in) && content.nil?
        target.render_in(@view_context, &block)
      when content.respond_to?(:render_in)
        content.render_in(@view_context, &block)
      when content
        allow_inferred_rendering ? (render_record(content) || content) : content
      when block_given? && (rendering.key?(:partial) || rendering.key?(:layout))
        @view_context.render(formats: [ :html ], layout: rendering[:partial], **rendering, &block)
      when block_given?
        @view_context.capture(&block)
      when rendering.any?
        @view_context.render(formats: [ :html ], **rendering)
      else
        render_record(target) if allow_inferred_rendering
      end
    end

    def render_record(possible_record)
      if possible_record.respond_to?(:to_partial_path)
        record = possible_record
        @view_context.render(partial: record, formats: :html)
      end
    end

  ActiveSupport.run_load_hooks :turbo_streams_tag_builder, self
end
