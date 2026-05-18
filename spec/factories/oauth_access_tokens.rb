# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_access_token, class: 'Doorkeeper::AccessToken' do
    application { association :oauth_application }
    resource_owner_id { association(:user).id }
    scopes      { 'mcp' }
    expires_in  { 3600 }
  end
end
