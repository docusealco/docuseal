# frozen_string_literal: true

require "concurrent-ruby"
require "forwardable"
require "ferrum/client/subscriber"
require "ferrum/client/web_socket"
require "ferrum/utils/thread"

module Ferrum
  class SessionClient
    attr_reader :client, :session_id

    def self.event_name(event, session_id)
      [event, session_id].compact.join("_")
    end

    def initialize(client, session_id)
      @client = client
      @session_id = session_id
    end

    def command(method, async: false, **params)
      message = build_message(method, params)
      @client.send_message(message, async: async)
    end

    def on(event, &)
      @client.on(event_name(event), &)
    end

    def off(event, id)
      @client.off(event_name(event), id)
    end

    def subscribed?(event)
      @client.subscribed?(event_name(event))
    end

    def respond_to_missing?(name, include_private)
      @client.respond_to?(name, include_private)
    end

    def method_missing(name, ...)
      @client.send(name, ...)
    end

    def close
      @client.subscriber.clear(session_id: session_id)
    end

    private

    def build_message(method, params)
      @client.build_message(method, params).merge(sessionId: session_id)
    end

    def event_name(event)
      self.class.event_name(event, session_id)
    end
  end

  class Client
    extend Forwardable

    delegate %i[timeout timeout=] => :options

    attr_reader :ws_url, :options, :subscriber

    def initialize(ws_url, options)
      @command_id = 0
      @ws_url = ws_url
      @options = options
      @pendings = Concurrent::Hash.new
      @ws = WebSocket.new(ws_url, options.ws_max_receive_size, options.logger)
      @subscriber = Subscriber.new

      start
    end

    def command(method, async: false, **params)
      message = build_message(method, params)
      send_message(message, async: async)
    end

    def send_message(message, async:)
      if async
        @ws.send_message(message)
        true
      else
        pending = Concurrent::IVar.new
        @pendings[message[:id]] = pending
        @ws.send_message(message)
        data = pending.value!(timeout)
        @pendings.delete(message[:id])

        raise DeadBrowserError if data.nil? && @ws.messages.closed?
        raise TimeoutError unless data

        error, response = data.values_at("error", "result")
        raise_browser_error(error) if error
        response
      end
    end

    def on(event, &)
      @subscriber.on(event, &)
    end

    def off(event, id)
      @subscriber.off(event, id)
    end

    def subscribed?(event)
      @subscriber.subscribed?(event)
    end

    def session(session_id)
      SessionClient.new(self, session_id)
    end

    def close
      @ws.close
      # Give a thread some time to handle a tail of messages
      @pendings.clear
      @thread.kill unless @thread.join(1)
      @subscriber.close
    end

    def inspect
      "#<#{self.class} " \
        "@command_id=#{@command_id.inspect} " \
        "@pendings=#{@pendings.inspect} " \
        "@ws=#{@ws.inspect}>"
    end

    def build_message(method, params)
      { method: method, params: params }.merge(id: next_command_id)
    end

    private

    def start
      @thread = Utils::Thread.spawn do
        loop do
          message = @ws.messages.pop
          break unless message

          if message.key?("method")
            @subscriber << message
          else
            @pendings[message["id"]]&.set(message)
          end
        end
      end
    end

    def next_command_id
      @command_id += 1
    end

    def raise_browser_error(error)
      case error["message"]
      # Node has disappeared while we were trying to get it
      when "No node with given id found",
           "Could not find node with given id",
           "Inspected target navigated or closed"
        raise NodeNotFoundError, error
      # Context is lost, page is reloading
      when "Cannot find context with specified id"
        raise NoExecutionContextError, error
      when "No target with given id found"
        raise NoSuchPageError
      when /Could not compute content quads/
        raise CoordinatesNotFoundError
      else
        raise BrowserError, error
      end
    end
  end
end
