# Development server status and configuration
#
# Provides methods to query the status and configuration of the webpack-dev-server
# or rspack-dev-server. This includes checking if the server is running, accessing
# its host/port, and querying features like HMR (Hot Module Replacement).
#
# The dev server runs during development to provide live reloading and hot module
# replacement. In production, the dev server is not used.
#
# @example Checking dev server status
#   dev_server = Shakapacker.dev_server
#   dev_server.running?
#   #=> true
#   dev_server.host_with_port
#   #=> "localhost:3035"
#   dev_server.hmr?
#   #=> true
#
# @see Shakapacker::DevServerRunner
class Shakapacker::DevServer
  # Default environment variable prefix for dev server settings
  DEFAULT_ENV_PREFIX = "SHAKAPACKER_DEV_SERVER".freeze

  # Configure dev server connection timeout (in seconds), default: 0.1
  # @example
  #   Shakapacker::DevServer.connect_timeout = 1
  # @return [Float] the connection timeout in seconds
  cattr_accessor(:connect_timeout) { 0.1 }

  # The Shakapacker configuration
  # @return [Shakapacker::Configuration] the configuration
  attr_reader :config

  # Creates a new dev server instance
  #
  # @param config [Shakapacker::Configuration] the Shakapacker configuration
  # @return [Shakapacker::DevServer] the new dev server instance
  def initialize(config)
    @config = config
  end

  # Returns whether the dev server is currently running
  #
  # Checks by attempting to open a TCP connection to the configured host and port.
  # Returns false if the connection fails or if dev server is not configured.
  #
  # @return [Boolean] true if the dev server is running
  def running?
    if config.dev_server.present?
      Socket.tcp(host, port, connect_timeout: connect_timeout).close
      true
    else
      false
    end
  rescue
    false
  end

  # Returns the dev server host
  #
  # Can be overridden via SHAKAPACKER_DEV_SERVER_HOST environment variable.
  #
  # @return [String] the host (e.g., "localhost", "0.0.0.0")
  def host
    fetch(:host)
  end

  # Returns the dev server port
  #
  # Can be overridden via SHAKAPACKER_DEV_SERVER_PORT environment variable.
  #
  # @return [Integer] the port number (typically 3035)
  def port
    fetch(:port)
  end

  # Returns the server type (http or https)
  #
  # Can be overridden via SHAKAPACKER_DEV_SERVER_SERVER environment variable.
  # Validates that the value is "http" or "https", falling back to "http" if invalid.
  #
  # @return [String] "http" or "https"
  def server
    server_value = fetch(:server)
    server_type = server_value.is_a?(Hash) ? server_value[:type] : server_value

    return server_type if ["http", "https"].include?(server_type)

    return "http" if server_type.nil?

    puts <<~MSG
    WARNING:
    `server: #{server_type}` is not a valid configuration in Shakapacker.
    Falling back to default `server: http`.
    MSG

    "http"
  rescue KeyError
    "http"
  end

  # Returns the protocol for the dev server
  #
  # This is an alias that returns "https" if server is "https", otherwise "http".
  #
  # @return [String] "http" or "https"
  def protocol
    return "https" if server == "https"

    "http"
  end

  # Returns the host and port as a single string
  #
  # @return [String] the host:port combination (e.g., "localhost:3035")
  # @example
  #   dev_server.host_with_port
  #   #=> "localhost:3035"
  def host_with_port
    "#{host}:#{port}"
  end

  # Returns whether pretty output is enabled
  #
  # When true, the dev server produces prettier, more readable output.
  # Can be overridden via SHAKAPACKER_DEV_SERVER_PRETTY environment variable.
  #
  # @return [Boolean] true if pretty output is enabled
  def pretty?
    fetch(:pretty)
  end

  # Returns whether Hot Module Replacement (HMR) is enabled
  #
  # When true, the dev server updates modules in the browser without a full
  # page reload, preserving application state.
  # Can be overridden via SHAKAPACKER_DEV_SERVER_HMR environment variable.
  #
  # @return [Boolean] true if HMR is enabled
  def hmr?
    fetch(:hmr)
  end

  # Returns whether CSS inlining is enabled
  #
  # When true, CSS is injected inline via JavaScript instead of being loaded
  # as separate stylesheet files. This enables HMR for CSS.
  # Can be overridden via SHAKAPACKER_DEV_SERVER_INLINE_CSS environment variable.
  #
  # @return [Boolean] true if CSS should be inlined
  def inline_css?
    case fetch(:inline_css)
    when false, "false"
      false
    else
      true
    end
  end

  # Returns the environment variable prefix for dev server settings
  #
  # Environment variables for dev server settings use this prefix (default: "SHAKAPACKER_DEV_SERVER").
  # For example, SHAKAPACKER_DEV_SERVER_PORT sets the port.
  #
  # @return [String] the env var prefix (typically "SHAKAPACKER_DEV_SERVER")
  def env_prefix
    config.dev_server.fetch(:env_prefix, DEFAULT_ENV_PREFIX)
  end

  private
    def fetch(key)
      return nil unless config.dev_server.present?

      ENV["#{env_prefix}_#{key.upcase}"] || config.dev_server.fetch(key, defaults[key])
    rescue
      nil
    end

    def defaults
      config.send(:defaults)[:dev_server] || {}
    end
end
