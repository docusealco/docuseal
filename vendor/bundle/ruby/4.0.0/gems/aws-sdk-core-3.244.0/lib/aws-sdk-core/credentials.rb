# frozen_string_literal: true

module Aws
  class Credentials

    # @param [String] access_key_id
    # @param [String] secret_access_key
    # @param [String] session_token (nil)
    # @param [Hash] kwargs
    # @option kwargs [String] :credential_scope (nil)
    def initialize(access_key_id, secret_access_key, session_token = nil,
                   **kwargs)
      @access_key_id = access_key_id
      @secret_access_key = secret_access_key
      @session_token = session_token
      @account_id = kwargs[:account_id]
      @metrics = ['CREDENTIALS_CODE']
    end

    # @return [String]
    attr_reader :access_key_id

    # @return [String]
    attr_reader :secret_access_key

    # @return [String, nil]
    attr_reader :session_token

    # @return [String, nil]
    attr_reader :account_id

    # @api private
    # Returns the credentials source. Used for tracking credentials
    # related UserAgent metrics.
    attr_accessor :metrics

    # @return [Credentials]
    def credentials
      self
    end

    # @return [Boolean] Returns `true` if the access key id and secret
    #   access key are both set.
    def set?
      !access_key_id.nil? &&
        !access_key_id.empty? &&
        !secret_access_key.nil? &&
        !secret_access_key.empty?
    end

    # Removing the secret access key from the default inspect string.
    # @api private
    def inspect
      "#<#{self.class.name} access_key_id=#{access_key_id.inspect}>"
    end

  end
end
