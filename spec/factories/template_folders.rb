# frozen_string_literal: true

FactoryBot.define do
  factory :template_folder do
    account

    author factory: %i[user]
    name { Faker::Book.title }

    trait :with_templates do
      after(:create) do |template_folder|
        create_list(:template, 2, folder: template_folder, account: template_folder.account)
      end
    end
  end
end
