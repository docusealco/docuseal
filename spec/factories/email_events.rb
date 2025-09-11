# frozen_string_literal: true

FactoryBot.define do
  factory :email_event do
    account
    event_type { 'bounce' }
    message_id { SecureRandom.uuid }
    tag { 'submitter_invitation' }
    email { Faker::Internet.email }
    event_datetime { 1.hour.ago }
  end
end
