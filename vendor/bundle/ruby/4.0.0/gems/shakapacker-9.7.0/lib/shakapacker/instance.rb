require "pathname"

# Represents a single instance of Shakapacker configuration and state
#
# An instance encapsulates all the configuration, compilation, and manifest
# lookup functionality for a specific Rails application. Most applications
# will use the shared instance accessible via {Shakapacker.instance}, but
# multiple instances can be created for testing or advanced scenarios.
#
# @example Using the default instance
#   instance = Shakapacker::Instance.new
#   instance.config.source_path
#   instance.manifest.lookup("application.js")
#
# @example Creating an instance with custom paths
#   instance = Shakapacker::Instance.new(
#     root_path: "/path/to/app",
#     config_path: "/custom/config.yml"
#   )
class Shakapacker::Instance
  # The shared logger used by all Shakapacker instances
  # @return [ActiveSupport::TaggedLogging] the logger
  cattr_accessor(:logger) { ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(STDOUT)) }

  # The root path of the application
  # @return [Pathname] the application root path
  attr_reader :root_path

  # The path to the Shakapacker configuration file
  # @return [Pathname] the config file path
  attr_reader :config_path

  # Creates a new Shakapacker instance
  #
  # @param root_path [String, Pathname, nil] the application root path.
  #   Defaults to Rails.root if Rails is defined, otherwise uses current directory
  # @param config_path [String, Pathname, nil] the path to shakapacker.yml.
  #   Can also be set via SHAKAPACKER_CONFIG environment variable.
  #   Defaults to +config/shakapacker.yml+ within the root_path
  # @return [Shakapacker::Instance] the new instance
  def initialize(root_path: nil, config_path: nil)
    # Use Rails.root if Rails is defined and no root_path is provided
    @root_path = root_path || (defined?(Rails) && Rails&.root) || Pathname.new(Dir.pwd)

    # Use the determined root_path to construct the default config path
    default_config_path = @root_path.join("config/shakapacker.yml")

    @config_path = Pathname.new(ENV["SHAKAPACKER_CONFIG"] || config_path || default_config_path)
  end

  # Returns the current Rails environment as a StringInquirer
  #
  # This allows for convenient environment checking:
  #   env.development? # => true/false
  #   env.production?  # => true/false
  #
  # @return [ActiveSupport::StringInquirer] the environment
  def env
    @env ||= Shakapacker::Env.inquire self
  end

  # Returns the configuration object for this instance
  #
  # The configuration is loaded from the shakapacker.yml file and provides
  # access to all settings like source paths, output paths, and compilation options.
  #
  # @return [Shakapacker::Configuration] the configuration
  def config
    @config ||= Shakapacker::Configuration.new(
      root_path: root_path,
      config_path: config_path,
      env: env
    )
  end

  # Returns the compiler strategy for determining staleness
  #
  # The strategy (mtime or digest) determines how Shakapacker decides whether
  # assets need recompilation.
  #
  # @return [Shakapacker::CompilerStrategy] the compiler strategy
  # @api private
  def strategy
    @strategy ||= Shakapacker::CompilerStrategy.from_config
  end

  # Returns the compiler for this instance
  #
  # The compiler is responsible for executing webpack/rspack to compile assets.
  #
  # @return [Shakapacker::Compiler] the compiler
  def compiler
    @compiler ||= Shakapacker::Compiler.new self
  end

  # Returns the development server instance
  #
  # The dev server instance can query the status of the webpack-dev-server,
  # including whether it's running, its host/port, and configuration.
  #
  # @return [Shakapacker::DevServer] the dev server
  def dev_server
    @dev_server ||= Shakapacker::DevServer.new config
  end

  # Returns the manifest for looking up compiled assets
  #
  # The manifest reads the manifest.json file produced by webpack/rspack
  # and provides methods to look up the compiled paths for source files.
  #
  # @return [Shakapacker::Manifest] the manifest
  def manifest
    @manifest ||= Shakapacker::Manifest.new self
  end

  # Returns the commands instance for build operations
  #
  # The commands object provides methods for bootstrapping, cleaning,
  # clobbering, and compiling assets.
  #
  # @return [Shakapacker::Commands] the commands
  def commands
    @commands ||= Shakapacker::Commands.new self
  end

  # Returns whether CSS should be inlined by the dev server
  #
  # CSS inlining is enabled when:
  # - The dev server has inline_css enabled
  # - Hot Module Replacement (HMR) is enabled
  # - The dev server is currently running
  #
  # @return [Boolean] true if CSS should be inlined
  def inlining_css?
    dev_server.inline_css? && dev_server.hmr? && dev_server.running?
  end
end
