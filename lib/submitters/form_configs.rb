# frozen_string_literal: true

module Submitters
  module FormConfigs
    DEFAULT_KEYS = [AccountConfig::FORM_COMPLETED_BUTTON_KEY,
                    AccountConfig::FORM_COMPLETED_MESSAGE_KEY,
                    AccountConfig::FORM_WITH_CONFETTI_KEY,
                    AccountConfig::FORM_PREFILL_SIGNATURE_KEY,
                    AccountConfig::WITH_SIGNATURE_ID,
                    AccountConfig::ALLOW_TYPED_SIGNATURE].freeze

    module_function

    def call(submitter, keys = [])
      configs = submitter.submission.account.account_configs.where(key: DEFAULT_KEYS + keys)

      completed_button = find_safe_value(configs, AccountConfig::FORM_COMPLETED_BUTTON_KEY) || {}
      completed_message = find_safe_value(configs, AccountConfig::FORM_COMPLETED_MESSAGE_KEY) || {}
      with_typed_signature = find_safe_value(configs, AccountConfig::ALLOW_TYPED_SIGNATURE) != false
      with_confetti = find_safe_value(configs, AccountConfig::FORM_WITH_CONFETTI_KEY) != false
      prefill_signature = find_safe_value(configs, AccountConfig::FORM_PREFILL_SIGNATURE_KEY) != false
      with_signature_id = find_safe_value(configs, AccountConfig::WITH_SIGNATURE_ID) == true

      attrs = { completed_button:,
                with_typed_signature:,
                with_confetti:,
                completed_message:,
                prefill_signature:,
                with_signature_id: }

      keys.each do |key|
        attrs[key.to_sym] = configs.find { |e| e.key == key.to_s }&.value
      end

      attrs
    end

    def find_safe_value(configs, key)
      configs.find { |e| e.key == key }&.value
    end
  end
end
