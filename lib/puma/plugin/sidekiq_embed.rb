# frozen_string_literal: true

require 'puma/plugin'

# rubocop:disable Metrics
Puma::Plugin.create do
  def config(cfg)
    return if cfg.instance_variable_get(:@options)[:workers] <= 0

    cfg.on_worker_boot { start_sidekiq! }

    cfg.on_worker_shutdown { @sidekiq&.stop }
    cfg.on_refork { @sidekiq&.stop }
  end

  def start(launcher)
    launcher.events.on_booted do
      next if Puma.stats_hash[:workers].to_i != 0

      start_sidekiq!
    end

    launcher.events.on_stopped { Thread.new { @sidekiq&.stop }.join }
    launcher.events.on_restart { Thread.new { @sidekiq&.stop }.join }
  end

  def fire_event(config, event)
    arr = config[:lifecycle_events][event]

    arr.each(&:call)

    arr.clear
  end

  def start_sidekiq!
    Thread.new do
      wait_for_redis!

      configs = Sidekiq.configure_embed do |config|
        config.logger.level = Logger::INFO
        sidekiq_config = YAML.load_file('config/sidekiq.yml')
        config.queues = sidekiq_config['queues']
        config.concurrency = ENV.fetch('SIDEKIQ_THREADS', 5).to_i
        config.merge!(sidekiq_config)
        config[:max_retries] = 13

        ActiveSupport.run_load_hooks(:sidekiq_config, config)
      end.instance_variable_get(:@config)

      @sidekiq = Sidekiq::Launcher.new(configs, embedded: true)

      @sidekiq.run

      fire_event(configs, :startup)
    end
  end

  def wait_for_redis!
    attempt = 0

    loop do
      attempt += 1

      sleep (attempt - 1) / 10.0

      RedisClient.new(url: ENV.fetch('REDIS_URL', nil)).call('GET', '1')

      break
    rescue RedisClient::CannotConnectError
      raise('Unable to connect to redis') if attempt > 10
    end
  end
end
# rubocop:enable Metrics
