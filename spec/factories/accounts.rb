# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    name { Faker::Company.name }
    locale { 'en-US' }
    timezone { 'UTC' }
  end
end
