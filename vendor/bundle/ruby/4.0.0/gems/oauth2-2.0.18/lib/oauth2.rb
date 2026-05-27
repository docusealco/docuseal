# frozen_string_literal: true

# includes modules from stdlib
require "cgi"
require "time"

# third party gems
require "snaky_hash"
require "version_gem"

# includes gem files
require_relative "oauth2/version"
require_relative "oauth2/filtered_attributes"
require_relative "oauth2/error"
require_relative "oauth2/authenticator"
require_relative "oauth2/client"
require_relative "oauth2/strategy/base"
require_relative "oauth2/strategy/auth_code"
require_relative "oauth2/strategy/implicit"
require_relative "oauth2/strategy/password"
require_relative "oauth2/strategy/client_credentials"
require_relative "oauth2/strategy/assertion"
require_relative "oauth2/access_token"
require_relative "oauth2/response"

# The namespace of this library
#
# This module is the entry point and top-level namespace for the oauth2 gem.
# It exposes configuration, constants, and requires the primary public classes.
module OAuth2
  # When true, enables verbose HTTP logging via Faraday's logger middleware.
  # Controlled by the OAUTH_DEBUG environment variable. Any case-insensitive
  # value equal to "true" will enable debugging.
  #
  # @return [Boolean]
  OAUTH_DEBUG = ENV.fetch("OAUTH_DEBUG", "false").casecmp("true").zero?

  # Default configuration values for the oauth2 library.
  #
  # @example Toggle warnings
  #   OAuth2.configure do |config|
  #     config[:silence_extra_tokens_warning] = false
  #     config[:silence_no_tokens_warning] = false
  #   end
  #
  # @return [SnakyHash::SymbolKeyed] A mutable Hash-like config with symbol keys
  DEFAULT_CONFIG = SnakyHash::SymbolKeyed.new(
    silence_extra_tokens_warning: true,
    silence_no_tokens_warning: true,
  )

  # The current runtime configuration for the library.
  #
  # @return [SnakyHash::SymbolKeyed]
  @config = DEFAULT_CONFIG.dup

  class << self
    # Access the current configuration.
    #
    # Prefer using {OAuth2.configure} to mutate configuration.
    #
    # @return [SnakyHash::SymbolKeyed]
    attr_reader :config
  end

  # Configure global library behavior.
  #
  # Yields the mutable configuration object so callers can update settings.
  #
  # @yieldparam [SnakyHash::SymbolKeyed] config the configuration object
  # @return [void]
  def configure
    yield @config
  end
  module_function :configure
end

# Extend OAuth2::Version with VersionGem helpers to provide semantic version helpers.
OAuth2::Version.class_eval do
  extend VersionGem::Basic
end
