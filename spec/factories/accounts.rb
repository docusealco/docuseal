# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    name { Faker::Company.name }
    locale { 'en-US' }
    timezone { 'UTC' }

    trait :with_testing_account do
      after(:create) do |account|
        testing_account = account.dup.tap { |a| a.name = "Testing - #{account.name}" }
        testing_account.uuid = SecureRandom.uuid
        account.testing_accounts << testing_account
        account.save!
      end
    end
  end
end
