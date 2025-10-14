# frozen_string_literal: true

FactoryBot.define do
  factory :account_linked_account do
    association :account
    association :linked_account, factory: :account
    account_type { 'testing' }
  end
end
