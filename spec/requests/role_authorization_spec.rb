# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Role-based authorization', type: :request do
  let!(:account) { create(:account) }
  let!(:admin)   { create(:user, account: account, role: User::ADMIN_ROLE,  email: 'admin@wabo.cc') }
  let!(:editor)  { create(:user, account: account, role: User::EDITOR_ROLE, email: 'editor@wabo.cc') }
  let!(:viewer)  { create(:user, account: account, role: User::VIEWER_ROLE, email: 'viewer@wabo.cc') }

  # `ApplicationController` rescues `CanCan::AccessDenied` only in production/test
  # and redirects to `root_path` (see app/controllers/application_controller.rb).
  def expect_denied
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to(root_path)
  end

  shared_examples 'an admin-only settings route' do |path_helper|
    it "is denied for editors (#{path_helper})" do
      sign_in editor
      get send(path_helper)
      expect_denied
    end

    it "is denied for viewers (#{path_helper})" do
      sign_in viewer
      get send(path_helper)
      expect_denied
    end

    it "is reachable for admins (#{path_helper})" do
      sign_in admin
      get send(path_helper)
      expect(response).to have_http_status(:ok).or have_http_status(:found)
      expect(response).not_to redirect_to(root_path) if response.status == 302
    end
  end

  describe 'admin-only settings' do
    include_examples 'an admin-only settings route', :settings_users_path
    include_examples 'an admin-only settings route', :settings_sso_index_path
    include_examples 'an admin-only settings route', :settings_webhooks_path
    include_examples 'an admin-only settings route', :settings_esign_path

    # Personalization's GET reads `AccountConfig`, which Editor/Viewer can do
    # (so UI chrome renders correctly). Writes are gated by :create AccountConfig,
    # which only admins hold.
    it 'lets editors view personalization but blocks the POST' do
      sign_in editor
      get settings_personalization_path
      expect(response).to have_http_status(:ok)

      post settings_personalization_path, params: {
        account_config: { key: AccountConfig::FORM_COMPLETED_BUTTON_KEY, value: { title: 'Done', url: '' } }
      }
      expect(response).to redirect_to(root_path)
    end

    it 'lets viewers view personalization but blocks the POST' do
      sign_in viewer
      get settings_personalization_path
      expect(response).to have_http_status(:ok)

      post settings_personalization_path, params: {
        account_config: { key: AccountConfig::FORM_COMPLETED_BUTTON_KEY, value: { title: 'Done', url: '' } }
      }
      expect(response).to redirect_to(root_path)
    end
  end

  describe 'templates and submissions list pages' do
    it 'are reachable for editors' do
      sign_in editor
      get templates_path
      expect(response).to have_http_status(:ok)
      get submissions_path
      expect(response).to have_http_status(:ok)
    end

    it 'are reachable for viewers' do
      sign_in viewer
      get templates_path
      expect(response).to have_http_status(:ok)
      get submissions_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'self-service profile' do
    it 'is reachable for editors and viewers' do
      sign_in editor
      get settings_profile_index_path
      expect(response).to have_http_status(:ok)

      sign_out editor
      sign_in viewer
      get settings_profile_index_path
      expect(response).to have_http_status(:ok)
    end
  end
end
