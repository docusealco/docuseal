# frozen_string_literal: true

module Submissions
  class TimestampHandler
    HASH_ALGORITHM = 'SHA512'

    TimestampError = Class.new(StandardError)

    attr_reader :tsa_url

    def initialize(tsa_url:)
      @tsa_url = tsa_url
    end

    def finalize_objects(_signature_field, signature)
      signature.document.version = '2.0'

      signature[:Type] = :DocTimeStamp
      signature[:Filter] = :'Adobe.PPKLite'
      signature[:SubFilter] = :'ETSI.RFC3161'
    end

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

      response = conn.post(uri.path, build_payload(digest.digest),
                           'content-type' => 'application/timestamp-query')

      raise TimestampError if response.status != 200 || response.body.blank?

      OpenSSL::Timestamp::Response.new(response.body).token.to_der
    end

    def build_payload(digest)
      req = OpenSSL::Timestamp::Request.new
      req.algorithm = HASH_ALGORITHM
      req.message_imprint = digest

      req.to_der
    end
  end
end
