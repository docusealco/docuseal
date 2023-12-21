# frozen_string_literal: true

module Submitters
  module FormConfigs
    module_function

    def call(submitter)
      configs = submitter.submission.template.account.account_configs
                         .where(key: [AccountConfig::FORM_COMPLETED_BUTTON_KEY,
                                      AccountConfig::ALLOW_TYPED_SIGNATURE])

      completed_button = configs.find { |e| e.key == AccountConfig::FORM_COMPLETED_BUTTON_KEY }&.value || {}

      with_typed_signature = configs.find { |e| e.key == AccountConfig::ALLOW_TYPED_SIGNATURE }&.value != false

      { completed_button:, with_typed_signature: }
    end
  end
end
