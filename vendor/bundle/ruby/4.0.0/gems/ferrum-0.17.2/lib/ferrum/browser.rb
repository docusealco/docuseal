# frozen_string_literal: true

require "base64"
require "forwardable"
require "ferrum/page"
require "ferrum/proxy"
require "ferrum/client"
require "ferrum/contexts"
require "ferrum/browser/xvfb"
require "ferrum/browser/options"
require "ferrum/browser/process"
require "ferrum/browser/binary"
require "ferrum/browser/version_info"

module Ferrum
  class Browser
    extend Forwardable

    delegate %i[default_context] => :contexts
    delegate %i[targets create_target page pages windows] => :default_context
    delegate %i[go_to goto go back forward refresh reload stop wait_for_reload
                at_css at_xpath css xpath current_url current_title url title
                body doctype content=
                headers cookies network downloads
                mouse keyboard
                screenshot pdf mhtml viewport_size device_pixel_ratio
                start_screencast stop_screencast
                frames frame_by main_frame
                evaluate evaluate_on evaluate_async execute evaluate_func
                add_script_tag add_style_tag bypass_csp
                on position position=
                playback_rate playback_rate=
                disable_javascript set_viewport resize] => :page

    attr_reader :client, :process, :contexts, :options

    delegate %i[timeout timeout= base_url base_url= default_user_agent default_user_agent= extensions] => :options
    delegate %i[command] => :client

    #
    # Initializes the browser.
    #
    # @param [Hash{Symbol => Object}, nil] options
    #   Additional browser options.
    #
    # @option options [Boolean] :headless (true)
    #   Set browser as headless or not.
    #
    # @option options [Boolean] :incognito (true)
    #   Create an incognito profile for the browser startup window.
    #
    # @option options [Boolean] :dockerize (false)
    #   Add CLI flags to a browser to run in a container.
    #
    # @option options [Boolean] :xvfb (false)
    #   Run browser in a virtual framebuffer.
    #
    # @option options [Boolean] :flatten (true)
    #   Use one websocket connection to the browser and all the pages in flatten mode.
    #
    # @option options [(Integer, Integer)] :window_size ([1024, 768])
    #   The dimensions of the browser window in which to test, expressed as a
    #   2-element array, e.g. `[1024, 768]`.
    #
    # @option options [Array<String, Hash>] :extensions
    #   An array of paths to files or JS source code to be preloaded into the
    #   browser e.g.: `["/path/to/script.js", { source: "window.secret = 'top'" }]`
    #
    # @option options [#puts] :logger
    #   When present, debug output is written to this object.
    #
    # @option options [Integer, Float] :slowmo
    #   Set a delay in seconds to wait before sending command.
    #   Useful companion of headless option, so that you have time to see
    #   changes.
    #
    # @option options [Numeric] :timeout (5)
    #   The number of seconds we'll wait for a response when communicating with
    #   browser.
    #
    # @option options [Boolean] :js_errors
    #   When true, JavaScript errors get re-raised in Ruby.
    #
    # @option options [Boolean] :pending_connection_errors (false)
    #   When main frame is still waiting for slow responses while timeout is
    #   reached {PendingConnectionsError} is raised. It's better to figure out
    #   why you have slow responses and fix or block them rather than turn this
    #   setting off.
    #
    # @option options [:chrome, :firefox] :browser_name (:chrome)
    #   Sets the browser's name. **Note:** only experimental support for
    #   `:firefox` for now.
    #
    # @option options [String] :browser_path
    #   Path to Chrome binary, you can also set ENV variable as
    #   `BROWSER_PATH=some/path/chrome bundle exec rspec`.
    #
    # @option options [Hash] :browser_options
    #   Additional command line options, [see them all](https://peter.sh/experiments/chromium-command-line-switches/)
    #   e.g. `{ "ignore-certificate-errors" => nil }`
    #
    # @option options [Boolean] :ignore_default_browser_options
    #   Ferrum has a number of default options it passes to the browser,
    #   if you set this to `true` then only options you put in
    #   `:browser_options` will be passed to the browser, except required ones
    #   of course.
    #
    # @option options [Integer] :port
    #   Remote debugging port for headless Chrome.
    #
    # @option options [String] :host
    #   Remote debugging address for headless Chrome.
    #
    # @option options [String] :url
    #   URL for a running instance of Chrome. If this is set, a browser process
    #   will not be spawned.
    #
    # @option options [Integer] :process_timeout
    #   How long to wait for the Chrome process to respond on startup.
    #
    # @option options [Integer] :ws_max_receive_size
    #   How big messages to accept from Chrome over the web socket, in bytes.
    #   Defaults to 64MB. Incoming messages larger this will cause a
    #   {Ferrum::DeadBrowserError}.
    #
    # @option options [Hash] :proxy
    #   Specify proxy settings, [read more](https://github.com/rubycdp/ferrum#proxy).
    #
    # @option options [String] :save_path
    #   Path to save attachments with [Content-Disposition](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition)
    #   header.
    #
    # @option options [Hash] :env
    #   Environment variables you'd like to pass through to the process.
    #
    def initialize(options = nil)
      @options = Options.new(options)
      @client = @process = @contexts = nil

      start
    end

    #
    # Creates a new page.
    #
    # @param [Boolean] new_context
    #   Whether to create a page in a new context or not.
    #
    # @param [Hash] proxy
    #   Whether to use proxy for a page. The page will be created in a new context if so.
    #
    # @return [Ferrum::Page]
    #   Created page.
    #
    def create_page(new_context: false, proxy: nil)
      page = if new_context || proxy
               params = {}

               if proxy
                 options.validate_proxy(proxy)
                 params.merge!(proxyServer: "#{proxy[:host]}:#{proxy[:port]}")
                 params.merge!(proxyBypassList: proxy[:bypass]) if proxy[:bypass]
               end

               context = contexts.create(**params)
               context.create_page(proxy: proxy)
             else
               default_context.create_page
             end

      block_given? ? yield(page) : page
    ensure
      if block_given?
        page&.close
        context.dispose if new_context
      end
    end

    #
    # Evaluate JavaScript to modify things before a page load.
    #
    # @param [String] expression
    #   The JavaScript to add to each new document.
    #
    # @example
    #   browser.evaluate_on_new_document <<~JS
    #     Object.defineProperty(navigator, "languages", {
    #       get: function() { return ["tlh"]; }
    #     });
    #   JS
    #
    def evaluate_on_new_document(expression)
      extensions << expression
    end

    #
    # Closes browser tabs opened by the `Browser` instance.
    #
    # @example
    #   # connect to a long-running Chrome process
    #   browser = Ferrum::Browser.new(url: 'http://localhost:9222')
    #
    #   browser.go_to("https://github.com/")
    #
    #   # clean up, lest the tab stays there hanging forever
    #   browser.reset
    #
    #   browser.quit
    #
    def reset
      contexts.reset
    end

    def restart
      quit
      start
    end

    def quit
      return unless @client

      contexts.close_connections

      @client.close
      @process.stop
      @client = @process = @contexts = nil
    end

    #
    # Crashes browser.
    #
    def crash
      command("Browser.crash")
    end

    #
    # Close browser gracefully.
    #
    # You should clean up resources/connections in ruby world manually, it's only a CDP command.
    #
    def close
      command("Browser.close")
    end

    #
    # Gets the version information from the browser.
    #
    # @return [VersionInfo]
    #
    # @since 0.13
    #
    def version
      VersionInfo.new(command("Browser.getVersion"))
    end

    #
    # Opens headless session in the browser devtools frontend.
    #
    # @return [void]
    #
    # @since 0.16
    #
    def debug(bind = nil)
      ::Process.spawn(process.path, debug_url)

      bind ||= binding
      if bind.respond_to?(:pry)
        Pry.start(bind)
      else
        bind.irb
      end
    end

    private

    def start
      Utils::ElapsedTime.start
      @process = Process.new(options)

      begin
        @process.start
        @options.default_user_agent = @process.default_user_agent

        @client = Client.new(@process.ws_url, options)
        @contexts = Contexts.new(@client)
      rescue StandardError
        @process.stop
        raise
      end
    end

    def debug_url
      response = JSON.parse(Net::HTTP.get(URI(build_remote_debug_url(path: "/json"))))

      devtools_frontend_path = response[0]&.[]("devtoolsFrontendUrl")
      raise "Could not generate debug url for remote debugging session" unless devtools_frontend_path

      build_remote_debug_url(path: devtools_frontend_path)
    end

    def build_remote_debug_url(path:)
      return path if Addressable::URI.parse(path).absolute?

      "http://#{process.host}:#{process.port}#{path}"
    end
  end
end
