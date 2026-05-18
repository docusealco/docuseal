# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OauthApplicationSweeperJob do
  it 'deletes apps older than 90 days with no active access tokens' do
    old_dead = create(:oauth_application, created_at: 100.days.ago)
    old_live = create(:oauth_application, created_at: 100.days.ago)
    recent   = create(:oauth_application, created_at: 1.day.ago)

    user = create(:user)
    create(:oauth_access_token, application: old_live, resource_owner_id: user.id, scopes: 'mcp')

    described_class.new.perform

    expect(Doorkeeper::Application.exists?(id: old_dead.id)).to be(false)
    expect(Doorkeeper::Application.exists?(id: old_live.id)).to be(true)
    expect(Doorkeeper::Application.exists?(id: recent.id)).to be(true)
  end
end
