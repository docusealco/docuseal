# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    account
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    password { 'password' }
    role { User::ADMIN_ROLE }
    email { Faker::Internet.email }
  end
end
