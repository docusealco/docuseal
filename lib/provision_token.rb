# frozen_string_literal: true

# Verifier for the HMAC-signed provisioning token minted by the parent EHR app.
#
# Token format: `body + "." + sig` where
#   body = Base64.urlsafe_encode64(payload_json, padding: false)  (compact JSON)
#   sig  = OpenSSL::HMAC.hexdigest("SHA256", secret, body)
#
# The shared secret lives in ENV["DOCUSEAL_PROVISION_SECRET"]. Fail closed on
# everything: a blank secret, a malformed/missing token, a signature mismatch,
# or an expired `exp` claim all return nil — never a half-trusted payload.
module ProvisionToken
  ENV_KEY = 'DOCUSEAL_PROVISION_SECRET'

  module_function

  def secret
    ENV[ENV_KEY].presence
  end

  # Returns the decoded payload Hash (string keys) when the token is valid and
  # unexpired, otherwise nil.
  def verify(token, secret: self.secret)
    return if secret.blank?
    return if token.blank?

    body, sig = token.split('.', 2)
    return if body.blank? || sig.blank?

    expected = OpenSSL::HMAC.hexdigest('SHA256', secret, body)
    return unless ActiveSupport::SecurityUtils.secure_compare(sig, expected)

    payload = JSON.parse(Base64.urlsafe_decode64(body))
    return unless payload.is_a?(Hash)

    exp = payload['exp']
    return unless exp.is_a?(Integer)
    return if exp <= Time.now.to_i

    payload
  rescue ArgumentError, JSON::ParserError
    # Base64.urlsafe_decode64 raises ArgumentError on malformed input;
    # JSON.parse raises JSON::ParserError. Both mean "not a valid token".
    nil
  end
end
