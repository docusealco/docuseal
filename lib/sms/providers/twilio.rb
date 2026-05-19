# frozen_string_literal: true

module Sms
  module Providers
    # Thin wrapper around the Twilio Messages API.
    #
    # Docs: https://www.twilio.com/docs/messaging/api/message-resource
    #
    # Request shape:
    #   POST https://api.twilio.com/2010-04-01/Accounts/<sid>/Messages.json
    #   Authorization: Basic base64(AccountSid:AuthToken)
    #   Content-Type: application/x-www-form-urlencoded  -- NOT JSON
    #   From=+15551234567&To=+15555550100&Body=...
    #
    # Response: 201 Created on success with JSON { sid, status, error_code,
    # error_message, ... }. Treat a 201 with a non-null error_code as failure.
    class Twilio
      ENDPOINT_HOST = 'api.twilio.com'
      TIMEOUT_SECONDS = 15

      def self.configured?(config)
        config['twilio_account_sid'].to_s.present? &&
          config['twilio_auth_token'].to_s.present? &&
          config['twilio_from'].to_s.present?
      end

      def initialize(config)
        @sid = config['twilio_account_sid'].to_s.strip
        @token = config['twilio_auth_token'].to_s.strip
        @from = format_e164(config['twilio_from'])
      end

      def deliver(to:, text:, webhook: nil)
        form = {
          'From' => @from,
          'To' => format_e164(to),
          'Body' => text.to_s
        }
        form['StatusCallback'] = webhook if webhook.present?

        response = http_post(form)
        parse_response!(response, form)
      end

      private

      def format_e164(raw)
        "+#{Sms.normalize_phone(raw)}"
      end

      def http_post(form)
        uri = URI("https://#{ENDPOINT_HOST}/2010-04-01/Accounts/#{@sid}/Messages.json")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = TIMEOUT_SECONDS
        http.open_timeout = TIMEOUT_SECONDS

        request = Net::HTTP::Post.new(uri.request_uri)
        request.basic_auth(@sid, @token)
        request['Accept'] = 'application/json'
        request.set_form_data(form)

        http.request(request)
      end

      def parse_response!(response, form)
        body = begin
          response.body.to_s.empty? ? {} : JSON.parse(response.body)
        rescue JSON::ParserError
          { 'raw' => response.body.to_s }
        end

        return body if response.is_a?(Net::HTTPSuccess) && body['error_code'].nil?

        code = body['code'] || body['error_code']
        message = body['message'] || body['error_message'] || body['raw'] || "HTTP #{response.code}"
        detail = code ? "#{code} #{message}" : message
        raise Sms::ProviderError,
              "Twilio rejected request (HTTP #{response.code}): #{detail}. " \
              "Request: From=#{form['From']} To=#{form['To']}."
      end
    end
  end
end
