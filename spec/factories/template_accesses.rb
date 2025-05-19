# frozen_string_literal: true

FactoryBot.define do
  factory :template_access do
    template
    user
  end
end
