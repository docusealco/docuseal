require "yaml"
require "json"
require "active_support/core_ext/hash/keys"
require "active_support/core_ext/hash/indifferent_access"

# Configuration management for Shakapacker
#
# Loads and provides access to settings from +config/shakapacker.yml+, including:
# - Source and output paths
# - Compilation settings
# - Dev server configuration
# - Asset bundler selection (webpack vs rspack)
# - JavaScript transpiler configuration (babel, swc, esbuild)
#
# Configuration values can be overridden via environment variables:
# - +SHAKAPACKER_CONFIG+ - path to config file
# - +SHAKAPACKER_PRECOMPILE+ - whether to precompile assets
# - +SHAKAPACKER_ASSETS_BUNDLER+ - which bundler to use
# - +SHAKAPACKER_ASSET_HOST+ - CDN or asset host URL
#
# @example Accessing configuration
#   config = Shakapacker.config
#   config.source_path
#   #=> #<Pathname:/app/app/packs>
#   config.webpack?
#   #=> true
#
# @see https://github.com/shakacode/shakapacker/blob/main/docs/shakapacker.yml.md
class Shakapacker::Configuration
  class << self
    # Flag indicating whether Shakapacker is currently being installed
    # Used to suppress certain validations during installation
    # @return [Boolean] true if installation is in progress
    # @api private
    attr_accessor :installing
  end

  # The application root path
  # @return [Pathname] the root path
  attr_reader :root_path

  # The path to the shakapacker.yml configuration file
  # @return [Pathname] the config file path
  attr_reader :config_path

  # The current Rails environment
  # @return [ActiveSupport::StringInquirer] the environment
  attr_reader :env

  # Override for the assets bundler (set via CLI flag)
  # @return [String, nil] the bundler override or nil
  # @api private
  attr_reader :bundler_override

  # Creates a new configuration instance
  #
  # @param root_path [Pathname] the application root path
  # @param config_path [Pathname] the path to shakapacker.yml
  # @param env [ActiveSupport::StringInquirer] the Rails environment
  # @param bundler_override [String, nil] optional bundler override (webpack or rspack)
  # @return [Shakapacker::Configuration] the new configuration instance
  def initialize(root_path:, config_path:, env:, bundler_override: nil)
    @root_path = root_path
    @env = env
    @config_path = config_path
    @bundler_override = bundler_override
  end

  # Returns the dev server configuration hash
  #
  # Contains settings like host, port, https, hmr, etc. for the webpack-dev-server.
  #
  # @return [Hash] the dev server configuration
  def dev_server
    fetch(:dev_server)
  end

  # Returns whether automatic compilation is enabled
  #
  # When true, Shakapacker will automatically compile assets when they're requested
  # and are stale. This is typically enabled in development and disabled in production.
  #
  # @return [Boolean] true if automatic compilation is enabled
  def compile?
    fetch(:compile)
  end

  # Returns whether nested entries are enabled
  #
  # When true, allows organizing entry points in subdirectories within the
  # source entry path.
  #
  # @return [Boolean] true if nested entries are allowed
  def nested_entries?
    fetch(:nested_entries)
  end

  # Returns whether consistent versioning check is enabled
  #
  # When true, verifies that package.json and Gemfile versions of shakapacker match.
  #
  # @return [Boolean] true if version consistency checking is enabled
  def ensure_consistent_versioning?
    fetch(:ensure_consistent_versioning)
  end

  # Returns whether Shakapacker should precompile assets
  #
  # Checks in order:
  # 1. SHAKAPACKER_PRECOMPILE environment variable (yes/true/y/t or no/false/n/f)
  # 2. shakapacker_precompile setting in config file
  # 3. Defaults to false if config file doesn't exist
  #
  # @return [Boolean] true if assets should be precompiled
  def shakapacker_precompile?
    # ENV of false takes precedence
    return false if %w(no false n f).include?(ENV["SHAKAPACKER_PRECOMPILE"])
    return true if %w(yes true y t).include?(ENV["SHAKAPACKER_PRECOMPILE"])

    return false unless config_path.exist?
    fetch(:shakapacker_precompile)
  end

  # Returns the absolute path to the source directory
  #
  # This is where your JavaScript/CSS source files live (e.g., app/packs).
  #
  # @return [Pathname] the absolute source path
  def source_path
    root_path.join(fetch(:source_path))
  end

  # Returns additional paths to include in compilation
  #
  # These paths are added to webpack/rspack's resolve configuration to allow
  # importing modules from additional directories.
  #
  # @return [Array<String>] array of additional paths
  def additional_paths
    fetch(:additional_paths)
  end

  # Returns the absolute path to the source entry directory
  #
  # Entry points (application.js, etc.) are found in this directory.
  #
  # @return [Pathname] the absolute entry path
  def source_entry_path
    source_path.join(relative_path(fetch(:source_entry_path)))
  end

  # Returns the absolute path to the manifest.json file
  #
  # The manifest maps source file names to their compiled output paths with digests.
  # Defaults to manifest.json in the public output directory if not configured.
  #
  # @return [Pathname] the absolute manifest path
  def manifest_path
    if data.has_key?(:manifest_path)
      root_path.join(fetch(:manifest_path))
    else
      public_output_path.join("manifest.json")
    end
  end

  # Alias for {#manifest_path}
  #
  # @return [Pathname] the absolute manifest path
  # @see #manifest_path
  def public_manifest_path
    manifest_path
  end

  # Returns the absolute path to the public root directory
  #
  # This is typically the Rails +public/+ directory where compiled assets
  # are served from.
  #
  # @return [Pathname] the absolute public path
  def public_path
    root_path.join(fetch(:public_root_path))
  end

  # Returns the absolute path to the private output directory
  #
  # The private output path is for server-side bundles (e.g., SSR) that should
  # not be publicly accessible. Returns nil if not configured.
  #
  # @return [Pathname, nil] the absolute private output path or nil
  def private_output_path
    private_path = fetch(:private_output_path)
    return nil if private_path.blank?
    validate_output_paths!
    root_path.join(private_path)
  end

  # Returns the absolute path to the public output directory
  #
  # This is where compiled assets are written for public serving
  # (typically +public/packs+).
  #
  # @return [Pathname] the absolute public output path
  def public_output_path
    public_path.join(fetch(:public_output_path))
  end

  # Returns whether manifest caching is enabled
  #
  # When true, the manifest.json file is cached in memory and only reloaded
  # when it changes. This improves performance in production.
  #
  # @return [Boolean] true if manifest should be cached
  def cache_manifest?
    fetch(:cache_manifest)
  end

  # Returns the absolute path to the compilation cache directory
  #
  # Webpack/rspack uses this directory to cache compilation results for faster
  # subsequent builds.
  #
  # @return [Pathname] the absolute cache path
  def cache_path
    root_path.join(fetch(:cache_path))
  end

  # Returns whether webpack/rspack compilation output should be shown
  #
  # When true, displays webpack/rspack's compilation progress and results.
  #
  # @return [Boolean] true if compilation output should be displayed
  def webpack_compile_output?
    fetch(:webpack_compile_output)
  end

  # Returns the compiler strategy for determining staleness
  #
  # Options:
  # - +"mtime"+ - use file modification times (faster, less accurate)
  # - +"digest"+ - use file content digests (slower, more accurate)
  #
  # @return [String] the compiler strategy ("mtime" or "digest")
  def compiler_strategy
    fetch(:compiler_strategy)
  end

  # Returns the assets bundler to use (webpack or rspack)
  #
  # Resolution order:
  # 1. CLI --bundler flag (via bundler_override)
  # 2. SHAKAPACKER_ASSETS_BUNDLER environment variable
  # 3. assets_bundler setting in config file
  # 4. bundler setting in config file (deprecated)
  # 5. Defaults to "webpack"
  #
  # @return [String] "webpack" or "rspack"
  def assets_bundler
    # CLI --bundler flag takes highest precedence
    return @bundler_override if @bundler_override

    # Show deprecation warning if using old 'bundler' key
    if data.has_key?(:bundler) && !data.has_key?(:assets_bundler)
      $stderr.puts "⚠️  DEPRECATION WARNING: The 'bundler' configuration option is deprecated. Please use 'assets_bundler' instead to avoid confusion with Ruby's Bundler gem manager."
    end
    ENV["SHAKAPACKER_ASSETS_BUNDLER"] || fetch(:assets_bundler) || fetch(:bundler) || "webpack"
  end

  # Deprecated alias for {#assets_bundler}
  #
  # @deprecated Use {#assets_bundler} instead
  # @return [String] the assets bundler
  # @see #assets_bundler
  def bundler
    assets_bundler
  end

  # Returns whether rspack is the configured bundler
  #
  # @return [Boolean] true if using rspack
  def rspack?
    assets_bundler == "rspack"
  end

  # Returns whether webpack is the configured bundler
  #
  # @return [Boolean] true if using webpack
  def webpack?
    assets_bundler == "webpack"
  end

  # Returns the precompile hook command to run after compilation
  #
  # The hook is a shell command that runs after successful compilation,
  # useful for post-processing tasks.
  #
  # @return [String, nil] the hook command or nil if not configured
  def precompile_hook
    hook = fetch(:precompile_hook)
    return nil if hook.nil? || (hook.is_a?(String) && hook.strip.empty?)

    unless hook.is_a?(String)
      raise "Shakapacker configuration error: precompile_hook must be a string, got #{hook.class}"
    end

    hook.strip
  end

  # Returns the JavaScript transpiler to use (babel, swc, or esbuild)
  #
  # Resolution order:
  # 1. javascript_transpiler setting in config file
  # 2. webpack_loader setting in config file (deprecated)
  # 3. Default based on bundler (swc for rspack, babel for webpack)
  #
  # Validates that the configured transpiler matches installed packages.
  #
  # @return [String] "babel", "swc", or "esbuild"
  def javascript_transpiler
    # Show deprecation warning if using old 'webpack_loader' key
    if data.has_key?(:webpack_loader) && !data.has_key?(:javascript_transpiler)
      $stderr.puts "⚠️  DEPRECATION WARNING: The 'webpack_loader' configuration option is deprecated. Please use 'javascript_transpiler' instead as it better reflects its purpose of configuring JavaScript transpilation regardless of the bundler used."
    end

    # Use explicit config if set, otherwise default based on bundler
    transpiler = fetch(:javascript_transpiler) || fetch(:webpack_loader) || default_javascript_transpiler

    # Validate transpiler configuration
    validate_transpiler_configuration(transpiler) unless self.class.installing

    transpiler
  end

  # Deprecated alias for {#javascript_transpiler}
  #
  # @deprecated Use {#javascript_transpiler} instead
  # @return [String] the JavaScript transpiler
  # @see #javascript_transpiler
  def webpack_loader
    javascript_transpiler
  end

  # Returns the CSS Modules export mode configuration
  #
  # Controls how CSS Module class names are exported in JavaScript:
  # - "named" (default): Use named exports with camelCase conversion (v9 behavior)
  # - "default": Use default export with both original and camelCase names (v8 behavior)
  #
  # @return [String] "named" or "default"
  # @raise [ArgumentError] if an invalid value is configured
  def css_modules_export_mode
    @css_modules_export_mode ||= begin
      mode = fetch(:css_modules_export_mode) || "named"

      # Validate the configuration value
      valid_modes = ["named", "default"]
      unless valid_modes.include?(mode)
        raise ArgumentError,
          "Invalid css_modules_export_mode: '#{mode}'. " \
          "Valid values are: #{valid_modes.map { |m| "'#{m}'" }.join(', ')}. " \
          "See https://github.com/shakacode/shakapacker/blob/main/docs/css-modules-export-mode.md"
      end

      mode
    end
  end

  # Returns the path to the bundler configuration directory
  #
  # This is where webpack.config.js or rspack.config.js should be located.
  # Defaults to config/webpack for webpack or config/rspack for rspack.
  #
  # @return [String] the relative path to the bundler config directory
  def assets_bundler_config_path
    custom_path = fetch(:assets_bundler_config_path)
    return custom_path if custom_path

    # Default paths based on bundler type
    rspack? ? "config/rspack" : "config/webpack"
  end

  # Returns the raw configuration data hash
  #
  # Returns the merged configuration from the shakapacker.yml file for the current environment.
  # The hash has symbolized keys loaded from the config file. Individual config values can be
  # accessed through specific accessor methods like {#source_path}, which apply defaults via {#fetch}.
  #
  # The returned hash is frozen to prevent accidental mutations. To access config values,
  # use the provided accessor methods instead of modifying this hash directly.
  #
  # @return [Hash<Symbol, Object>] the raw configuration data with symbolized keys (frozen)
  # @example
  #   config.data[:source_path]  #=> "app/javascript"
  #   config.data[:compile]      #=> true
  # @note The hash is frozen to prevent mutations. Use accessor methods for safe config access.
  # @api public
  def data
    @data ||= load.freeze
  end

  private

    def default_javascript_transpiler
      # RSpack has built-in SWC support, use it by default
      rspack? ? "swc" : "babel"
    end

    def validate_transpiler_configuration(transpiler)
      return unless ENV["NODE_ENV"] != "test" # Skip validation in test environment

      # Skip validation if transpiler is set to 'none' (custom webpack config)
      return if transpiler == "none"

      # Check if package.json exists
      package_json_path = root_path.join("package.json")
      return unless package_json_path.exist?

      begin
        package_json = JSON.parse(File.read(package_json_path))
        all_deps = (package_json["dependencies"] || {}).merge(package_json["devDependencies"] || {})

        # Check for transpiler mismatch
        has_babel = all_deps.keys.any? { |pkg| pkg.start_with?("@babel/", "babel-") }
        has_swc = all_deps.keys.any? { |pkg| pkg.include?("swc") }
        has_esbuild = all_deps.keys.any? { |pkg| pkg.include?("esbuild") }

        case transpiler
        when "babel"
          if !has_babel && has_swc
            warn_transpiler_mismatch("Babel", "SWC packages found but Babel is configured")
          end
        when "swc"
          if !has_swc && has_babel
            warn_transpiler_mismatch("SWC", "Babel packages found but SWC is configured")
          end
        when "esbuild"
          if !has_esbuild && (has_babel || has_swc)
            other = has_babel ? "Babel" : "SWC"
            warn_transpiler_mismatch("esbuild", "#{other} packages found but esbuild is configured")
          end
        end
      rescue JSON::ParserError
        # Ignore if package.json is malformed
      end
    end

    def warn_transpiler_mismatch(configured, message)
      $stderr.puts <<~WARNING
        ⚠️  Transpiler Configuration Mismatch Detected:
           #{message}
           Configured transpiler: #{configured}
        #{'   '}
           This might cause unexpected behavior or build failures.
        #{'   '}
           To fix this:
           1. Run 'rails shakapacker:migrate_to_swc' to migrate to SWC (recommended for 20x faster builds)
           2. Or install the correct packages for #{configured}
           3. Or update your shakapacker.yml to match your installed packages
      WARNING
    end

  public

  # Fetches a configuration value
  #
  # Looks up the value in the loaded configuration data, falling back to
  # the default configuration if not found.
  #
  # @param key [Symbol] the configuration key to fetch
  # @return [Object] the configuration value
  # @api private
  def fetch(key)
    data.fetch(key, defaults[key])
  end

  # Returns the asset host URL for serving assets
  #
  # Resolution order:
  # 1. SHAKAPACKER_ASSET_HOST environment variable
  # 2. asset_host setting in config file
  # 3. Rails ActionController::Base.helpers.compute_asset_host
  #
  # Used to serve assets from a CDN or different domain.
  #
  # @return [String, nil] the asset host URL or nil
  def asset_host
    ENV.fetch(
      "SHAKAPACKER_ASSET_HOST",
      fetch(:asset_host) || ActionController::Base.helpers.compute_asset_host
    )
  end

  # Returns whether subresource integrity (SRI) is enabled
  #
  # When true, generates integrity hashes for script and link tags to
  # protect against compromised CDNs or man-in-the-middle attacks.
  #
  # @return [Boolean] true if integrity checking is enabled
  def integrity
    fetch(:integrity)
  end

  # Returns whether HTTP/2 Early Hints are enabled
  #
  # When true, sends Early Hints headers to start loading assets before
  # the full response is ready.
  #
  # @return [Boolean] true if early hints are enabled
  def early_hints
    fetch(:early_hints)
  end

  private
    def validate_output_paths!
      # Skip validation if already validated to avoid redundant checks
      return if @validated_output_paths
      @validated_output_paths = true

      # Only validate when both paths are configured
      return unless fetch(:private_output_path) && fetch(:public_output_path)

      private_path_str, public_path_str = resolve_paths_for_comparison

      if private_path_str == public_path_str
        raise "Shakapacker configuration error: private_output_path and public_output_path must be different. " \
              "Both paths resolve to '#{private_path_str}'. " \
              "The private_output_path is for server-side bundles (e.g., SSR) that should not be served publicly."
      end
    end

    def resolve_paths_for_comparison
      private_full_path = root_path.join(fetch(:private_output_path))
      public_full_path = root_path.join(fetch(:public_root_path), fetch(:public_output_path))

      # Create directories if they don't exist (for testing)
      private_full_path.mkpath unless private_full_path.exist?
      public_full_path.mkpath unless public_full_path.exist?

      # Use realpath to resolve symbolic links and relative paths
      [private_full_path.realpath.to_s, public_full_path.realpath.to_s]
    rescue Errno::ENOENT
      # If paths don't exist yet, fall back to cleanpath for comparison
      [private_full_path.cleanpath.to_s, public_full_path.cleanpath.to_s]
    end

    def load
      config = begin
        YAML.load_file(config_path.to_s, aliases: true)
      rescue ArgumentError
        YAML.load_file(config_path.to_s)
      end

      # Try to find environment-specific configuration with fallback
      # Fallback order: requested env → production
      if config[env]
        env_config = config[env]
      elsif config["production"]
        log_fallback(env, "production")
        env_config = config["production"]
      else
        # No suitable configuration found - rely on bundled defaults
        log_fallback(env, "none (will use bundled defaults)")
        env_config = nil
      end

      symbolized_config = env_config&.deep_symbolize_keys || {}

      return symbolized_config
    rescue Errno::ENOENT => e
      if self.class.installing
        {}
      else
        raise "Shakapacker configuration file not found #{config_path}. " \
              "Please run rails shakapacker:install " \
              "Error: #{e.message}"
      end
    rescue Psych::SyntaxError => e
      raise "YAML syntax error occurred while parsing #{config_path}. " \
            "Please note that YAML must be consistently indented using spaces. Tabs are not allowed. " \
            "Error: #{e.message}"
    end

    def defaults
      @defaults ||= begin
        path = File.expand_path("../../install/config/shakapacker.yml", __FILE__)
        config = begin
          YAML.load_file(path, aliases: true)
        rescue ArgumentError
          YAML.load_file(path)
        end
        # Load defaults from bundled shakapacker.yml (always has all environments)
        # Note: This differs from load() which reads user's config and may be missing environments
        # Fallback to production ensures staging and other custom envs get production-like defaults
        HashWithIndifferentAccess.new(config[env] || config["production"])
      end
    end

    def relative_path(path)
      return ".#{path}" if path.start_with?("/")

      path
    end

    def log_fallback(requested_env, fallback_env)
      message = "Shakapacker environment '#{requested_env}' not found in #{config_path}, " \
                "falling back to '#{fallback_env}'"

      # Try to use the logger if available, otherwise fall back to stdout
      begin
        if Shakapacker.respond_to?(:logger) && Shakapacker.logger
          Shakapacker.logger.info(message)
        else
          puts message
        end
      rescue NameError, NoMethodError
        # If logger access fails (e.g., circular dependency in standalone runner context),
        # fall back to stdout so the message still gets displayed
        puts message
      end
    end
end
