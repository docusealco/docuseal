# frozen_string_literal: true

FactoryBot.define do
  factory :partnership do
    external_partnership_id { Faker::Number.unique.number(digits: 8) }
    name { Faker::Company.name }
  end
end
