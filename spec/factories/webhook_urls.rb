# frozen_string_literal: true

FactoryBot.define do
  factory :webhook_url do
    account
    url { Faker::Internet.url }
  end
end
