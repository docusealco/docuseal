# frozen_string_literal: true

module Aws
  module CredentialProvider

    # @return [Credentials]
    attr_reader :credentials

    # @return [Time]
    attr_reader :expiration

    # @api private
    # Returns UserAgent metrics for credentials.
    attr_accessor :metrics

    # @return [Boolean]
    def set?
      !!@credentials && @credentials.set?
    end

  end
end
