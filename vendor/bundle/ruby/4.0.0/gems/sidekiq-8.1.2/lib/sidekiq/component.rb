# frozen_string_literal: true

module Sidekiq
  # Ruby's default thread priority is 0, which uses 100ms time slices.
  # This can lead to some surprising thread starvation; if using a lot of
  # CPU-heavy concurrency, it may take several seconds before a Thread gets
  # on the CPU.
  #
  # Negative priorities lower the timeslice by half, so -1 = 50ms, -2 = 25ms, etc.
  # With more frequent timeslices, we reduce the risk of unintentional timeouts
  # and starvation.
  #
  # Customize like so:
  #
  #   Sidekiq.configure_server do |cfg|
  #     cfg.thread_priority = 0
  #   end
  #
  DEFAULT_THREAD_PRIORITY = -1

  ##
  # Sidekiq::Component provides a set of utility methods depending only
  # on Sidekiq::Config. It assumes a config instance is available at @config.
  module Component # :nodoc:
    attr_reader :config

    # This is epoch milliseconds, appropriate for persistence
    def real_ms
      ::Process.clock_gettime(::Process::CLOCK_REALTIME, :millisecond)
    end

    # used for time difference and relative comparisons, not persistence.
    def mono_ms
      ::Process.clock_gettime(::Process::CLOCK_MONOTONIC, :millisecond)
    end

    def watchdog(last_words)
      yield
    rescue Exception => ex
      handle_exception(ex, {context: last_words})
      raise ex
    end

    def safe_thread(name, priority: nil, &block)
      Thread.new do
        Thread.current.name = "sidekiq.#{name}"
        watchdog(name, &block)
      end.tap { |t| t.priority = (priority || config.thread_priority || DEFAULT_THREAD_PRIORITY) }
    end

    def logger
      config.logger
    end

    def redis(&block)
      config.redis(&block)
    end

    def tid
      # We XOR with PID to ensure Thread IDs changes after fork.
      # I'm unclear why we don't multiply the two values to better guarantee
      # a unique value but it's been this way for quite a while now. #3685
      Thread.current["sidekiq_tid"] ||= (Thread.current.object_id ^ ::Process.pid).to_s(36)
    end

    def hostname
      ENV["DYNO"] || Socket.gethostname
    end

    def process_nonce
      @@process_nonce ||= SecureRandom.hex(6)
    end

    def identity
      @@identity ||= "#{hostname}:#{::Process.pid}:#{process_nonce}"
    end

    def handle_exception(ex, ctx = {})
      config.handle_exception(ex, ctx)
    end

    def fire_event(event, options = {})
      oneshot = options.fetch(:oneshot, true)
      reverse = options[:reverse]
      reraise = options[:reraise]
      logger.debug("Firing #{event} event") if oneshot

      arr = config[:lifecycle_events][event]
      arr.reverse! if reverse
      arr.each do |block|
        block.call
      rescue => ex
        handle_exception(ex, {context: "Exception during Sidekiq lifecycle event.", event: event})
        raise ex if reraise
      end
      arr.clear if oneshot # once we've fired an event, we never fire it again
    end

    # When you have a large tree of components, the `inspect` output
    # can get out of hand, especially with lots of Sidekiq::Config
    # references everywhere. We avoid calling `inspect` on more complex
    # state and use `to_s` instead to keep output manageable, #6553
    def inspect
      "#<#{self.class.name} #{
        instance_variables.map do |name|
          value = instance_variable_get(name)
          case value
          when Proc
            "#{name}=#{value}"
          when Sidekiq::Config
            "#{name}=#{value}"
          when Sidekiq::Component
            "#{name}=#{value}"
          else
            "#{name}=#{value.inspect}"
          end
        end.join(", ")
      }>"
    end

    def default_tag(dir = Dir.pwd)
      name = File.basename(dir)
      prevdir = File.dirname(dir) # Capistrano release directory?
      if name.to_i != 0 && prevdir
        if File.basename(prevdir) == "releases"
          return File.basename(File.dirname(prevdir))
        end
      end
      name
    end
  end
end
