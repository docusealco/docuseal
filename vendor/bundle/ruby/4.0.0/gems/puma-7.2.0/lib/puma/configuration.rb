# frozen_string_literal: true

require_relative 'plugin'
require_relative 'const'
require_relative 'dsl'
require_relative 'events'

module Puma
  # A class used for storing "leveled" configuration options.
  #
  # In this class any "user" specified options take precedence over any
  # "file" specified options, take precedence over any "default" options.
  #
  # User input is preferred over "defaults":
  #   user_options    = { foo: "bar" }
  #   default_options = { foo: "zoo" }
  #   options = UserFileDefaultOptions.new(user_options, default_options)
  #   puts options[:foo]
  #   # => "bar"
  #
  # All values can be accessed via `all_of`
  #
  #   puts options.all_of(:foo)
  #   # => ["bar", "zoo"]
  #
  # A "file" option can be set. This config will be preferred over "default" options
  # but will defer to any available "user" specified options.
  #
  #   user_options    = { foo: "bar" }
  #   default_options = { rackup: "zoo.rb" }
  #   options = UserFileDefaultOptions.new(user_options, default_options)
  #   options.file_options[:rackup] = "sup.rb"
  #   puts options[:rackup]
  #   # => "sup.rb"
  #
  # The "default" options can be set via procs. These are resolved during runtime
  # via calls to `finalize_values`
  class UserFileDefaultOptions
    def initialize(user_options, default_options)
      @user_options    = user_options
      @file_options    = {}
      @default_options = default_options
    end

    attr_reader :user_options, :file_options, :default_options

    def [](key)
      fetch(key)
    end

    def []=(key, value)
      user_options[key] = value
    end

    def fetch(key, default_value = nil)
      return user_options[key]    if user_options.key?(key)
      return file_options[key]    if file_options.key?(key)
      return default_options[key] if default_options.key?(key)

      default_value
    end

    def all_of(key)
      user    = user_options[key]
      file    = file_options[key]
      default = default_options[key]

      user    = [user]    unless user.is_a?(Array)
      file    = [file]    unless file.is_a?(Array)
      default = [default] unless default.is_a?(Array)

      user.compact!
      file.compact!
      default.compact!

      user + file + default
    end

    def finalize_values
      @default_options.each do |k,v|
        if v.respond_to? :call
          @default_options[k] = v.call
        end
      end
    end

    def final_options
      default_options
        .merge(file_options)
        .merge(user_options)
    end
  end

  # The main configuration class of Puma.
  #
  # It can be initialized with a set of "user" options and "default" options.
  # Defaults will be merged with `Configuration.puma_default_options`.
  #
  # This class works together with 2 main other classes the `UserFileDefaultOptions`
  # which stores configuration options in order so the precedence is that user
  # set configuration wins over "file" based configuration wins over "default"
  # configuration. These configurations are set via the `DSL` class. This
  # class powers the Puma config file syntax and does double duty as a configuration
  # DSL used by the `Puma::CLI` and Puma rack handler.
  #
  # It also handles loading plugins.
  #
  # [Note:]
  #   `:port` and `:host` are not valid keys. By the time they make it to the
  #   configuration options they are expected to be incorporated into a `:binds` key.
  #   Under the hood the DSL maps `port` and `host` calls to `:binds`
  #
  #     config = Configuration.new({}) do |user_config, file_config, default_config|
  #       user_config.port 3003
  #     end
  #     config.clamp
  #     puts config.options[:port]
  #     # => 3003
  #
  # It is expected that `load` is called on the configuration instance after setting
  # config. This method expands any values in `config_file` and puts them into the
  # correct configuration option hash.
  #
  # Once all configuration is complete it is expected that `clamp` will be called
  # on the instance. This will expand any procs stored under "default" values. This
  # is done because an environment variable may have been modified while loading
  # configuration files.
  class Configuration
    class NotLoadedError < StandardError; end
    class NotClampedError < StandardError; end

    DEFAULTS = {
      auto_trim_time: 30,
      binds: ['tcp://0.0.0.0:9292'.freeze],
      fiber_per_request: !!ENV.fetch("PUMA_FIBER_PER_REQUEST", false),
      debug: false,
      enable_keep_alives: true,
      early_hints: nil,
      environment: 'development'.freeze,
      # Number of seconds to wait until we get the first data for the request.
      first_data_timeout: 30,
      # Number of seconds to wait until the next request before shutting down.
      idle_timeout: nil,
      io_selector_backend: :auto,
      log_requests: false,
      logger: STDOUT,
      # Limits how many requests a keep alive connection can make.
      # The connection will be closed after it reaches `max_keep_alive`
      # requests.
      max_keep_alive: 999,
      max_threads: Puma.mri? ? 5 : 16,
      min_threads: 0,
      mode: :http,
      mutate_stdout_and_stderr_to_sync_on_write: true,
      out_of_band: [],
      # Number of seconds for another request within a persistent session.
      persistent_timeout: 65, # PUMA_PERSISTENT_TIMEOUT
      prune_bundler: false,
      queue_requests: true,
      rackup: 'config.ru'.freeze,
      raise_exception_on_sigterm: true,
      reaping_time: 1,
      remote_address: :socket,
      silence_single_worker_warning: false,
      silence_fork_callback_warning: false,
      tag: File.basename(Dir.getwd),
      tcp_host: '0.0.0.0'.freeze,
      tcp_port: 9292,
      wait_for_less_busy_worker: 0.005,
      worker_boot_timeout: 60,
      worker_check_interval: 5,
      worker_culling_strategy: :youngest,
      worker_shutdown_timeout: 30,
      worker_timeout: 60,
      workers: 0,
      http_content_length_limit: nil
    }

    def initialize(user_options={}, default_options = {}, env = ENV, &block)
      default_options = self.puma_default_options(env).merge(default_options)

      @_options    = UserFileDefaultOptions.new(user_options, default_options)
      @plugins     = PluginLoader.new
      @events      = @_options[:events] || Events.new
      @hooks       = {}
      @user_dsl    = DSL.new(@_options.user_options, self)
      @file_dsl    = DSL.new(@_options.file_options, self)
      @default_dsl = DSL.new(@_options.default_options, self)

      @puma_bundler_pruned = env.key? 'PUMA_BUNDLER_PRUNED'

      if block
        configure(&block)
      end

      @loaded = false
      @clamped = false
    end

    attr_reader :plugins, :events, :hooks, :_options

    def options
      raise NotClampedError, "ensure clamp is called before accessing options" unless @clamped

      @_options
    end

    def configure
      yield @user_dsl, @file_dsl, @default_dsl
    ensure
      @user_dsl._offer_plugins
      @file_dsl._offer_plugins
      @default_dsl._offer_plugins
    end

    def initialize_copy(other)
      @conf        = nil
      @cli_options = nil
      @_options     = @_options.dup
    end

    def flatten
      dup.flatten!
    end

    def flatten!
      @_options = @_options.flatten
      self
    end

    def puma_default_options(env = ENV)
      defaults = DEFAULTS.dup
      puma_options_from_env(env).each { |k,v| defaults[k] = v if v }
      defaults
    end

    def puma_options_from_env(env = ENV)
      min = env['PUMA_MIN_THREADS'] || env['MIN_THREADS']
      max = env['PUMA_MAX_THREADS'] || env['MAX_THREADS']
      persistent_timeout = env['PUMA_PERSISTENT_TIMEOUT']
      workers_env = env['WEB_CONCURRENCY']
      workers = workers_env && workers_env.strip != "" ? parse_workers(workers_env.strip) : nil

      {
        min_threads: min && min != "" && Integer(min),
        max_threads: max && max != "" && Integer(max),
        persistent_timeout: persistent_timeout && persistent_timeout != "" && Integer(persistent_timeout),
        workers: workers,
        environment: env['APP_ENV'] || env['RACK_ENV'] || env['RAILS_ENV'],
      }
    end

    def load
      @loaded = true
      config_files.each { |config_file| @file_dsl._load_from(config_file) }
      @_options
    end

    def config_files
      raise NotLoadedError, "ensure load is called before accessing config_files" unless @loaded

      files = @_options.all_of(:config_files)

      return [] if files == ['-']
      return files if files.any?

      first_default_file = %W(config/puma/#{@_options[:environment]}.rb config/puma.rb).find do |f|
        File.exist?(f)
      end

      [first_default_file]
    end

    # Call once all configuration (included from rackup files)
    # is loaded to finalize defaults and lock in the configuration.
    #
    # This also calls load if it hasn't been called yet.
    def clamp
      load unless @loaded
      set_conditional_default_options
      @_options.finalize_values
      @clamped = true
      warn_hooks
      options
    end

    # Injects the Configuration object into the env
    class ConfigMiddleware
      def initialize(config, app)
        @config = config
        @app = app
      end

      def call(env)
        env[Const::PUMA_CONFIG] = @config
        @app.call(env)
      end
    end

    # Indicate if there is a properly configured app
    #
    def app_configured?
      options[:app] || File.exist?(rackup)
    end

    def rackup
      options[:rackup]
    end

    # Load the specified rackup file, pull options from
    # the rackup file, and set @app.
    #
    def app
      found = options[:app] || load_rackup

      if options[:log_requests]
        require_relative 'commonlogger'
        logger = options[:custom_logger] ? options[:custom_logger] : options[:logger]
        found = CommonLogger.new(found, logger)
      end

      ConfigMiddleware.new(self, found)
    end

    # Return which environment we're running in
    def environment
      options[:environment]
    end

    def load_plugin(name)
      @plugins.create name
    end

    # @param key [:Symbol] hook to run
    # @param arg [Launcher, Int] `:before_restart` passes Launcher
    #
    def run_hooks(key, arg, log_writer, hook_data = nil)
      log_writer.debug "Running #{key} hooks"

      options.all_of(key).each do |hook_options|
        begin
          block = hook_options[:block]
          if id = hook_options[:id]
            hook_data[id] ||= Hash.new
            block.call arg, hook_data[id]
          else
            block.call arg
          end
        rescue => e
          log_writer.log "WARNING hook #{key} failed with exception (#{e.class}) #{e.message}"
          log_writer.debug e.backtrace.join("\n")
        end
      end
    end

    def final_options
      options.final_options
    end

    def self.temp_path
      require 'tmpdir'

      t = (Time.now.to_f * 1000).to_i
      "#{Dir.tmpdir}/puma-status-#{t}-#{$$}"
    end

    def self.random_token
      require 'securerandom' unless defined?(SecureRandom)

      SecureRandom.hex(16)
    end

    private

    def require_processor_counter
      require 'concurrent/utility/processor_counter'
    rescue LoadError
      warn <<~MESSAGE
        WEB_CONCURRENCY=auto or workers(:auto) requires the "concurrent-ruby" gem to be installed.
        Please add "concurrent-ruby" to your Gemfile.
      MESSAGE
      raise
    end

    def parse_workers(value)
      if value == :auto || value == 'auto'
        require_processor_counter
        Integer(::Concurrent.available_processor_count)
      else
        Integer(value)
      end
    rescue ArgumentError, TypeError
      raise ArgumentError, "workers must be an Integer or :auto"
    end

    # Load and use the normal Rack builder if we can, otherwise
    # fallback to our minimal version.
    def rack_builder
      # Load bundler now if we can so that we can pickup rack from
      # a Gemfile
      if @puma_bundler_pruned
        begin
          require 'bundler/setup'
        rescue LoadError
        end
      end

      begin
        require 'rack'
        require 'rack/builder'
        ::Rack::Builder
      rescue LoadError
        require_relative 'rack/builder'
        Puma::Rack::Builder
      end
    end

    def load_rackup
      raise "Missing rackup file '#{rackup}'" unless File.exist?(rackup)

      rack_app, rack_options = rack_builder.parse_file(rackup)
      rack_options = rack_options || {}

      options.file_options.merge!(rack_options)

      config_ru_binds = []
      rack_options.each do |k, v|
        config_ru_binds << v if k.to_s.start_with?("bind")
      end

      options.file_options[:binds] = config_ru_binds unless config_ru_binds.empty?

      rack_app
    end

    def set_conditional_default_options
      @_options.default_options[:preload_app] = !@_options[:prune_bundler] &&
        (@_options[:workers] > 1) && Puma.forkable?
    end

    def warn_hooks
      return if options[:workers] > 0
      return if options[:silence_fork_callback_warning]

      log_writer = LogWriter.stdio
      @hooks.each_key do |hook|
        options.all_of(hook).each do |hook_options|
          next unless hook_options[:cluster_only]

          log_writer.log(<<~MSG.tr("\n", " "))
            Warning: The code in the `#{hook}` block will not execute
            in the current Puma configuration. The `#{hook}` block only
            executes in Puma's cluster mode. To fix this, either remove the
            `#{hook}` call or increase Puma's worker count above zero.
          MSG
        end
      end
    end
  end
end
