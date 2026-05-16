# frozen_string_literal: true

module Sms
  class Error < StandardError; end
  class NotConfiguredError < Error; end
  class ProviderError < Error; end
  class InvalidNumberError < Error; end

  SUPPORTED_PROVIDERS = %w[bulkvs].freeze

  module_function

  # Returns the SMS configuration hash for an account, with the same keys the
  # form posts: { provider, enabled, basic_auth_token, from_number,
  # delivery_webhook_url }. Returns nil if no record exists.
  def configuration_for(account)
    return nil if account.nil?

    record = EncryptedConfig.find_by(account_id: account.id, key: EncryptedConfig::SMS_CONFIGS_KEY)
    record&.value
  end

  def enabled_for?(account)
    config = configuration_for(account)
    config.is_a?(Hash) &&
      config['enabled'] &&
      SUPPORTED_PROVIDERS.include?(config['provider'].to_s) &&
      config['basic_auth_token'].to_s.present? &&
      config['from_number'].to_s.present?
  end

  # Send an SMS via the account's configured provider.
  #
  # account: a WaboSign Account record
  # to:      the recipient phone number (E.164 string, leading + tolerated)
  # text:    the message body (already variable-substituted)
  # webhook: optional override of the per-message delivery_status_webhook_url
  #
  # Returns the provider's parsed JSON response on success. Raises
  # NotConfiguredError or ProviderError on failure.
  def send_message(account:, to:, text:, webhook: nil)
    config = configuration_for(account)
    raise NotConfiguredError, 'SMS provider is not configured' unless enabled_for?(account)

    provider = config['provider'].to_s
    case provider
    when 'bulkvs'
      Sms::Providers::Bulkvs.new(config).deliver(to: to, text: text, webhook: webhook)
    else
      raise NotConfiguredError, "Unsupported SMS provider: #{provider.inspect}"
    end
  end

  # Normalize a phone number to E.164 (digits-only, no '+'). BulkVS expects
  # eleven-digit US numbers like 15551234567; international numbers are passed
  # through as-is once stripped of formatting characters.
  def normalize_phone(raw)
    digits = raw.to_s.gsub(/[^\d]/, '')
    raise InvalidNumberError, "Invalid phone number: #{raw.inspect}" if digits.length < 8

    digits
  end
end
