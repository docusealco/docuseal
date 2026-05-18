# frozen_string_literal: true

FactoryBot.define do
  factory :mcp_token do
    user
    sequence(:name) { |n| "MCP token #{n}" }
  end
end
