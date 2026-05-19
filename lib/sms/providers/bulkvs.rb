# frozen_string_literal: true

module Sms
  module Providers
    # Thin wrapper around the BulkVS messageSend API.
    #
    # Docs: https://portal.bulkvs.com/api/v1.0/documentation
    #
    # Request shape:
    #   POST /api/v1.0/messageSend
    #   Authorization: Basic <pre-encoded token from the BulkVS portal>
    #   Content-Type: application/json
    #   { "From": "<e164>", "To": ["<e164>", ...], "Message": "<text>",
    #     "delivery_status_webhook_url": "<optional>" }
    #
    # Response shape (success): JSON with at least { "Status": "...", ... }
    # Response shape (error):   non-2xx + JSON body with error details
    class Bulkvs
      ENDPOINT = 'https://portal.bulkvs.com/api/v1.0/messageSend'
      TIMEOUT_SECONDS = 15

      def self.configured?(config)
        config['basic_auth_token'].to_s.present? && config['from_number'].to_s.present?
      end

      def initialize(config)
        @token = config['basic_auth_token'].to_s.strip
        @from = Sms.normalize_phone(config['from_number'])
        @config_webhook = config['delivery_webhook_url'].to_s.strip
      end

      def deliver(to:, text:, webhook: nil)
        body = {
          'From' => @from,
          'To' => Array(to).map { |n| Sms.normalize_phone(n) },
          'Message' => text.to_s
        }
        effective_webhook = webhook.presence || @config_webhook.presence
        body['delivery_status_webhook_url'] = effective_webhook if effective_webhook

        response = http_post(body)
        parse_response!(response, body)
      end

      private

      def http_post(body)
        uri = URI(ENDPOINT)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = TIMEOUT_SECONDS
        http.open_timeout = TIMEOUT_SECONDS

        request = Net::HTTP::Post.new(uri.request_uri)
        request['Authorization'] = "Basic #{@token}"
        request['Content-Type'] = 'application/json'
        request['Accept'] = 'application/json'
        request.body = JSON.generate(body)

        http.request(request)
      end

      def parse_response!(response, request_body)
        body = begin
          response.body.to_s.empty? ? {} : JSON.parse(response.body)
        rescue JSON::ParserError
          { 'raw' => response.body.to_s }
        end

        return body if response.is_a?(Net::HTTPSuccess)

        message = body['Description'] || body['Status'] || body['error'] ||
                  body['raw'] || "HTTP #{response.code}"
        raise Sms::ProviderError,
              "BulkVS rejected request (HTTP #{response.code}): #{message}. " \
              "Request body: #{JSON.generate(request_body.except('Message'))}."
      end
    end
  end
end
