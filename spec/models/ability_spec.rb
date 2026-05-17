# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

RSpec.describe Ability do
  let(:account)       { create(:account) }
  let(:other_account) { create(:account) }

  def template_for(account)
    Template.new(account_id: account.id)
  end

  def template_folder_for(account)
    TemplateFolder.new(account_id: account.id)
  end

  def submission_for(account)
    Submission.new(account_id: account.id)
  end

  def submitter_for(account)
    Submitter.new(account_id: account.id)
  end

  shared_examples 'personal-resource grants' do
    it 'manages own User, UserConfig, EncryptedUserConfig, AccessToken' do
      expect(ability).to be_able_to(:manage, user)
      expect(ability).to be_able_to(:manage, UserConfig.new(user_id: user.id))
      expect(ability).to be_able_to(:manage, EncryptedUserConfig.new(user_id: user.id))
      expect(ability).to be_able_to(:manage, AccessToken.new(user_id: user.id))
      expect(ability).to be_able_to(:read, Account.new.tap { |a| a.id = account.id })
    end

    it "cannot touch another user's User / UserConfig / AccessToken (unless admin)" do
      other_user = create(:user, account: account)
      expect(ability).not_to be_able_to(:manage, UserConfig.new(user_id: other_user.id))
      expect(ability).not_to be_able_to(:manage, AccessToken.new(user_id: other_user.id))

      # Admin's full :manage User rule covers same-account users; editor/viewer don't.
      if user.role == User::ADMIN_ROLE
        expect(ability).to be_able_to(:manage, other_user)
      else
        expect(ability).not_to be_able_to(:manage, other_user)
      end
    end
  end

  describe 'admin role' do
    let(:user) { create(:user, account: account, role: User::ADMIN_ROLE) }
    let(:ability) { described_class.new(user) }

    include_examples 'personal-resource grants'

    it 'manages templates, folders, sharings, submissions, submitters in own account' do
      expect(ability).to be_able_to(:read,    template_for(account))
      expect(ability).to be_able_to(:create,  template_for(account))
      expect(ability).to be_able_to(:update,  template_for(account))
      expect(ability).to be_able_to(:destroy, template_for(account))
      expect(ability).to be_able_to(:manage,  template_folder_for(account))
      expect(ability).to be_able_to(:manage,  submission_for(account))
      expect(ability).to be_able_to(:manage,  submitter_for(account))
    end

    it 'manages account-wide settings and users' do
      expect(ability).to be_able_to(:manage, User.new(account_id: account.id))
      expect(ability).to be_able_to(:manage, Account.new.tap { |a| a.id = account.id })
      expect(ability).to be_able_to(:manage, AccountConfig.new(account_id: account.id))
      expect(ability).to be_able_to(:manage, EncryptedConfig.new(account_id: account.id))
      expect(ability).to be_able_to(:manage, WebhookUrl.new(account_id: account.id))
      expect(ability).to be_able_to(:manage, McpToken.new(user_id: user.id))
      expect(ability).to be_able_to(:manage, :mcp)
    end

    it 'cannot touch resources scoped to another account' do
      expect(ability).not_to be_able_to(:read,    template_for(other_account))
      expect(ability).not_to be_able_to(:destroy, template_for(other_account))
      expect(ability).not_to be_able_to(:manage,  submission_for(other_account))
      expect(ability).not_to be_able_to(:manage,  User.new(account_id: other_account.id))
      expect(ability).not_to be_able_to(:manage,  Account.new.tap { |a| a.id = other_account.id })
    end
  end

  describe 'editor role' do
    let(:user) { create(:user, account: account, role: User::EDITOR_ROLE) }
    let(:ability) { described_class.new(user) }

    include_examples 'personal-resource grants'

    it 'manages templates, folders, sharings, submissions, submitters in own account' do
      expect(ability).to be_able_to(:read,    template_for(account))
      expect(ability).to be_able_to(:create,  template_for(account))
      expect(ability).to be_able_to(:update,  template_for(account))
      expect(ability).to be_able_to(:destroy, template_for(account))
      expect(ability).to be_able_to(:manage,  template_folder_for(account))
      expect(ability).to be_able_to(:manage,  submission_for(account))
      expect(ability).to be_able_to(:manage,  submitter_for(account))
    end

    it 'can read AccountConfig but cannot manage account-wide settings' do
      expect(ability).to     be_able_to(:read,   AccountConfig.new(account_id: account.id))
      expect(ability).not_to be_able_to(:manage, AccountConfig.new(account_id: account.id))
      expect(ability).not_to be_able_to(:manage, EncryptedConfig.new(account_id: account.id))
      expect(ability).not_to be_able_to(:manage, User.new(account_id: account.id))
      expect(ability).not_to be_able_to(:manage, Account.new.tap { |a| a.id = account.id })
      expect(ability).not_to be_able_to(:manage, WebhookUrl.new(account_id: account.id))
      expect(ability).not_to be_able_to(:manage, McpToken.new(user_id: user.id))
      expect(ability).not_to be_able_to(:manage, :mcp)
    end

    it 'cannot touch resources scoped to another account' do
      expect(ability).not_to be_able_to(:read,   template_for(other_account))
      expect(ability).not_to be_able_to(:manage, submission_for(other_account))
    end
  end

  describe 'viewer role' do
    let(:user) { create(:user, account: account, role: User::VIEWER_ROLE) }
    let(:ability) { described_class.new(user) }

    include_examples 'personal-resource grants'

    it 'reads templates, folders, sharings, submissions, submitters in own account' do
      expect(ability).to be_able_to(:read, template_for(account))
      expect(ability).to be_able_to(:read, template_folder_for(account))
      expect(ability).to be_able_to(:read, submission_for(account))
      expect(ability).to be_able_to(:read, submitter_for(account))
      expect(ability).to be_able_to(:read, AccountConfig.new(account_id: account.id))
    end

    it 'cannot mutate anything in own account beyond personal resources' do
      expect(ability).not_to be_able_to(:create,  template_for(account))
      expect(ability).not_to be_able_to(:update,  template_for(account))
      expect(ability).not_to be_able_to(:destroy, template_for(account))
      expect(ability).not_to be_able_to(:manage,  template_folder_for(account))
      expect(ability).not_to be_able_to(:manage,  submission_for(account))
      expect(ability).not_to be_able_to(:manage,  submitter_for(account))
      expect(ability).not_to be_able_to(:manage,  User.new(account_id: account.id))
      expect(ability).not_to be_able_to(:manage,  AccountConfig.new(account_id: account.id))
      expect(ability).not_to be_able_to(:manage,  EncryptedConfig.new(account_id: account.id))
      expect(ability).not_to be_able_to(:manage,  WebhookUrl.new(account_id: account.id))
      expect(ability).not_to be_able_to(:manage,  Account.new.tap { |a| a.id = account.id })
      expect(ability).not_to be_able_to(:manage,  :mcp)
    end

    it 'cannot read resources scoped to another account' do
      expect(ability).not_to be_able_to(:read, template_for(other_account))
      expect(ability).not_to be_able_to(:read, submission_for(other_account))
    end
  end

  describe 'unknown role' do
    let(:user) { create(:user, account: account, role: User::ADMIN_ROLE).tap { |u| u.update_column(:role, 'mystery') } }
    let(:ability) { described_class.new(user) }

    it 'still grants personal resources but no role-specific abilities' do
      expect(ability).to     be_able_to(:manage, UserConfig.new(user_id: user.id))
      expect(ability).not_to be_able_to(:read,   template_for(account))
      expect(ability).not_to be_able_to(:manage, submission_for(account))
    end
  end
end
