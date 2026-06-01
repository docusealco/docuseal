# frozen_string_literal: true

module Ferrum
  class Target
    NEW_WINDOW_WAIT = ENV.fetch("FERRUM_NEW_WINDOW_WAIT", 0.3).to_f

    # You can create page yourself and assign it to target, used in cuprite
    # where we enhance page class and build page ourselves.
    attr_writer :page

    attr_reader :options
    attr_accessor :session_id

    def initialize(browser_client, session_id = nil, params = nil)
      @page = nil
      @session_id = session_id
      @params = params
      @browser_client = browser_client
      @options = browser_client.options
    end

    def update(params)
      @params.merge!(params)
    end

    def connected?
      !!@page
    end

    def page
      @page ||= build_page
    end

    def client
      @client ||= build_client
    end

    def build_page(**options)
      maybe_sleep_if_new_window
      Page.new(client, context_id: context_id, target_id: id, **options)
    end

    def id
      @params["targetId"]
    end

    def type
      @params["type"]
    end

    def title
      @params["title"]
    end

    def url
      @params["url"]
    end

    def opener_id
      @params["openerId"]
    end

    def context_id
      @params["browserContextId"]
    end

    def window?
      !!opener_id
    end

    def iframe?
      type == "iframe"
    end

    def maybe_sleep_if_new_window
      # Dirty hack because new window doesn't have events at all
      sleep(NEW_WINDOW_WAIT) if window?
    end

    def command(...)
      client.command(...)
    end

    private

    def build_client
      return @browser_client.session(session_id) if options.flatten

      Client.new(ws_url, options)
    end

    def ws_url
      @browser_client.ws_url.merge(path: "/devtools/page/#{id}")
    end
  end
end
