# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    password { "password123" }
    password_confirmation { "password123" }
    email_address { "user#{SecureRandom.hex(3)}@example.com" }
  end
end
