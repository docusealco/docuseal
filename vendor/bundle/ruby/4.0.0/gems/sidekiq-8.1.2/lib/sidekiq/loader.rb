module Sidekiq
  require "sidekiq/component"

  class Loader
    include Sidekiq::Component

    def initialize(cfg = Sidekiq.default_configuration)
      @config = cfg
      @load_hooks = Hash.new { |h, k| h[k] = [] }
      @loaded = Set.new
      @lock = Mutex.new
    end

    # Declares a block that will be executed when a Sidekiq component is fully
    # loaded. If the component has already loaded, the block is executed
    # immediately.
    #
    #   Sidekiq.loader.on_load(:api) do
    #     # extend the sidekiq API
    #   end
    #
    def on_load(name, &block)
      # we don't want to hold the lock while calling the block
      to_run = nil

      @lock.synchronize do
        if @loaded.include?(name)
          to_run = block
        else
          @load_hooks[name] << block
        end
      end

      to_run&.call
      nil
    end

    # Executes all blocks registered to +name+ via on_load.
    #
    #   Sidekiq.loader.run_load_hooks(:api)
    #
    # In the case of the above example, it will execute all hooks registered for +:api+.
    #
    def run_load_hooks(name)
      hks = @lock.synchronize do
        @loaded << name
        @load_hooks.delete(name)
      end

      hks&.each do |blk|
        blk.call
      rescue => ex
        handle_exception(ex, hook: name)
      end
    end
  end
end
