# frozen_string_literal: true

module AccountConfigs
  module_function

  def find_or_initialize_for_key(account, key)
    account.account_configs.find_by(key:) ||
      account.account_configs.new(key:, value: AccountConfig::DEFAULT_VALUES[key])
  end
end
