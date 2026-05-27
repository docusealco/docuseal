# frozen_string_literal: true

# JSON Web Token implementation
#
# Should be up to date with the latest spec:
# https://tools.ietf.org/html/rfc7519
module JWT
  # Returns the gem version of the JWT library.
  #
  # @return [Gem::Version] the gem version.
  def self.gem_version
    Gem::Version.new(VERSION::STRING)
  end

  # Version constants
  module VERSION
    MAJOR = 3
    MINOR = 1
    TINY  = 2
    PRE   = nil

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join('.')
  end

  # Checks if the OpenSSL version is 3 or greater.
  #
  # @return [Boolean] true if OpenSSL version is 3 or greater, false otherwise.
  # @api private
  def self.openssl_3?
    return false if OpenSSL::OPENSSL_VERSION.include?('LibreSSL')

    true if 3 * 0x10000000 <= OpenSSL::OPENSSL_VERSION_NUMBER
  end

  # Checks if there is an OpenSSL 3 HMAC empty key regression.
  #
  # @return [Boolean] true if there is an OpenSSL 3 HMAC empty key regression, false otherwise.
  # @api private
  def self.openssl_3_hmac_empty_key_regression?
    openssl_3? && openssl_version <= ::Gem::Version.new('3.0.0')
  end

  # Returns the OpenSSL version.
  #
  # @return [Gem::Version] the OpenSSL version.
  # @api private
  def self.openssl_version
    @openssl_version ||= ::Gem::Version.new(OpenSSL::VERSION)
  end
end
