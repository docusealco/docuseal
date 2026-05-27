require "active_support/core_ext/module/attribute_accessors"
require "active_support/core_ext/string/inquiry"
require "active_support/logger"
require "active_support/tagged_logging"

# = Shakapacker
#
# Shakapacker is a Ruby gem that integrates webpack and rspack with Rails applications,
# providing a modern asset pipeline for JavaScript, CSS, and other web assets.
#
# The main Shakapacker module provides singleton-style access to configuration,
# compilation, and asset manifest functionality. Most methods delegate to a shared
# {Shakapacker::Instance} object.
#
# == Basic Usage
#
#   # Access configuration
#   Shakapacker.config.source_path
#   #=> Pathname("/path/to/app/packs")
#
#   # Check if dev server is running
#   Shakapacker.dev_server.running?
#   #=> true
#
#   # Look up compiled assets
#   Shakapacker.manifest.lookup("application.js")
#   #=> "/packs/application-abc123.js"
#
#   # Compile assets
#   Shakapacker.compile
#
# == Configuration
#
# Configuration is loaded from +config/shakapacker.yml+ and can be accessed via
# {Shakapacker.config}. The configuration determines the source paths, output paths,
# compilation settings, and dev server options.
#
# @see Shakapacker::Configuration
# @see Shakapacker::Instance
module Shakapacker
  extend self

  # Default environment when RAILS_ENV is not set
  DEFAULT_ENV = "development".freeze
  # Environments that use "development" for NODE_ENV
  # All other environments (production, staging, etc.) use "production" for webpack optimizations
  # Note: Both development and test RAILS_ENV use NODE_ENV=development because
  # webpack/rspack only recognize "development" and "production" values for NODE_ENV.
  # Using "test" causes DefinePlugin conflicts with optimization.nodeEnv.
  DEV_ENVS = %w[development test].freeze

  # Sets the shared Shakapacker instance
  #
  # This is primarily used for testing or advanced customization scenarios.
  # In most applications, the default instance is sufficient.
  #
  # @param instance [Shakapacker::Instance] the instance to use
  # @return [Shakapacker::Instance] the instance that was set
  # @api public
  def instance=(instance)
    @instance = instance
  end

  # Returns the shared Shakapacker instance
  #
  # This instance is used by all module-level delegate methods. It provides
  # access to configuration, compilation, manifest lookup, and more.
  #
  # @return [Shakapacker::Instance] the shared instance
  # @api public
  def instance
    @instance ||= Shakapacker::Instance.new
  end

  # Temporarily overrides NODE_ENV for the duration of the block
  #
  # This is useful when you need to perform operations with a specific NODE_ENV
  # value without permanently changing the environment.
  #
  # @param env [String] the NODE_ENV value to use temporarily
  # @yield the block to execute with the temporary NODE_ENV
  # @return [Object] the return value of the block
  # @example
  #   Shakapacker.with_node_env("production") do
  #     # This code runs with NODE_ENV=production
  #     Shakapacker.compile
  #   end
  # @api public
  def with_node_env(env)
    original = ENV["NODE_ENV"]
    ENV["NODE_ENV"] = env
    yield
  ensure
    ENV["NODE_ENV"] = original
  end

  # Sets NODE_ENV based on RAILS_ENV if not already set
  #
  # Environment mapping:
  # - +development+ and +test+ environments use "development" for NODE_ENV
  # - All other environments (+production+, +staging+, etc.) use "production" for webpack optimizations
  #
  # Note: We always use "development" (not "test") for test environments because
  # webpack/rspack only recognize "development" and "production" as valid NODE_ENV values.
  # Using "test" causes DefinePlugin conflicts with optimization.nodeEnv.
  #
  # This method is typically called automatically during Rails initialization.
  #
  # @return [String] the NODE_ENV value that was set
  # @api private
  def ensure_node_env!
    ENV["NODE_ENV"] ||= DEV_ENVS.include?(ENV["RAILS_ENV"]) ? "development" : "production"
  end

  # Temporarily redirects Shakapacker logging to STDOUT
  #
  # This is useful for debugging or when you want to see compilation output
  # in the console instead of the Rails log.
  #
  # @yield the block to execute with STDOUT logging
  # @return [Object] the return value of the block
  # @example
  #   Shakapacker.ensure_log_goes_to_stdout do
  #     Shakapacker.compile
  #   end
  # @api public
  def ensure_log_goes_to_stdout
    old_logger = Shakapacker.logger
    Shakapacker.logger = Logger.new(STDOUT)
    yield
  ensure
    Shakapacker.logger = old_logger
  end

  # @!method logger
  #   Returns the logger instance used by Shakapacker
  #   @return [Logger] the logger instance
  #   @see Shakapacker::Instance#logger
  # @!method logger=(logger)
  #   Sets the logger instance used by Shakapacker
  #   @param logger [Logger] the logger to use
  #   @return [Logger] the logger that was set
  #   @see Shakapacker::Instance#logger=
  # @!method env
  #   Returns the current Rails environment as an ActiveSupport::StringInquirer
  #   @return [ActiveSupport::StringInquirer] the environment
  #   @see Shakapacker::Instance#env
  # @!method inlining_css?
  #   Returns whether CSS inlining is enabled
  #   @return [Boolean] true if CSS should be inlined
  #   @see Shakapacker::Instance#inlining_css?
  delegate :logger, :logger=, :env, :inlining_css?, to: :instance

  # @!method config
  #   Returns the Shakapacker configuration object
  #   @return [Shakapacker::Configuration] the configuration
  #   @see Shakapacker::Instance#config
  # @!method compiler
  #   Returns the compiler instance for compiling assets
  #   @return [Shakapacker::Compiler] the compiler
  #   @see Shakapacker::Instance#compiler
  # @!method manifest
  #   Returns the manifest instance for looking up compiled assets
  #   @return [Shakapacker::Manifest] the manifest
  #   @see Shakapacker::Instance#manifest
  # @!method commands
  #   Returns the commands instance for build operations
  #   @return [Shakapacker::Commands] the commands object
  #   @see Shakapacker::Instance#commands
  # @!method dev_server
  #   Returns the dev server instance for querying server status
  #   @return [Shakapacker::DevServer] the dev server
  #   @see Shakapacker::Instance#dev_server
  delegate :config, :compiler, :manifest, :commands, :dev_server, to: :instance

  # @!method bootstrap
  #   Creates the default configuration files and directory structure
  #   @return [void]
  #   @see Shakapacker::Commands#bootstrap
  # @!method clean(count = nil, age = nil)
  #   Removes old compiled packs, keeping the most recent versions
  #   @param count [Integer, nil] number of versions to keep per entry
  #   @param age [Integer, nil] maximum age in seconds for packs to keep
  #   @return [void]
  #   @see Shakapacker::Commands#clean
  # @!method clobber
  #   Removes all compiled packs
  #   @return [void]
  #   @see Shakapacker::Commands#clobber
  # @!method compile
  #   Compiles all webpack/rspack packs
  #   @return [Boolean] true if compilation succeeded
  #   @see Shakapacker::Commands#compile
  delegate :bootstrap, :clean, :clobber, :compile, to: :commands
end

require_relative "shakapacker/instance"
require_relative "shakapacker/env"
require_relative "shakapacker/configuration"
require_relative "shakapacker/manifest"
require_relative "shakapacker/compiler"
require_relative "shakapacker/commands"
require_relative "shakapacker/dev_server"
require_relative "shakapacker/doctor"
require_relative "shakapacker/deprecation_helper"

require_relative "shakapacker/railtie" if defined?(Rails)
