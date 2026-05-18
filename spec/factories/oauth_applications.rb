# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_application, class: 'Doorkeeper::Application' do
    sequence(:name) { |n| "MCP client #{n}" }
    redirect_uri { 'https://claude.ai/api/mcp/auth_callback' }
    scopes       { 'mcp' }
    confidential { false }
  end
end
