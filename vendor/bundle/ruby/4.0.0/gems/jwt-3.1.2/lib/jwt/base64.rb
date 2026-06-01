# frozen_string_literal: true

require 'base64'

module JWT
  # Base64 encoding and decoding
  # @api private
  class Base64
    class << self
      # Encode a string with URL-safe Base64 complying with RFC 4648 (not padded).
      # @api private
      def url_encode(str)
        ::Base64.urlsafe_encode64(str, padding: false)
      end

      # Decode a string with URL-safe Base64 complying with RFC 4648.
      # @api private
      def url_decode(str)
        ::Base64.urlsafe_decode64(str)
      rescue ArgumentError => e
        raise unless e.message == 'invalid base64'

        raise Base64DecodeError, 'Invalid base64 encoding'
      end
    end
  end
end
