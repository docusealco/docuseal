# frozen_string_literal: true

module Sms
  module Providers
    # Thin wrapper around the SignalWire Compatibility API Messages endpoint.
    # Twilio-shaped on the wire (same Basic Auth, same form-encoded body, same
    # 201-with-error_code JSON), with two differences from Twilio:
    #   - path is /api/laml/2010-04-01/Accounts/<id>/Messages (no .json suffix)
    #   - host comes from a per-account "Space URL" (e.g. acme.signalwire.com)
    #
    # Docs: https://signalwire.com/docs/compatibility-api/rest/messages/create-message
    class Signalwire
      TIMEOUT_SECONDS = 15

      def self.configured?(config)
        config['signalwire_space_url'].to_s.present? &&
          config['signalwire_project_id'].to_s.present? &&
          config['signalwire_api_token'].to_s.present? &&
          config['signalwire_from'].to_s.present?
      end

      def initialize(config)
        @host = normalize_space_url(config['signalwire_space_url'])
        @project_id = config['signalwire_project_id'].to_s.strip
        @token = config['signalwire_api_token'].to_s.strip
        @from = format_e164(config['signalwire_from'])
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

      def normalize_space_url(raw)
        raw.to_s.strip.sub(%r{\Ahttps?://}, '').delete_suffix('/')
      end

      def format_e164(raw)
        "+#{Sms.normalize_phone(raw)}"
      end

      def http_post(form)
        uri = URI("https://#{@host}/api/laml/2010-04-01/Accounts/#{@project_id}/Messages")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = TIMEOUT_SECONDS
        http.open_timeout = TIMEOUT_SECONDS

        request = Net::HTTP::Post.new(uri.request_uri)
        request.basic_auth(@project_id, @token)
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
              "SignalWire rejected request (HTTP #{response.code}): #{detail}. " \
              "Request: From=#{form['From']} To=#{form['To']}."
      end
    end
  end
end
