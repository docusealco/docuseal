# frozen_string_literal: true

FactoryBot.define do
  factory :submitter do
    submission
    email { Faker::Internet.email }
    name { Faker::Name.name }

    before(:create) do |submitter, _|
      submitter.account_id = submitter.submission.account_id
    end
  end
end
