# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    name { Faker::Company.name }
    locale { 'en-US' }
    timezone { 'UTC' }

    transient do
      teams_count { 2 }
    end

    trait :with_testing_account do
      after(:create) do |account|
        testing_account = account.dup.tap { |a| a.name = "Testing - #{account.name}" }
        testing_account.uuid = SecureRandom.uuid
        account.testing_accounts << testing_account
        account.save!
      end
    end

    trait :with_teams do
      after(:create) do |account, evaluator|
        Array.new(evaluator.teams_count) do |i|
          Account.create!(
            name: "Team #{i}",
            linked_account_account: AccountLinkedAccount.new(account_type: :linked, account:)
          )
        end
      end
    end
  end
end
