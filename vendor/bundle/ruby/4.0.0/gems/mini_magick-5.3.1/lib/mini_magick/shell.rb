require "open3"

module MiniMagick
  ##
  # Sends commands to the shell (more precisely, it sends commands directly to
  # the operating system).
  #
  # @private
  #
  class Shell

    def run(command, errors: MiniMagick.errors, warnings: MiniMagick.warnings, **options)
      stdout, stderr, status = execute(command, **options)

      if status != 0
        if stderr.include?("time limit exceeded")
          fail MiniMagick::TimeoutError, "`#{command.join(" ")}` has timed out"
        elsif errors
          fail MiniMagick::Error, "`#{command.join(" ")}` failed with status: #{status.inspect} and error:\n#{stderr}"
        end
      end

      $stderr.print(stderr) if warnings

      [stdout, stderr, status]
    end

    def execute(command, stdin: "", timeout: MiniMagick.timeout)
      env = MiniMagick.restricted_env ? ENV.to_h.slice("HOME", "PATH", "LANG") : {} # Using #to_h for Ruby 2.5 compatibility.
      env.merge!(MiniMagick.cli_env)
      env["MAGICK_TIME_LIMIT"] = timeout.to_s if timeout

      stdout, stderr, status = log(command.join(" ")) do
        Open3.capture3(env, *command, stdin_data: stdin, unsetenv_others: MiniMagick.restricted_env)
      end

      [stdout, stderr, status&.exitstatus]
    rescue Errno::ENOENT, IOError
      ["", "executable not found: \"#{command.first}\"", 127]
    end

    private

    def log(command, &block)
      time_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      value = block.call
      duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - time_start
      MiniMagick.logger.debug "[%.2fs] %s" % [duration, command]
      value
    end

  end
end
