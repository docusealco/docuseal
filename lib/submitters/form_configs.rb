# frozen_string_literal: true

module Submitters
  module FormConfigs
    DEFAULT_KEYS = [AccountConfig::FORM_COMPLETED_BUTTON_KEY,
                    AccountConfig::FORM_COMPLETED_MESSAGE_KEY,
                    AccountConfig::FORM_WITH_CONFETTI_KEY,
                    AccountConfig::ALLOW_TYPED_SIGNATURE].freeze

    module_function

    def call(submitter, keys = [])
      configs = submitter.submission.account.account_configs
                         .where(key: DEFAULT_KEYS + keys)

      completed_button = configs.find { |e| e.key == AccountConfig::FORM_COMPLETED_BUTTON_KEY }&.value || {}
      completed_message = configs.find { |e| e.key == AccountConfig::FORM_COMPLETED_MESSAGE_KEY }&.value || {}
      with_typed_signature = configs.find { |e| e.key == AccountConfig::ALLOW_TYPED_SIGNATURE }&.value != false
      with_confetti = configs.find { |e| e.key == AccountConfig::FORM_WITH_CONFETTI_KEY }&.value != false

      attrs = { completed_button:, with_typed_signature:, with_confetti:, completed_message: }

      keys.each do |key|
        attrs[key.to_sym] = configs.find { |e| e.key == key.to_s }&.value
      end

      attrs
    end
  end
end
