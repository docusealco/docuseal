# frozen_string_literal: true

require "forwardable"
require "pathname"
require "ferrum/mouse"
require "ferrum/keyboard"
require "ferrum/headers"
require "ferrum/cookies"
require "ferrum/dialog"
require "ferrum/network"
require "ferrum/downloads"
require "ferrum/page/frames"
require "ferrum/page/screencast"
require "ferrum/page/screenshot"
require "ferrum/page/animation"
require "ferrum/page/tracing"
require "ferrum/page/stream"

module Ferrum
  class Page
    GOTO_WAIT = ENV.fetch("FERRUM_GOTO_WAIT", 0.1).to_f

    extend Forwardable

    delegate %i[at_css at_xpath css xpath
                current_url current_title url title body doctype content=
                execution_id execution_id! evaluate evaluate_on evaluate_async execute evaluate_func
                add_script_tag add_style_tag] => :main_frame
    delegate %i[base_url default_user_agent timeout timeout=] => :@options

    include Animation
    include Screencast
    include Screenshot
    include Frames
    include Stream

    attr_accessor :referrer
    attr_reader :context_id, :target_id, :event, :tracing

    # Client connection.
    #
    # @return [Client]
    attr_reader :client

    # Mouse object.
    #
    # @return [Mouse]
    attr_reader :mouse

    # Keyboard object.
    #
    # @return [Keyboard]
    attr_reader :keyboard

    # Network object.
    #
    # @return [Network]
    attr_reader :network

    # Headers object.
    #
    # @return [Headers]
    attr_reader :headers

    # Cookie store.
    #
    # @return [Cookies]
    attr_reader :cookies

    # Downloads object.
    #
    # @return [Downloads]
    attr_reader :downloads

    def initialize(client, context_id:, target_id:, proxy: nil)
      @client = client
      @context_id = context_id
      @target_id = target_id
      @options = client.options

      @frames = Concurrent::Map.new
      @main_frame = Frame.new(nil, self)
      @event = Utils::Event.new.tap(&:set)
      self.proxy = proxy

      @mouse = Mouse.new(self)
      @keyboard = Keyboard.new(self)
      @headers = Headers.new(self)
      @cookies = Cookies.new(self)
      @network = Network.new(self)
      @tracing = Tracing.new(self)
      @downloads = Downloads.new(self)

      subscribe
      prepare_page
    end

    #
    # Navigates the page to a URL.
    #
    # @param [String, nil] url
    #   The URL to navigate to. The url should include scheme unless you set
    #   `{Browser#base_url = url}` when configuring.
    #
    # @example
    #   page.go_to("https://github.com/")
    #
    def go_to(url = nil)
      options = { url: combine_url!(url) }
      options.merge!(referrer: referrer) if referrer
      response = command("Page.navigate", wait: GOTO_WAIT, **options)
      error_text = response["errorText"] # https://cs.chromium.org/chromium/src/net/base/net_error_list.h
      if error_text && error_text != "net::ERR_ABORTED" # Request aborted due to user action or download
        raise StatusError.new(options[:url], "Request to #{options[:url]} failed (#{error_text})")
      end

      response["frameId"]
    rescue TimeoutError
      if @options.pending_connection_errors
        pendings = network.traffic.select(&:pending?).map(&:url).compact
        raise PendingConnectionsError.new(options[:url], pendings) unless pendings.empty?
      end
    end
    alias goto go_to
    alias go go_to

    def close
      @headers.clear
      client.command("Target.closeTarget", async: true, targetId: @target_id)
      close_connection

      true
    end

    def close_connection
      client&.close
    end

    #
    # Overrides device screen dimensions and emulates viewport according to parameters
    #
    # Read more [here](https://chromedevtools.github.io/devtools-protocol/tot/Emulation/#method-setDeviceMetricsOverride).
    #
    # @param [Integer] width width value in pixels. 0 disables the override
    #
    # @param [Integer] height height value in pixels. 0 disables the override
    #
    # @param [Float] scale_factor device scale factor value. 0 disables the override
    #
    # @param [Boolean] mobile whether to emulate mobile device
    #
    def set_viewport(width:, height:, scale_factor: 0, mobile: false)
      command(
        "Emulation.setDeviceMetricsOverride",
        slowmoable: true,
        width: width,
        height: height,
        deviceScaleFactor: scale_factor,
        mobile: mobile
      )
    end

    def resize(width: nil, height: nil, fullscreen: false)
      if fullscreen
        width, height = document_size
        self.window_bounds = { window_state: "fullscreen" }
      else
        self.window_bounds = { window_state: "normal" }
        self.window_bounds = { width: width, height: height }
      end

      set_viewport(width: width, height: height)
    end

    #
    # Disables JavaScript execution from the HTML source for the page.
    #
    # This doesn't prevent users evaluate JavaScript with Ferrum.
    #
    def disable_javascript
      command("Emulation.setScriptExecutionDisabled", value: true)
    end

    #
    # The current position of the window.
    #
    # @return [(Integer, Integer)]
    #   The left, top coordinates of the window.
    #
    # @example
    #   page.position # => [10, 20]
    #
    def position
      window_bounds.values_at("left", "top")
    end

    #
    # Sets the position of the window.
    #
    # @param [Hash{Symbol => Object}] options
    #
    # @option options [Integer] :left
    #   The number of pixels from the left-hand side of the screen.
    #
    # @option options [Integer] :top
    #   The number of pixels from the top of the screen.
    #
    # @example
    #   page.position = { left: 10, top: 20 }
    #
    def position=(options)
      self.window_bounds = { left: options[:left], top: options[:top] }
    end

    # Sets the position of the window.
    #
    # @param [Hash{Symbol => Object}] bounds
    #
    # @option options [Integer] :left
    #   The number of pixels from the left-hand side of the screen.
    #
    # @option options [Integer] :top
    #   The number of pixels from the top of the screen.
    #
    # @option options [Integer] :width
    #   The window width in pixels.
    #
    # @option options [Integer] :height
    #   The window height in pixels.
    #
    # @option options [String] :window_state
    #   The window state. Default to normal. Allowed Values: normal, minimized, maximized, fullscreen
    #
    # @example
    #   page.window_bounds = { left: 10, top: 20, width: 1024, height: 768, window_state: "normal" }
    #
    def window_bounds=(bounds)
      options = bounds.dup
      window_state = options.delete(:window_state)
      bounds = { windowState: window_state, **options }.compact

      client.command("Browser.setWindowBounds", windowId: window_id, bounds: bounds)
    end

    #
    # Current window bounds.
    #
    # @return [Hash{String => (Integer, String)}]
    #
    # @example
    #   page.window_bounds # => { "left": 0, "top": 1286, "width": 10, "height": 10, "windowState": "normal" }
    #
    def window_bounds
      client.command("Browser.getWindowBounds", windowId: window_id).fetch("bounds")
    end

    #
    # Current window id.
    #
    # @return [Integer]
    #
    # @example
    #   page.window_id # => 1
    #
    def window_id
      client.command("Browser.getWindowForTarget", targetId: target_id)["windowId"]
    end

    #
    # Reloads the current page.
    #
    # @example
    #   page.go_to("https://github.com/")
    #   page.refresh
    #
    def refresh
      command("Page.reload", wait: timeout, slowmoable: true)
    end
    alias reload refresh

    #
    # Stop all navigations and loading pending resources on the page.
    #
    # @example
    #   page.go_to("https://github.com/")
    #   page.stop
    #
    def stop
      command("Page.stopLoading", slowmoable: true)
    end

    #
    # Navigates to the previous URL in the history.
    #
    # @example
    #   page.go_to("https://github.com/")
    #   page.at_xpath("//a").click
    #   page.back
    #
    def back
      history_navigate(delta: -1)
    end

    #
    # Navigates to the next URL in the history.
    #
    # @example
    #   page.go_to("https://github.com/")
    #   page.at_xpath("//a").click
    #   page.back
    #   page.forward
    #
    def forward
      history_navigate(delta: 1)
    end

    def wait_for_reload(timeout = 1)
      @event.reset if @event.set?
      @event.wait(timeout)
      @event.set
    end

    #
    # Enables/disables CSP bypass.
    #
    # @param [Boolean] enabled
    #
    # @return [Boolean]
    #
    # @example
    #   page.bypass_csp # => true
    #   page.go_to("https://github.com/ruby-concurrency/concurrent-ruby/blob/master/docs-source/promises.in.md")
    #   page.refresh
    #   page.add_script_tag(content: "window.__injected = 42")
    #   page.evaluate("window.__injected") # => 42
    #
    def bypass_csp(enabled: true)
      command("Page.setBypassCSP", enabled: enabled)
      enabled
    end

    #
    # Activates (focuses) the target for the given page.
    # When you have multiple tabs you work with, and you need to switch a given one.
    #
    # @return [Boolean]
    #
    # @example
    #   page.activate # => true
    #
    def activate
      command("Target.activateTarget", targetId: target_id)
      true
    end

    def command(method, wait: 0, slowmoable: false, **params)
      iteration = @event.reset if wait.positive?
      sleep(@options.slowmo) if slowmoable && @options.slowmo.positive?
      result = client.command(method, **params)

      if wait.positive?
        # Wait a bit after command and check if iteration has
        # changed which means there was some network event for
        # the main frame and it started to load new content.
        @event.wait(wait)
        if iteration != @event.iteration
          set = @event.wait(timeout)
          raise TimeoutError unless set
        end
      end
      result
    end

    def on(name, &block)
      case name
      when :dialog
        client.on("Page.javascriptDialogOpening") do |params, index, total|
          dialog = Dialog.new(self, params)
          block.call(dialog, index, total)
        end
      when :request
        client.on("Fetch.requestPaused") do |params, index, total|
          request = Network::InterceptedRequest.new(client, params)
          exchange = network.select(request.network_id).last
          exchange ||= network.build_exchange(request.network_id)
          exchange.intercepted_request = request
          block.call(request, index, total)
        end
      when :auth
        client.on("Fetch.authRequired") do |params, index, total|
          request = Network::AuthRequest.new(self, params)
          block.call(request, index, total)
        end
      else
        client.on(name, &block)
      end
    end

    def off(name, id)
      case name
      when :dialog
        client.off("Page.javascriptDialogOpening", id)
      when :request
        client.off("Fetch.requestPaused", id)
      when :auth
        client.off("Fetch.authRequired", id)
      else
        client.off(name, id)
      end
    end

    def subscribed?(event)
      client.subscribed?(event)
    end

    def use_proxy?
      @proxy_host && @proxy_port
    end

    def use_authorized_proxy?
      use_proxy? && @proxy_user && @proxy_password
    end

    def document_node_id(async: false)
      return client.command("DOM.getDocument", async: true, depth: 0) if async

      command("DOM.getDocument", depth: 0).dig("root", "nodeId")
    end

    private

    def subscribe
      frames_subscribe
      network.subscribe
      downloads.subscribe

      if @options.logger
        on("Runtime.consoleAPICalled") do |params|
          params["args"].each { |r| @options.logger.puts(r["value"]) }
        end
      end

      if @options.js_errors
        on("Runtime.exceptionThrown") do |params|
          # FIXME: https://jvns.ca/blog/2015/11/27/why-rubys-timeout-is-dangerous-and-thread-dot-raise-is-terrifying/
          Thread.main.raise JavaScriptError, params["exceptionDetails"]
        end
      end

      on(:dialog) do |dialog, _index, total|
        if total == 1
          warn "Dialog was shown but you didn't provide `on(:dialog)` callback, accepting it by default. " \
               "Please take a look at https://github.com/rubycdp/ferrum#dialogs"
          dialog.accept
        end
      end
    end

    def prepare_page
      command("Page.enable")
      command("Runtime.enable")
      command("DOM.enable")
      command("CSS.enable")
      command("Log.enable")
      command("Network.enable")

      if use_authorized_proxy?
        network.authorize(user: @proxy_user,
                          password: @proxy_password,
                          type: :proxy) do |request, _index, _total|
          request.continue
        end
      end

      downloads.set_behavior(save_path: @options.save_path) if @options.save_path

      @options.extensions.each do |extension|
        command("Page.addScriptToEvaluateOnNewDocument", source: extension)
      end

      inject_extensions

      response = command("Page.getNavigationHistory")
      transition_type = response.dig("entries", 0, "transitionType")
      return if transition_type == "auto_toplevel"

      # If we create page by clicking links, submitting forms and so on it
      # opens a new window for which `frameStoppedLoading` event never
      # occurs and thus search for nodes cannot be completed. Here we check
      # the history and if the transitionType for example `link` then
      # content is already loaded, and we can try to get the document.
      document_node_id
    end

    def inject_extensions
      @options.extensions.each do |extension|
        # https://github.com/GoogleChrome/puppeteer/issues/1443
        # https://github.com/ChromeDevTools/devtools-protocol/issues/77
        # https://github.com/cyrus-and/chrome-remote-interface/issues/319
        # We also evaluate script just in case because
        # `Page.addScriptToEvaluateOnNewDocument` doesn't work in popups.
        command("Runtime.evaluate", expression: extension,
                                    executionContextId: execution_id!,
                                    returnByValue: true)
      end
    end

    def history_navigate(delta:)
      history = command("Page.getNavigationHistory")
      index, entries = history.values_at("currentIndex", "entries")
      entry = entries[index + delta]

      return unless entry

      # Potential wait because of network event
      command("Page.navigateToHistoryEntry",
              wait: Mouse::CLICK_WAIT,
              slowmoable: true,
              entryId: entry["id"])
    end

    def combine_url!(url_or_path)
      url = Addressable::URI.parse(url_or_path)
      nil_or_relative = url.nil? || url.relative?

      if nil_or_relative && !@options.base_url
        raise "Set :base_url browser's option or use absolute url in `go_to`, you passed: #{url_or_path}"
      end

      (nil_or_relative ? @options.base_url.join(url.to_s) : url).to_s
    end

    def proxy=(options)
      @proxy_host = options&.[](:host) || @options.proxy&.[](:host)
      @proxy_port = options&.[](:port) || @options.proxy&.[](:port)
      @proxy_user = options&.[](:user) || @options.proxy&.[](:user)
      @proxy_password = options&.[](:password) || @options.proxy&.[](:password)
    end
  end
end
