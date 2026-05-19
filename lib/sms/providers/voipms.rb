# frozen_string_literal: true

module Sms
  module Providers
    # Thin wrapper around the VoIP.ms REST/JSON API sendSMS method.
    #
    # Docs: https://voip.ms/m/apidocs.php
    # SMS wiki: https://wiki.voip.ms/article/SMS-MMS
    #
    # Request shape:
    #   GET https://voip.ms/api/v1/rest.php
    #     ?api_username=...&api_password=...&method=sendSMS&did=...&dst=...&message=...
    #
    # Response: ALWAYS HTTP 200. Success body { "status": "success", "sms": <id> }.
    # Failure body { "status": "<error_code>" } where error codes include
    # invalid_credentials, invalid_did, invalid_dst, missing_message,
    # sms_toolong, limit_reached, ip_not_authorized. Must inspect the `status`
    # field — HTTP code alone is meaningless.
    class Voipms
      ENDPOINT = 'https://voip.ms/api/v1/rest.php'
      TIMEOUT_SECONDS = 15
      MAX_SMS_LENGTH = 160

      def self.configured?(config)
        config['voipms_api_username'].to_s.present? &&
          config['voipms_api_password'].to_s.present? &&
          config['voipms_did'].to_s.present?
      end

      def initialize(config)
        @username = config['voipms_api_username'].to_s.strip
        @password = config['voipms_api_password'].to_s.strip
        @did = Sms.normalize_phone(config['voipms_did'])
      end

      def deliver(to:, text:, webhook: nil) # rubocop:disable Lint/UnusedMethodArgument
        message = text.to_s
        if message.bytesize > MAX_SMS_LENGTH
          raise Sms::ProviderError,
                "VoIP.ms rejects messages longer than #{MAX_SMS_LENGTH} bytes; got #{message.bytesize}."
        end

        params = {
          'api_username' => @username,
          'api_password' => @password,
          'method' => 'sendSMS',
          'did' => @did,
          'dst' => Sms.normalize_phone(to),
          'message' => message
        }

        response = http_get(params)
        parse_response!(response)
      end

      private

      def http_get(params)
        uri = URI(ENDPOINT)
        uri.query = URI.encode_www_form(params)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = TIMEOUT_SECONDS
        http.open_timeout = TIMEOUT_SECONDS

        request = Net::HTTP::Get.new(uri.request_uri)
        request['Accept'] = 'application/json'

        http.request(request)
      end

      def parse_response!(response)
        body = begin
          response.body.to_s.empty? ? {} : JSON.parse(response.body)
        rescue JSON::ParserError
          { 'raw' => response.body.to_s }
        end

        status = body['status'].to_s
        return body if response.is_a?(Net::HTTPSuccess) && status == 'success'

        detail = status.presence || body['raw'].presence || "HTTP #{response.code}"
        raise Sms::ProviderError, "VoIP.ms rejected request: #{detail}."
      end
    end
  end
end
