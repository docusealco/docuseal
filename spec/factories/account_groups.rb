# frozen_string_literal: true

FactoryBot.define do
  factory :account_group do
    external_account_group_id { Faker::Number.unique.number(digits: 8) }
    name { Faker::Company.name }
  end
end
