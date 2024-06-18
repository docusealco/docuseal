# frozen_string_literal: true

require 'puma/plugin'

# rubocop:disable Metrics
Puma::Plugin.create do
  def start(launcher)
    return if ENV['LOCAL_REDIS_URL'].to_s.empty?

    @puma_pid = $PROCESS_ID

    launcher.events.on_booted do
      @redis_server_pid = fork_redis
    end

    in_background { monitor_redis }

    at_exit do
      stop_redis_server if Process.pid == @puma_pid
    end

    launcher.events.on_stopped { stop_redis_server }
    launcher.events.on_restart { stop_redis_server }
  end

  private

  def monitor_redis
    loop do
      if redis_dead?
        Process.kill(:INT, @puma_pid)

        break
      end

      sleep 5
    end
  end

  def redis_dead?
    return false unless @redis_server_pid

    Process.waitpid(@redis_server_pid, Process::WNOHANG)

    false
  rescue Errno::ECHILD, Errno::ESRCH
    true
  end

  def fork_redis
    fork do
      Process.setsid

      Dir.chdir(ENV.fetch('WORKDIR', nil)) unless ENV['WORKDIR'].to_s.empty?

      exec('redis-server', '--requirepass', Digest::SHA1.hexdigest("redis#{ENV.fetch('SECRET_KEY_BASE', '')}"),
           out: '/dev/null')
    end
  end

  def stop_redis_server
    if @redis_server_pid
      Process.kill(:INT, @redis_server_pid)
      Process.wait(@redis_server_pid)
    end
  rescue Errno::ECHILD, Errno::ESRCH
    nil
  end
end
# rubocop:enable Metrics
