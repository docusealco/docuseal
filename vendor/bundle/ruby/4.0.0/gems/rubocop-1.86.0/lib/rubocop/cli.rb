# frozen_string_literal: true

require 'fileutils'

module RuboCop
  # The CLI is a class responsible of handling all the command line interface
  # logic.
  class CLI
    STATUS_SUCCESS     = 0
    STATUS_OFFENSES    = 1
    STATUS_ERROR       = 2
    STATUS_INTERRUPTED = Signal.list['INT'] + 128
    DEFAULT_PARALLEL_OPTIONS = %i[
      color config debug display_style_guide display_time display_only_fail_level_offenses
      display_only_failed editor_mode except extra_details fail_level fix_layout format formatters
      ignore_disable_comments lint only only_guide_cops require safe
      autocorrect safe_autocorrect autocorrect_all
    ].freeze

    class Finished < StandardError; end

    attr_reader :options, :config_store

    def initialize
      @options = {}
      @config_store = ConfigStore.new
    end

    # @api public
    #
    # Entry point for the application logic. Here we
    # do the command line arguments processing and inspect
    # the target files.
    #
    # @param args [Array<String>] command line arguments
    # @return [Integer] UNIX exit code
    #
    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def run(args = ARGV)
      time_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      @options, paths = Options.new.parse(args)
      @env = Environment.new(@options, @config_store, paths)

      profile_if_needed do
        if @options[:init]
          run_command(:init)
        else
          act_on_options
          validate_options_vs_config
          parallel_by_default!
          apply_default_formatter
          report_pending_cops
          execute_runners
        end
      end
    rescue ConfigNotFoundError, IncorrectCopNameError, OptionArgumentError => e
      warn Rainbow(e.message).red
      STATUS_ERROR
    rescue RuboCop::Error => e
      warn Rainbow("Error: #{e.message}").red
      STATUS_ERROR
    rescue Interrupt
      warn ''
      warn 'Exiting...'
      STATUS_INTERRUPTED
    rescue Finished
      STATUS_SUCCESS
    rescue OptionParser::ParseError => e
      warn e.message
      warn 'For usage information, use --help'
      STATUS_ERROR
    rescue StandardError, SyntaxError, LoadError => e
      warn e.message
      warn e.backtrace
      STATUS_ERROR
    ensure
      elapsed_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - time_start
      if @options[:debug] || @options[:display_time]
        puts "Finished in #{elapsed_time.round(5)} seconds"
      end
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    private

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def profile_if_needed
      return yield unless @options[:profile]

      return STATUS_ERROR unless require_gem('stackprof')

      with_memory = @options[:memory]
      if with_memory
        return STATUS_ERROR unless require_gem('memory_profiler')

        MemoryProfiler.start
      end

      tmp_dir = File.join(ConfigFinder.project_root, 'tmp')
      FileUtils.mkdir_p(tmp_dir)
      cpu_profile_file = File.join(tmp_dir, 'rubocop-stackprof.dump')
      status = nil

      StackProf.run(out: cpu_profile_file) do
        status = yield
      end
      puts "Profile report generated at #{cpu_profile_file}"

      if with_memory
        puts 'Building memory report...'
        report = MemoryProfiler.stop
        memory_profile_file = File.join(tmp_dir, 'rubocop-memory_profiler.txt')
        report.pretty_print(to_file: memory_profile_file, scale_bytes: true)
        puts "Memory report generated at #{memory_profile_file}"
      end
      status
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    def require_gem(name)
      require name
      true
    rescue LoadError
      warn("You don't have #{name} installed. Add it to your Gemfile and run `bundle install`")
      false
    end

    def run_command(name)
      @env.run(name)
    end

    def execute_runners
      if @options[:auto_gen_config]
        run_command(:auto_gen_config)
      else
        run_command(:execute_runner).tap { suggest_extensions }
      end
    end

    def suggest_extensions
      run_command(:suggest_extensions)
    end

    def validate_options_vs_config
      return unless @options[:parallel] && !@config_store.for_pwd.for_all_cops['UseCache']

      raise OptionArgumentError, '-P/--parallel uses caching to speed up execution, so combining ' \
                                 'with AllCops: UseCache: false is not allowed.'
    end

    def parallel_by_default!
      # See https://github.com/rubocop/rubocop/pull/4537 for JRuby and Windows constraints.
      return if RUBY_ENGINE != 'ruby' || RuboCop::Platform.windows?

      if (@options.keys - DEFAULT_PARALLEL_OPTIONS).empty? &&
         @config_store.for_pwd.for_all_cops['UseCache'] != false
        puts 'Use parallel by default.' if @options[:debug]

        @options[:parallel] = true
      end
    end

    def act_on_options
      set_options_to_config_loader
      set_options_to_pending_cops_reporter
      handle_editor_mode

      @config_store.apply_options!(@options)
      # Set cache root after apply_options! to ensure force_default_config is applied first.
      early_cache_root = ConfigLoader.cache_root(@options[:cache_root])
      ConfigLoader.cache_root = ResultCache.cache_root(@config_store, @options[:cache_root])
      warn_if_cache_root_changed(early_cache_root, ConfigLoader.cache_root)

      handle_exiting_options

      if @options[:color]
        # color output explicitly forced on
        Rainbow.enabled = true
      elsif @options[:color] == false
        # color output explicitly forced off
        Rainbow.enabled = false
      end
    end

    def set_options_to_config_loader
      ConfigLoader.debug = @options[:debug]
      ConfigLoader.disable_pending_cops = @options[:disable_pending_cops]
      ConfigLoader.enable_pending_cops = @options[:enable_pending_cops]
      ConfigLoader.ignore_parent_exclusion = @options[:ignore_parent_exclusion]
      ConfigLoader.ignore_unrecognized_cops = @options[:ignore_unrecognized_cops]
    end

    def set_options_to_pending_cops_reporter
      PendingCopsReporter.disable_pending_cops = @options[:disable_pending_cops]
      PendingCopsReporter.enable_pending_cops = @options[:enable_pending_cops]
    end

    def handle_editor_mode
      RuboCop::LSP.enable if @options[:editor_mode]
    end

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def handle_exiting_options
      return unless Options::EXITING_OPTIONS.any? { |o| @options.key? o }

      run_command(:version) if @options[:version] || @options[:verbose_version]
      run_command(:show_cops) if @options[:show_cops]
      run_command(:show_docs_url) if @options[:show_docs_url]
      run_command(:lsp) if @options[:lsp]
      run_command(:mcp) if @options[:mcp]
      raise Finished
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def apply_default_formatter
      # This must be done after the options have already been processed,
      # because they can affect how ConfigStore behaves
      @options[:formatters] ||= begin
        if @options[:auto_gen_config]
          formatter = 'autogenconf'
        else
          cfg = @config_store.for_pwd.for_all_cops
          formatter = cfg['DefaultFormatter'] || 'progress'
        end
        [[formatter, @options[:output_path]]]
      end
    end

    def report_pending_cops
      PendingCopsReporter.warn_if_needed(@config_store.for_pwd)
    end

    def warn_if_cache_root_changed(early, desired)
      return if early == desired
      # Normalize paths to avoid false positives from symlink resolution differences
      if File.exist?(early) && File.exist?(desired) &&
         File.realpath(early) == File.realpath(desired)
        return
      end

      warn Rainbow(
        "Warning: Remote configuration cache files were stored in `#{early}` " \
        "because a desired cache root (`#{desired}`) was not set at the top level. " \
        'Consider setting `AllCops: CacheRootDirectory` in your toplevel configuration file, ' \
        'using the `RUBOCOP_CACHE_ROOT` environment variable, or using CLI options.'
      ).yellow
    end
  end
end
