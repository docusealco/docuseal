# frozen_string_literal: true

FactoryBot.define do
  factory :submission_event do
    submission
    submitter
    event_type { 'view_form' }
    event_timestamp { Time.zone.now }
    data do
      {
        ip: Faker::Internet.ip_v4_address,
        ua: Faker::Internet.user_agent,
        sid: SecureRandom.base58(10),
        uid: Faker::Number.number(digits: 4)
      }
    end
  end
end
