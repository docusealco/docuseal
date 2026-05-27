# frozen_string_literal: true

module Puma

  # This is an event sink used by `Puma::Server` to handle
  # lifecycle events such as :after_booted, :before_restart, and :after_stopped.
  # Using `Puma::DSL` it is possible to register callback hooks
  # for each event type.
  class Events

    def initialize
      @hooks = Hash.new { |h,k| h[k] = [] }
    end

    # Fire callbacks for the named hook
    def fire(hook, *args)
      @hooks[hook].each { |t| t.call(*args) }
    end

    # Register a callback for a given hook
    def register(hook, obj=nil, &blk)
      if obj and blk
        raise "Specify either an object or a block, not both"
      end

      h = obj || blk

      @hooks[hook] << h

      h
    end

    def after_booted(&block)
      register(:after_booted, &block)
    end

    def before_restart(&block)
      register(:before_restart, &block)
    end

    def after_stopped(&block)
      register(:after_stopped, &block)
    end

    def on_booted(&block)
      Puma.deprecate_method_change :on_booted, __callee__, :after_booted
      after_booted(&block)
    end

    def on_restart(&block)
      Puma.deprecate_method_change :on_restart, __callee__, :before_restart
      before_restart(&block)
    end

    def on_stopped(&block)
      Puma.deprecate_method_change :on_stopped, __callee__, :after_stopped
      after_stopped(&block)
    end

    def fire_after_booted!
      fire(:after_booted)
    end

    def fire_before_restart!
      fire(:before_restart)
    end

    def fire_after_stopped!
      fire(:after_stopped)
    end
  end
end
