# frozen_string_literal: true

module Aws
  module TokenProvider

    # @return [Token]
    attr_reader :token

    # @api private
    # Returns UserAgent metrics for tokens.
    attr_accessor :metrics

    # @return [Boolean]
    def set?
      !!token && token.set?
    end

  end
end
