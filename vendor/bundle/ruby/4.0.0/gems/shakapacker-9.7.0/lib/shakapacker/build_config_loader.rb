require "yaml"

module Shakapacker
  class BuildConfigLoader
    attr_reader :config_file_path

    def initialize(config_file_path = nil)
      @config_file_path = config_file_path || File.join(Dir.pwd, "config", "shakapacker-builds.yml")
    end

    def exists?
      File.exist?(@config_file_path)
    end

    def load_build(build_name)
      unless exists?
        raise ArgumentError, "Config file not found: #{@config_file_path}\n" \
                            "Run 'bin/shakapacker --init' to generate a sample config file."
      end

      config = load_config
      fetch_build_or_raise(config, build_name)
    end

    def resolve_build_config(build_name, default_bundler: "webpack")
      config = load_config
      build = fetch_build_or_raise(config, build_name)

      # Resolve bundler with precedence: build.bundler > config.default_bundler > default_bundler
      bundler = build["bundler"] || config["default_bundler"] || default_bundler

      # Get environment variables
      environment = build["environment"] || {}

      # Get config file path if specified
      config_file = build["config"]
      if config_file
        # Expand ${BUNDLER} variable
        config_file = config_file.gsub("${BUNDLER}", bundler)
      end

      # Get bundler_env for --env flags
      bundler_env = build["bundler_env"] || {}

      # Get outputs
      outputs = build["outputs"] || []

      # Validate outputs
      if outputs.empty?
        raise ArgumentError, "Build '#{build_name}' has empty outputs array. " \
                            "Please specify at least one output type (client, server, or all)."
      end

      {
        name: build_name,
        description: build["description"],
        bundler: bundler,
        dev_server: build["dev_server"],
        environment: environment,
        bundler_env: bundler_env,
        outputs: outputs,
        config_file: config_file
      }
    end

    def uses_dev_server?(build_config)
      # Check explicit dev_server flag first (preferred)
      # Only return early if the value is explicitly set (not nil)
      return build_config[:dev_server] unless build_config[:dev_server].nil?

      # Fallback: check environment variables for backward compatibility
      env = build_config[:environment]
      return false unless env

      # Handle both string "true" and boolean true from YAML
      %w[WEBPACK_SERVE HMR].any? do |key|
        value = env[key]
        value.to_s.strip.casecmp("true").zero?
      end
    end

    def list_builds
      config = load_config
      builds = config["builds"]

      puts "\nAvailable builds in #{@config_file_path}:\n\n"

      builds.each do |name, build|
        bundler = build["bundler"] || config["default_bundler"] || "webpack (default)"
        outputs = build["outputs"] ? build["outputs"].join(", ") : "missing (invalid)"

        puts "  #{name}"
        puts "    Description: #{build["description"]}" if build["description"]
        puts "    Bundler: #{bundler}"
        puts "    Outputs: #{outputs}"
        puts ""
      end
    end

    private

      def fetch_build_or_raise(config, build_name)
        build = config["builds"][build_name]
        unless build
          available = config["builds"].keys.join(", ")
          raise ArgumentError, "Build '#{build_name}' not found in config file.\n" \
                              "Available builds: #{available}\n" \
                              "Use 'bin/shakapacker --list-builds' to see all available builds."
        end
        build
      end

      # Load YAML config file safely with Ruby version compatibility
      # Ruby 3.1+ supports safe_load_file with aliases, older versions need safe_load
      def load_config
        begin
          config = if YAML.respond_to?(:safe_load_file)
            # Ruby 3.1+: Use safe_load_file with aliases enabled
            YAML.safe_load_file(@config_file_path, aliases: true)
          else
            # Ruby 2.7-3.0: Use safe_load with aliases enabled
            YAML.safe_load(
              File.read(@config_file_path),
              permitted_classes: [],
              permitted_symbols: [],
              aliases: true
            )
          end
        rescue ArgumentError
          # Fallback for older Psych versions without aliases support
          config = YAML.safe_load(
            File.read(@config_file_path),
            permitted_classes: [],
            permitted_symbols: []
          )
        end

        unless config["builds"]&.is_a?(Hash)
          raise ArgumentError, "Config file must contain a 'builds' object"
        end

        config
      rescue Psych::SyntaxError => e
        raise ArgumentError, "Invalid YAML in config file: #{e.message}"
      end
  end
end
