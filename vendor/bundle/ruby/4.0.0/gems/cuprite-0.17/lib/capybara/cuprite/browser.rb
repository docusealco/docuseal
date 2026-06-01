# frozen_string_literal: true

require "forwardable"

module Capybara
  module Cuprite
    class Browser < Ferrum::Browser
      extend Forwardable

      delegate %i[send_keys select set hover trigger before_click switch_to_frame
                  find_modal accept_confirm dismiss_confirm accept_prompt
                  dismiss_prompt reset_modals] => :page

      def initialize(options = nil)
        super

        @options.url_blacklist = prepare_wildcards(options&.dig(:url_blacklist))
        @options.url_whitelist = prepare_wildcards(options&.dig(:url_whitelist))

        @page = nil
      end

      def command(...)
        super
      rescue Ferrum::DeadBrowserError
        restart
        raise
      end

      def page
        raise Ferrum::NoSuchPageError if @page&.closed?

        @page ||= attach_page
      end

      def reset
        super
        @options.reset_window_size
        @page = nil
      end

      def quit
        super
        @page = nil
      end

      def resize(**options)
        @options.window_size = [options[:width], options[:height]]
        super
      end

      def url_whitelist
        @options.url_whitelist
      end
      alias url_allowlist url_whitelist

      def url_whitelist=(patterns)
        @options.url_whitelist = prepare_wildcards(patterns)
        page.network.whitelist = @options.url_whitelist if @client && @options.url_whitelist.any?
      end
      alias url_allowlist= url_whitelist=

      def url_blacklist
        @options.url_blacklist
      end
      alias url_blocklist url_blacklist

      def url_blacklist=(patterns)
        @options.url_blacklist = prepare_wildcards(patterns)
        page.network.blacklist = @options.url_blacklist if @client && @options.url_blacklist.any?
      end
      alias url_blocklist= url_blacklist=

      def visit(*args)
        goto(*args)
      end

      def status_code
        network.status
      end

      def find(method, selector)
        find_all(method, selector)
      end

      def property(node, name)
        node.property(name)
      end

      def find_within(node, method, selector)
        resolved = page.command("DOM.resolveNode", nodeId: node.node_id)
        object_id = resolved.dig("object", "objectId")
        find_all(method, selector, { "objectId" => object_id })
      end

      def window_handle
        page.target_id
      end

      def window_handles
        targets.keys
      end

      def within_window(locator = nil)
        original = window_handle
        raise Ferrum::NoSuchPageError unless window_handles.include?(locator)

        switch_to_window(locator)
        yield
      ensure
        switch_to_window(original)
      end

      def switch_to_window(target_id)
        target = targets[target_id]
        raise Ferrum::NoSuchPageError unless target

        @page = attach_page(target.id)
      end

      def close_window(target_id)
        target = targets[target_id]
        raise Ferrum::NoSuchPageError unless target

        @page = ClosedPage.new if @page.target_id == target.id
        target.page.close
        targets.delete(target_id) # page.close is async, delete target asap
      end

      def active_element
        evaluate("document.activeElement")
      end

      def browser_error
        evaluate("_cuprite.browserError()")
      end

      def source
        raise NotImplementedError
      end

      def drag(node, other, steps, delay = nil, scroll = true)
        x1, y1 = node.find_position

        mouse.move(x: x1, y: y1)
        mouse.down
        sleep delay if delay

        other.scroll_into_view if scroll

        x2, y2 = other.find_position
        mouse.move(x: x2, y: y2, steps: steps)

        mouse.up
      end

      def drag_by(node, dx, dy, steps, delay = nil, scroll = true)
        x1, y1 = node.find_position

        mouse.move(x: x1, y: y1)
        mouse.down

        sleep delay if delay

        evaluate("window.scrollBy(#{dx}, #{dy})") if scroll # should be extracted to Mouse#scroll_by in ferrum

        x2, y2 = node.find_position
        mouse.move(x: x2 + dx, y: y2 + dy, steps: steps)
        mouse.up
      end

      def select_file(node, value)
        node.select_file(value)
      end

      def parents(node)
        evaluate_on(node: node, expression: "_cuprite.parents(this)", by_value: false)
      end

      def visible_text(node)
        evaluate_on(node: node, expression: "_cuprite.visibleText(this)")
      end

      def delete_text(node)
        evaluate_on(node: node, expression: "_cuprite.deleteText(this)")
      end

      def attributes(node)
        value = evaluate_on(node: node, expression: "_cuprite.getAttributes(this)")
        JSON.parse(value)
      end

      def attribute(node, name)
        evaluate_on(node: node, expression: %(_cuprite.getAttribute(this, "#{name}")))
      end

      def value(node)
        evaluate_on(node: node, expression: "_cuprite.value(this)")
      end

      def visible?(node)
        evaluate_on(node: node, expression: "_cuprite.isVisible(this)")
      end

      def disabled?(node)
        evaluate_on(node: node, expression: "_cuprite.isDisabled(this)")
      end

      def path(node)
        evaluate_on(node: node, expression: "_cuprite.path(this)")
      end

      def obscured?(node)
        evaluate_on(node: node, expression: "_cuprite.isObscured(this)")
      end

      def all_text(node)
        node.text
      end

      private

      def find_all(method, selector, within = nil)
        nodes = if within
                  evaluate("_cuprite.find(arguments[0], arguments[1], arguments[2])", method, selector, within)
                else
                  evaluate("_cuprite.find(arguments[0], arguments[1])", method, selector)
                end

        nodes.select(&:node?)
      rescue Ferrum::JavaScriptError => e
        raise InvalidSelector.new(e.response, method, selector) if e.class_name == "InvalidSelector"

        raise
      end

      def prepare_wildcards(patterns)
        string_passed = false

        Array(patterns).map do |pattern|
          if pattern.is_a?(Regexp)
            pattern
          else
            string_passed = true
            pattern = pattern.gsub("*", ".*")
            Regexp.new(pattern, Regexp::IGNORECASE)
          end
        end
      ensure
        if string_passed
          warn "Passing strings to blacklist/whitelist is deprecated, pass regexp at #{caller(4..4).first}"
        end
      end

      def attach_page(target_id = nil)
        target = targets[target_id] if target_id
        target ||= default_context.default_target
        return target.page if target.connected?

        target.maybe_sleep_if_new_window
        target.page = Page.new(target.client, context_id: target.context_id, target_id: target.id)
        target.page
      end
    end
  end
end
