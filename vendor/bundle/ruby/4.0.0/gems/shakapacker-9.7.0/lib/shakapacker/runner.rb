require_relative "utils/misc"
require_relative "utils/manager"
require_relative "configuration"
require_relative "version"
require_relative "build_config_loader"

require "package_json"
require "pathname"
require "stringio"

module Shakapacker
  class Runner
    attr_reader :config

    # Common commands that don't work with --config option
    BASE_COMMANDS = [
      "help",
      "h",
      "--help",
      "-h",
      "version",
      "v",
      "--version",
      "-v",
      "info",
      "i"
    ].freeze

    def self.json_output?(argv)
      argv.include?("--json") || argv.include?("-j")
    end

    def self.log_output_for(argv)
      json_output?(argv) ? $stderr : $stdout
    end

    def self.run(argv)
      $stdout.sync = true

      # Show Shakapacker help and exit (don't call bundler)
      # Support --help, -h, and --help=verbose formats
      help_verbose = argv.any? { |arg| arg == "--help=verbose" }
      if argv.include?("--help") || argv.include?("-h") || help_verbose
        print_help(verbose: help_verbose)
        exit(0)
      elsif argv.include?("--version") || argv.include?("-v")
        print_version
        exit(0)
      elsif argv.include?("--init")
        init_config_file
        exit(0)
      elsif argv.include?("--list-builds")
        list_builds
        exit(0)
      end

      # Check for --bundler flag
      bundler_override = nil
      bundler_index = argv.index("--bundler")
      if bundler_index
        bundler_value = argv[bundler_index + 1]
        unless bundler_value && %w[webpack rspack].include?(bundler_value)
          $stderr.puts "[Shakapacker] Error: --bundler requires 'webpack' or 'rspack'"
          $stderr.puts "Usage: bin/shakapacker --bundler <webpack|rspack>"
          exit(1)
        end
        bundler_override = bundler_value
      end

      # Check for --build flag
      build_index = argv.index("--build")
      if build_index
        build_name = argv[build_index + 1]

        unless build_name
          $stderr.puts "[Shakapacker] Error: --build requires a build name"
          $stderr.puts "Usage: bin/shakapacker --build <name>"
          exit(1)
        end

        loader = BuildConfigLoader.new

        unless loader.exists?
          $stderr.puts "[Shakapacker] Config file not found: #{loader.config_file_path}"
          $stderr.puts "Run 'bin/shakapacker --init' to create one"
          exit(1)
        end

        begin
          # Pass bundler override to resolve_build_config
          resolve_opts = {}
          resolve_opts[:default_bundler] = bundler_override if bundler_override
          build_config = loader.resolve_build_config(build_name, **resolve_opts)

          # Remove --build and build name from argv
          remaining_argv = argv.dup
          remaining_argv.delete_at(build_index + 1)
          remaining_argv.delete_at(build_index)

          # Remove --bundler and bundler value from argv if present
          if bundler_index
            bundler_idx_in_remaining = remaining_argv.index("--bundler")
            if bundler_idx_in_remaining
              remaining_argv.delete_at(bundler_idx_in_remaining + 1)
              remaining_argv.delete_at(bundler_idx_in_remaining)
            end
          end

          # If this build uses dev server, delegate to DevServerRunner
          if loader.uses_dev_server?(build_config)
            log = log_output_for(argv)
            log.puts "[Shakapacker] Build '#{build_name}' requires dev server"
            log.puts "[Shakapacker] Running: bin/shakapacker-dev-server --build #{build_name}"
            log.puts ""
            require_relative "dev_server_runner"
            DevServerRunner.run_with_build_config(remaining_argv, build_config)
            return
          end

          # Otherwise run with this build config
          run_with_build_config(remaining_argv, build_config)
          return
        rescue ArgumentError => e
          $stderr.puts "[Shakapacker] #{e.message}"
          exit(1)
        end
      end

      Shakapacker.ensure_node_env!

      # Remove --bundler flag from argv if present (not using --build)
      remaining_argv = argv.dup
      if bundler_index
        bundler_idx = remaining_argv.index("--bundler")
        if bundler_idx
          remaining_argv.delete_at(bundler_idx + 1)
          remaining_argv.delete_at(bundler_idx)
        end
      end

      # Set SHAKAPACKER_ASSETS_BUNDLER if bundler override is specified
      # This ensures JS/TS config files use the correct bundler
      ENV["SHAKAPACKER_ASSETS_BUNDLER"] = bundler_override if bundler_override

      # Create a single runner instance to avoid loading configuration twice.
      # We extend it with the appropriate build command based on the bundler type.
      runner = new(remaining_argv, nil, bundler_override)

      # Determine which bundler to use (override takes precedence)
      use_rspack = bundler_override ? (bundler_override == "rspack") : runner.config.rspack?

      if use_rspack
        require_relative "rspack_runner"
        # Extend the runner instance with rspack-specific methods
        # This avoids creating a new RspackRunner which would reload the configuration
        runner.extend(Module.new do
          def build_cmd
            package_json.manager.native_exec_command("rspack")
          end

          def assets_bundler_commands
            BASE_COMMANDS + %w[build watch]
          end
        end)
        runner.run
      else
        require_relative "webpack_runner"
        # Extend the runner instance with webpack-specific methods
        # This avoids creating a new WebpackRunner which would reload the configuration
        runner.extend(Module.new do
          def build_cmd
            package_json.manager.native_exec_command("webpack")
          end
        end)
        runner.run
      end
    end

    def self.run_with_build_config(argv, build_config)
      $stdout.sync = true
      Shakapacker.ensure_node_env!

      # Apply build config environment variables
      build_config[:environment].each do |key, value|
        ENV[key] = value.to_s
      end

      # Set SHAKAPACKER_ASSETS_BUNDLER so JS/TS config files use the correct bundler
      # This ensures the bundler override (from --bundler or build config) is respected
      ENV["SHAKAPACKER_ASSETS_BUNDLER"] = build_config[:bundler]

      log = log_output_for(argv)
      log.puts "[Shakapacker] Running build: #{build_config[:name]}"
      log.puts "[Shakapacker] Description: #{build_config[:description]}" if build_config[:description]
      log.puts "[Shakapacker] Bundler: #{build_config[:bundler]}"
      log.puts "[Shakapacker] Config file: #{build_config[:config_file]}" if build_config[:config_file]

      # Create runner with modified argv and bundler from build_config
      # The build_config[:bundler] already has any CLI --bundler override applied
      runner = new(argv, build_config, build_config[:bundler])

      # Use bundler from build_config (which includes CLI override)
      if build_config[:bundler] == "rspack"
        require_relative "rspack_runner"
        runner.extend(Module.new do
          def build_cmd
            package_json.manager.native_exec_command("rspack")
          end

          def assets_bundler_commands
            BASE_COMMANDS + %w[build watch]
          end
        end)
        runner.run
      else
        require_relative "webpack_runner"
        runner.extend(Module.new do
          def build_cmd
            package_json.manager.native_exec_command("webpack")
          end
        end)
        runner.run
      end
    end

    def initialize(argv, build_config = nil, bundler_override = nil)
      @argv = argv
      @build_config = build_config
      @bundler_override = bundler_override
      @json_output = self.class.json_output?(argv)

      @app_path           = File.expand_path(".", Dir.pwd)
      @shakapacker_config = ENV["SHAKAPACKER_CONFIG"] || File.join(@app_path, "config/shakapacker.yml")

      # Create config with bundler override if provided
      config_opts = {
        root_path: Pathname.new(@app_path),
        config_path: Pathname.new(@shakapacker_config),
        env: ENV["RAILS_ENV"] || ENV["NODE_ENV"] || "development"
      }
      config_opts[:bundler_override] = bundler_override if bundler_override

      @config = Configuration.new(**config_opts)

      @webpack_config = find_webpack_config_from_build_or_default

      Shakapacker::Utils::Manager.error_unless_package_manager_is_obvious!
    end

    def package_json
      @package_json ||= PackageJson.read(@app_path)
    end

    def run
      log_output.puts "[Shakapacker] Preparing environment for assets bundler execution..."
      env = Shakapacker::Compiler.env
      env["SHAKAPACKER_CONFIG"] = @shakapacker_config
      env["NODE_OPTIONS"] = ENV["NODE_OPTIONS"] || ""

      cmd = build_cmd
      log_output.puts "[Shakapacker] Base command: #{cmd.join(" ")}"

      if @argv.delete("--debug-shakapacker")
        log_output.puts "[Shakapacker] Debug mode enabled (--debug-shakapacker)"
        env["NODE_OPTIONS"] = "#{env["NODE_OPTIONS"]} --inspect-brk"
      end

      if @argv.delete "--trace-deprecation"
        log_output.puts "[Shakapacker] Trace deprecation enabled (--trace-deprecation)"
        env["NODE_OPTIONS"] = "#{env["NODE_OPTIONS"]} --trace-deprecation"
      end

      if @argv.delete "--no-deprecation"
        log_output.puts "[Shakapacker] Deprecation warnings disabled (--no-deprecation)"
        env["NODE_OPTIONS"] = "#{env["NODE_OPTIONS"]} --no-deprecation"
      end

      # Commands are not compatible with --config option.
      if (@argv & assets_bundler_commands).empty?
        log_output.puts "[Shakapacker] Adding config file: #{@webpack_config}"
        cmd += ["--config", @webpack_config]
      else
        log_output.puts "[Shakapacker] Skipping config file (running assets bundler command: #{(@argv & assets_bundler_commands).join(", ")})"
      end

      cmd += @argv
      log_output.puts "[Shakapacker] Final command: #{cmd.join(" ")}"
      log_output.puts "[Shakapacker] Working directory: #{@app_path}"

      watch_mode = @argv.include?("--watch") || @argv.include?("-w")
      start_time = Time.now unless watch_mode

      Dir.chdir(@app_path) do
        child_pid = nil
        trap("TERM") do
          if child_pid
            Process.kill("TERM", child_pid)
          else
            # Signal arrived before spawn completed; re-raise so the process exits normally.
            raise SignalException, "TERM"
          end
        rescue Errno::ESRCH
          nil
        end
        child_pid = spawn(env, *cmd)
        Process.wait(child_pid)
      end

      if !watch_mode && start_time
        bundler_name = @config.rspack? ? "rspack" : "webpack"
        elapsed_time = Time.now - start_time
        minutes = (elapsed_time / 60).floor
        seconds = (elapsed_time % 60).round(2)
        time_display = minutes > 0 ? "#{minutes}:#{format('%05.2f', seconds)}s" : "#{elapsed_time.round(2)}s"
        log_output.puts "[Shakapacker] Completed #{bundler_name} build in #{time_display} (#{elapsed_time.round(2)}s)"
      end
      exit($?.exitstatus || 1) unless $?.success?
    end

    protected

      def assets_bundler_commands
        BASE_COMMANDS
      end

      def print_config_not_found_error(bundler_type, config_path, config_dir)
        $stderr.puts "[Shakapacker] ERROR: #{bundler_type} config #{config_path} not found."
        $stderr.puts ""
        $stderr.puts "Please run 'bundle exec rake shakapacker:install' to install Shakapacker with default configs,"
        $stderr.puts "or create the missing config file."
        $stderr.puts ""
        $stderr.puts "If your config file is in a different location, you can configure it in config/shakapacker.yml:"
        $stderr.puts ""
        $stderr.puts "  assets_bundler_config_path: your/custom/path"
        $stderr.puts ""
        $stderr.puts "Current configured path: #{config_dir}"
      end

      def self.print_help(verbose: false)
        puts <<~HELP
        ================================================================================
        SHAKAPACKER - Rails Webpack/Rspack Integration
        ================================================================================

        Usage: bin/shakapacker [options]

        Shakapacker-specific options:
          -h, --help                Show this help message
              --help=verbose        Show verbose help including all bundler options
          -v, --version             Show Shakapacker version
          --debug-shakapacker       Enable Node.js debugging (--inspect-brk)
          --trace-deprecation       Show stack traces for deprecations
          --no-deprecation          Silence deprecation warnings
          --bundler <webpack|rspack>
                                    Override bundler (defaults to shakapacker.yml)

        Build configurations (config/shakapacker-builds.yml):
          --init                    Create config/shakapacker-builds.yml
          --list-builds             List available builds
          --build <name>            Run a specific build configuration

        Examples (build configs):
          bin/shakapacker --init                       # Create config file
          bin/shakapacker --list-builds                # Show available builds
          bin/shakapacker --build dev-hmr              # Run the 'dev-hmr' build
          bin/shakapacker --build prod                 # Run the 'prod' build
          bin/shakapacker --build prod --bundler rspack # Override to use rspack

          Note: If a build has dev_server: true in its config, it will
          automatically use bin/shakapacker-dev-server instead.

          Advanced: Use bin/shakapacker-config for more config management options
          (validate builds, export configs, etc.)

        HELP

        print_bundler_help(verbose: verbose)

        puts <<~HELP

        Examples (passing options to webpack/rspack):
          bin/shakapacker                              # Build for production
          bin/shakapacker --bundler rspack             # Build with rspack instead of webpack
          bin/shakapacker --mode development           # Build for development
          bin/shakapacker --watch                      # Watch mode
          bin/shakapacker --mode development --analyze # Development build with analysis
          bin/shakapacker --debug-shakapacker          # Debug with Node inspector

        Options managed by Shakapacker (configured via config files):
          --config                  Set automatically based on assets_bundler_config_path
                                    (defaults to config/webpack or config/rspack)
          --node-env                Set from RAILS_ENV or NODE_ENV
        HELP
      end

      def self.print_bundler_help(verbose: false)
        help_flag = verbose ? "--help=verbose" : "--help"
        bundler_type, bundler_help = get_bundler_help(help_flag)

        if bundler_help
          bundler_name = bundler_type == :rspack ? "RSPACK" : "WEBPACK"
          puts "=" * 80
          puts "AVAILABLE #{bundler_name} OPTIONS (Passed directly to #{bundler_name.downcase})"
          puts "=" * 80
          puts
          puts filter_managed_options(bundler_help)
          puts
          puts "For complete documentation:"
          if bundler_type == :rspack
            puts "  https://rspack.dev/api/cli"
          else
            puts "  https://webpack.js.org/api/cli/"
          end
        else
          puts "For complete documentation:"
          puts "  Webpack: https://webpack.js.org/api/cli/"
          puts "  Rspack:  https://rspack.dev/api/cli"
        end
      end

      def self.get_bundler_help(help_flag = "--help")
        execute_bundler_command(help_flag) { |stdout| stdout }
      end

      # Filter bundler help output to remove Shakapacker-managed options
      #
      # This method processes the raw help output from webpack/rspack and removes:
      # 1. Command sections (e.g., "Commands: webpack build")
      # 2. Options that Shakapacker manages automatically (--config, --nodeEnv, etc.)
      # 3. Help/version flags (shown separately in Shakapacker's help)
      #
      # The filtering uses stateful line-by-line processing:
      # - in_commands_section: tracks when we're inside a Commands: block
      # - skip_until_blank: tracks multi-line option descriptions to skip entirely
      #
      # Note: This relies on bundler help format conventions. If webpack/rspack
      # significantly changes their help output format, this may need adjustment.
      def self.filter_managed_options(help_text)
        lines = help_text.lines
        filtered_lines = []
        skip_until_blank = false
        in_commands_section = false

        lines.each do |line|
          # Skip the [options] line and Commands section headers
          # These appear in formats like "[options]" or "Commands:"
          if line.match?(/^\[options\]/) || line.match?(/^Commands:/)
            in_commands_section = true
            next
          end

          # Continue skipping until we exit the commands section
          # Exit when we hit "Options:" header or double blank lines
          if in_commands_section
            if line.match?(/^Options:/) || (line.strip.empty? && filtered_lines.last&.strip&.empty?)
              in_commands_section = false
            else
              next
            end
          end

          # Skip options that Shakapacker manages and their descriptions
          # These options are shown in the "Options managed by Shakapacker" section
          if line.match?(/^\s*(-c,\s*)?--config\b/) ||
             line.match?(/^\s*--configName\b/) ||
             line.match?(/^\s*--configLoader\b/) ||
             line.match?(/^\s*--nodeEnv\b/) ||
             line.match?(/^\s*(-h,\s*)?--help\b/) ||
             line.match?(/^\s*(-v,\s*)?--version\b/)
            skip_until_blank = true
            next
          end

          # Continue skipping lines that are part of a filtered option's description
          # Reset when we hit a blank line or the start of a new option (starts with -)
          if skip_until_blank
            if line.strip.empty? || line.match?(/^\s*-/)
              skip_until_blank = false
            else
              next
            end
          end

          filtered_lines << line
        end

        filtered_lines.join
      end

      def self.print_version
        puts "Shakapacker #{Shakapacker::VERSION}"
        puts "Framework: Rails #{Rails.version}" if defined?(Rails)

        # Try to get bundler version
        bundler_type, bundler_version = get_bundler_version
        if bundler_version
          bundler_name = bundler_type == :rspack ? "Rspack" : "Webpack"
          puts "Bundler: #{bundler_name} #{bundler_version}"
        end
      end

      def self.init_config_file
        loader = BuildConfigLoader.new
        config_path = loader.config_file_path

        if loader.exists?
          puts "[Shakapacker] Config file already exists: #{config_path}"
          puts "Use --list-builds to see available builds"
          return
        end

        # Delegate to bin/shakapacker-config
        app_path = File.expand_path(".", Dir.pwd)
        shakapacker_config_path = File.join(app_path, "bin", "shakapacker-config")

        unless File.exist?(shakapacker_config_path)
          $stderr.puts "[Shakapacker] Error: bin/shakapacker-config not found"
          $stderr.puts "Please ensure Shakapacker is properly installed"
          exit(1)
        end

        # Run the init command and check if it succeeded
        unless system(shakapacker_config_path, "--init")
          exit_code = $?.exitstatus || 1
          $stderr.puts "[Shakapacker] Error: Failed to run: #{shakapacker_config_path} --init"
          $stderr.puts "[Shakapacker] Command exited with status: #{exit_code}"
          exit(exit_code)
        end
      end

      def self.list_builds
        loader = BuildConfigLoader.new

        unless loader.exists?
          puts "[Shakapacker] No config file found: #{loader.config_file_path}"
          puts "Run 'bin/shakapacker --init' to create one"
          return
        end

        begin
          loader.list_builds
        rescue ArgumentError => e
          $stderr.puts "[Shakapacker] Error: #{e.message}"
          exit(1)
        end
      end

      def self.get_bundler_version
        execute_bundler_command("--version") { |stdout| stdout.strip }
      end

      # Shared helper to execute bundler commands with output suppression
      # Returns [bundler_type, processed_output] or [nil, nil] on error
      #
      # @param bundler_args [String, Array<String>] Arguments to pass to bundler command
      # @yield [stdout] Block to process the command output
      # @yieldparam stdout [String] The raw stdout from the bundler command
      # @yieldreturn [Object] The processed output to return
      def self.execute_bundler_command(*bundler_args)
        # Check if we're in a Rails project with necessary files
        app_path = File.expand_path(".", Dir.pwd)
        config_path = ENV["SHAKAPACKER_CONFIG"] || File.join(app_path, "config/shakapacker.yml")
        return [nil, nil] unless File.exist?(config_path)

        original_stdout = $stdout
        original_stderr = $stderr

        begin
          # Suppress any output during config loading
          $stdout = StringIO.new
          $stderr = StringIO.new

          # Try to detect bundler type
          runner = new([])
          return [nil, nil] unless runner.config

          bundler_type = runner.config.rspack? ? :rspack : :webpack
          bundler_name = bundler_type == :rspack ? "rspack" : "webpack"
          cmd = runner.package_json.manager.native_exec_command(bundler_name, bundler_args.flatten)

          # Restore output before running command
          $stdout = original_stdout
          $stderr = original_stderr

          # Capture command output
          require "open3"
          stdout, _stderr, status = Open3.capture3(*cmd)
          return [nil, nil] unless status.success?

          # Process output using the provided block
          processed_output = yield(stdout)
          [bundler_type, processed_output]
        rescue StandardError => e
          [nil, nil]
        ensure
          # Always restore output streams
          $stdout = original_stdout
          $stderr = original_stderr
        end
      end

    private

      # Returns the appropriate output stream for log messages.
      # When --json is used, log messages go to stderr to keep stdout clean for JSON.
      # Otherwise, log messages go to stdout as normal.
      def log_output
        @json_output ? $stderr : $stdout
      end

      def find_webpack_config_from_build_or_default
        if @build_config && @build_config[:config_file]
          File.join(@app_path, @build_config[:config_file])
        else
          find_assets_bundler_config
        end
      end

      def find_assets_bundler_config
        if @config.rspack?
          find_rspack_config_with_fallback
        else
          find_webpack_config
        end
      end

      def find_rspack_config_with_fallback
        config_dir = @config.assets_bundler_config_path

        # First try rspack-specific paths in the configured directory
        rspack_paths = %w[ts js].map do |ext|
          File.join(@app_path, config_dir, "rspack.config.#{ext}")
        end

        log_output.puts "[Shakapacker] Looking for Rspack config in: #{rspack_paths.join(", ")}"
        rspack_path = rspack_paths.find { |f| File.exist?(f) }
        if rspack_path
          log_output.puts "[Shakapacker] Found Rspack config: #{rspack_path}"
          return rspack_path
        end

        # Fallback to webpack config in the configured directory
        webpack_paths = %w[ts js].map do |ext|
          File.join(@app_path, config_dir, "webpack.config.#{ext}")
        end

        log_output.puts "[Shakapacker] Rspack config not found, checking for webpack config fallback..."
        webpack_path = webpack_paths.find { |f| File.exist?(f) }
        if webpack_path
          $stderr.puts "⚠️  DEPRECATION WARNING: Using webpack config file for Rspack assets bundler."
          $stderr.puts "   Please create #{config_dir}/rspack.config.js and migrate your configuration."
          $stderr.puts "   Using: #{webpack_path}"
          return webpack_path
        end

        # Backward compatibility: Check config/webpack/ if we were looking in config/rspack/
        # This supports upgrades from versions where rspack used config/webpack/
        if config_dir == "config/rspack"
          webpack_dir_paths = %w[ts js].map do |ext|
            File.join(@app_path, "config/webpack", "webpack.config.#{ext}")
          end

          log_output.puts "[Shakapacker] Checking config/webpack/ for backward compatibility..."
          webpack_dir_path = webpack_dir_paths.find { |f| File.exist?(f) }
          if webpack_dir_path
            $stderr.puts "⚠️  DEPRECATION WARNING: Found webpack config in config/webpack/ but assets_bundler is set to 'rspack'."
            $stderr.puts "   For rspack, configs should be in config/rspack/ directory."
            $stderr.puts "   "
            $stderr.puts "   To fix this, either:"
            $stderr.puts "   1. Move your config: mv config/webpack config/rspack"
            $stderr.puts "   2. Set assets_bundler_config_path in config/shakapacker.yml:"
            $stderr.puts "      assets_bundler_config_path: config/webpack"
            $stderr.puts "   "
            $stderr.puts "   Using: #{webpack_dir_path}"
            return webpack_dir_path
          end
        end

        # No config found
        print_config_not_found_error("rspack", rspack_paths.last, config_dir)
        exit(1)
      end

      def find_webpack_config
        config_dir = @config.assets_bundler_config_path

        possible_paths = %w[ts js].map do |ext|
          File.join(@app_path, config_dir, "webpack.config.#{ext}")
        end
        log_output.puts "[Shakapacker] Looking for Webpack config in: #{possible_paths.join(", ")}"
        path = possible_paths.find { |f| File.exist?(f) }
        unless path
          print_config_not_found_error("webpack", possible_paths.last, config_dir)
          exit(1)
        end
        log_output.puts "[Shakapacker] Found Webpack config: #{path}"
        path
      end
  end
end
