# frozen_string_literal: true

module Submissions
  class TimestampHandler
    HASH_ALGORITHM = 'SHA256'

    TimestampError = Class.new(StandardError)

    attr_reader :tsa_url, :tsa_fallback_url

    def initialize(tsa_url:)
      @tsa_url, @tsa_fallback_url = tsa_url.split(',')
    end

    def finalize_objects(_signature_field, signature)
      signature.document.version = '2.0'

      signature[:Type] = :DocTimeStamp
      signature[:Filter] = :'Adobe.PPKLite'
      signature[:SubFilter] = :'ETSI.RFC3161'
    end

    # rubocop:disable Metrics
    def sign(io, byte_range)
      digest = OpenSSL::Digest.new(HASH_ALGORITHM)

      io.pos = byte_range[0]
      digest << io.read(byte_range[1])
      io.pos = byte_range[2]
      digest << io.read(byte_range[3])

      uri = Addressable::URI.parse(tsa_url)

      conn = Faraday.new(uri.origin) do |c|
        c.basic_auth(uri.user, uri.password) if uri.password.present?
      end

      response = conn.post(uri.request_uri, build_payload(digest.digest),
                           'content-type' => 'application/timestamp-query')

      if response.status != 200 || response.body.blank?
        raise TimestampError if tsa_fallback_url.blank?

        Rollbar.error('TimestampError: use fallback URL') if defined?(Rollbar)

        response = Faraday.post(tsa_fallback_url, build_payload(digest.digest),
                                'content-type' => 'application/timestamp-query')

        raise TimestampError if response.status != 200 || response.body.blank?
      end

      OpenSSL::Timestamp::Response.new(response.body).token.to_der
    rescue StandardError => e
      Rollbar.error(e) if defined?(Rollbar)
      Rails.logger.error(e)

      OpenSSL::ASN1::GeneralizedTime.new(Time.now.utc).to_der
    end
    # rubocop:enable Metrics

    def build_payload(digest)
      req = OpenSSL::Timestamp::Request.new
      req.algorithm = HASH_ALGORITHM
      req.message_imprint = digest

      req.to_der
    end
  end
end
