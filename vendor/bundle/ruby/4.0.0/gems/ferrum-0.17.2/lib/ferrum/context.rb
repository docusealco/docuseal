# frozen_string_literal: true

require "ferrum/target"

module Ferrum
  class Context
    POSITION = %i[first last].freeze

    attr_reader :id, :targets

    def initialize(client, contexts, id)
      @id = id
      @client = client
      @contexts = contexts
      @targets = Concurrent::Map.new
      @pendings = Concurrent::Map.new
    end

    def default_target
      @default_target ||= create_target
    end

    def page
      default_target.page
    end

    def pages
      @targets.values.reject(&:iframe?).map(&:page)
    end

    # When we call `page` method on target it triggers ruby to connect to given
    # page by WebSocket, if there are many opened windows, but we need only one
    # it makes more sense to get and connect to the needed one only which
    # usually is the last one.
    def windows(pos = nil, size = 1)
      raise ArgumentError if pos && !POSITION.include?(pos)

      windows = @targets.values.select(&:window?)
      windows = windows.send(pos, size) if pos
      windows.map(&:page)
    end

    def create_page(**options)
      target = create_target
      target.page = target.build_page(**options)
    end

    def create_target
      target_id = @client.command("Target.createTarget", browserContextId: @id, url: "about:blank")["targetId"]

      new_pending = Concurrent::IVar.new
      pending = @pendings.put_if_absent(target_id, new_pending) || new_pending
      resolved = pending.value(@client.timeout)
      raise NoSuchTargetError unless resolved

      @pendings.delete(target_id)
      @targets[target_id]
    end

    def add_target(params:, session_id: nil)
      new_target = Target.new(@client, session_id, params)
      # `put_if_absent` returns nil if added a new value or existing if there was one already
      target = @targets.put_if_absent(new_target.id, new_target) || new_target
      # on first iteration session_id may be nil, then if session is present here we must set it to the target
      target.session_id = session_id if session_id && target.session_id.nil?
      @default_target ||= target

      new_pending = Concurrent::IVar.new
      pending = @pendings.put_if_absent(target.id, new_pending) || new_pending
      pending.try_set(true)
      true
    end

    def update_target(target_id, params)
      @targets[target_id]&.update(params)
    end

    def delete_target(target_id)
      @targets.delete(target_id)
    end

    def attach_target(target_id)
      target = @targets[target_id]
      raise NoSuchTargetError unless target

      session = @client.command("Target.attachToTarget", targetId: target_id, flatten: true)
      target.session_id = session["sessionId"]
      true
    end

    def find_target
      @targets.each_value { |t| return t if yield(t) }

      nil
    end

    def close_targets_connection
      @targets.each_value do |target|
        next unless target.connected?

        target.page.close_connection
      end
    end

    def dispose
      @contexts.dispose(@id)
    end

    def target?(target_id)
      !!@targets[target_id]
    end

    def inspect
      %(#<#{self.class} @id=#{@id.inspect} @targets=#{@targets.inspect} @default_target=#{@default_target.inspect}>)
    end
  end
end
