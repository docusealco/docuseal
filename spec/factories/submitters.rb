# frozen_string_literal: true

FactoryBot.define do
  factory :submitter do
    submission
    email { Faker::Internet.email }
  end
end
