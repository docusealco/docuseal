# frozen_string_literal: true

module WebhookUrls
  module Signatures
    SECRET_PREFIX = 'whsec_'
    SECRET_BYTES = 24
    TOLERANCE = 5 * 60

    InvalidSignatureError = Class.new(StandardError)
    TimestampError = Class.new(StandardError)

    module_function

    def generate_secret
      SECRET_PREFIX + Base64.strict_encode64(SecureRandom.bytes(SECRET_BYTES))
    end

    def sign(secret, body:, timestamp: Time.current.to_i)
      "#{timestamp}.#{OpenSSL::HMAC.hexdigest('sha256', secret, "#{timestamp}.#{body}")}"
    end

    def verify(secret, body:, header:, tolerance: TOLERANCE)
      ts, sig = header.to_s.split('.', 2)
      ts = Integer(ts, exception: false)

      raise InvalidSignatureError unless ts && sig

      now = Time.current.to_i

      raise TimestampError, 'Too old' if ts < now - tolerance
      raise TimestampError, 'In future' if ts > now + tolerance

      expected = OpenSSL::HMAC.hexdigest('sha256', secret, "#{ts}.#{body}")

      raise InvalidSignatureError unless ActiveSupport::SecurityUtils.secure_compare(expected, sig)

      true
    end
  end
end
