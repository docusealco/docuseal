# frozen_string_literal: true

module AccountConfigs
  REMINDER_DURATIONS = {
    'one_hour' => '1 hour',
    'two_hours' => '2 hours',
    'four_hours' => '4 hours',
    'eight_hours' => '8 hours',
    'twelve_hours' => '12 hours',
    'twenty_four_hours' => '24 hours',
    'two_days' => '2 days',
    'four_days' => '4 days',
    'eight_days' => '8 days',
    'fifteen_days' => '15 days'
  }.freeze

  module_function

  def find_or_initialize_for_key(account, key)
    find_for_account(account, key) ||
      account.account_configs.new(key:, value: AccountConfig::DEFAULT_VALUES[key])
  end

  def find_for_account(account, key)
    configs = account.account_configs.find_by(key:)

    configs ||= Account.order(:id).first.account_configs.find_by(key:) unless Docuseal.multitenant?

    configs
  end
end
