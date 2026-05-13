# frozen_string_literal: true

FactoryBot.define do
  factory :team do
    account
    name { Faker::Team.name }
  end
end
