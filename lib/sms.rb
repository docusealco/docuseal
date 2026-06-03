# frozen_string_literal: true

module Sms
  class Error < StandardError; end
  class NotConfiguredError < Error; end
  class ProviderError < Error; end
  class InvalidNumberError < Error; end

  SUPPORTED_PROVIDERS = %w[bulkvs twilio voipms signalwire].freeze

  module_function

  # Returns the SMS configuration hash for an account. Keys vary by provider —
  # see the per-provider class for which keys it consumes. Returns nil if no
  # record exists.
  def configuration_for(account)
    return nil if account.nil?

    record = EncryptedConfig.find_by(account_id: account.id, key: EncryptedConfig::SMS_CONFIGS_KEY)
    record&.value
  end

  def enabled?(account)
    config = configuration_for(account)
    config.is_a?(Hash) && !!config['enabled']
  end

  def enabled_for?(account)
    config = configuration_for(account)
    return false unless config.is_a?(Hash)
    return false unless config['enabled']

    klass = provider_class(config['provider'].to_s)
    klass ? klass.configured?(config) : false
  end

  # Send an SMS via the account's configured provider.
  #
  # account: a WaboSign Account record
  # to:      the recipient phone number (E.164, leading + tolerated; the
  #          provider class decides whether to keep or strip the +)
  # text:    the message body (already variable-substituted)
  # webhook: optional override of the per-message delivery callback URL
  #
  # Returns the provider's parsed response on success. Raises
  # NotConfiguredError or ProviderError on failure.
  def send_message(account:, to:, text:, webhook: nil)
    raise NotConfiguredError, 'SMS provider is not configured' unless enabled_for?(account)

    config = configuration_for(account)
    klass = provider_class(config['provider'].to_s)
    raise NotConfiguredError, "Unsupported SMS provider: #{config['provider'].inspect}" unless klass

    klass.new(config).deliver(to: to, text: text, webhook: webhook)
  end

  # Normalize a phone number to digits-only. Each provider class is responsible
  # for prepending '+' if its wire format requires E.164 with leading plus
  # (Twilio, SignalWire); BulkVS and VoIP.ms take digits-only.
  def normalize_phone(raw)
    digits = raw.to_s.gsub(/[^\d]/, '')
    raise InvalidNumberError, "Invalid phone number: #{raw.inspect}" if digits.length < 8

    digits
  end

  def provider_class(name)
    case name
    when 'bulkvs'     then Sms::Providers::Bulkvs
    when 'twilio'     then Sms::Providers::Twilio
    when 'voipms'     then Sms::Providers::Voipms
    when 'signalwire' then Sms::Providers::Signalwire
    end
  end
end
