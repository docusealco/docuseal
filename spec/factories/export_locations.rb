# frozen_string_literal: true

FactoryBot.define do
  factory :export_location do
    name { Faker::Company.name }
    api_base_url { 'https://api.example.com' }
    default_location { false }
    extra_params { {} }
    templates_endpoint { '/templates' }
    submissions_endpoint { nil }
    authorization_token { nil }

    trait :with_submissions_endpoint do
      submissions_endpoint { '/submissions' }
    end

    trait :with_authorization_token do
      authorization_token { SecureRandom.hex(32) }
    end

    trait :default do
      default_location { true }
    end

    trait :with_extra_params do
      extra_params { { 'api_key' => 'test_key', 'version' => '1.0' } }
    end
  end
end
