# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user

    can :manage, EncryptedUserConfig, user_id: user.id
    can :manage, UserConfig, user_id: user.id
    can :manage, AccessToken, user_id: user.id
    can :manage, McpToken, user_id: user.id

    if user.role == User::ADMIN_ROLE
      admin_abilities(user)
    elsif user.role == User::EDITOR_ROLE
      editor_abilities(user)
    end
  end

  private

  def admin_abilities(user)
    can %i[read create update], Template, Abilities::TemplateConditions.collection(user) do |template|
      Abilities::TemplateConditions.entity(template, user:, ability: 'manage')
    end

    can :destroy, Template, account_id: user.account_id
    can :manage, TemplateFolder, account_id: user.account_id
    can :manage, TemplateSharing, template: { account_id: user.account_id }
    can :manage, Submission, account_id: user.account_id
    can :manage, Submitter, account_id: user.account_id
    can :manage, User, account_id: user.account_id
    can :manage, EncryptedConfig, account_id: user.account_id
    can :manage, AccountConfig, account_id: user.account_id
    can :manage, Account, id: user.account_id
    can :manage, WebhookUrl, account_id: user.account_id
    can :manage, Team, account_id: user.account_id
    can :manage, :mcp
  end

  def editor_abilities(user)
    can %i[read create update], Template, team_id: user.team_id, account_id: user.account_id
    can :destroy, Template, team_id: user.team_id, account_id: user.account_id
    can :manage, TemplateFolder, team_id: user.team_id, account_id: user.account_id
    can :read, TemplateSharing, template: { team_id: user.team_id, account_id: user.account_id }
    can :manage, Submission, team_id: user.team_id, account_id: user.account_id
    can :manage, Submitter, team_id: user.team_id, account_id: user.account_id
    can :manage, AccountConfig, account_id: user.account_id
    can :manage, WebhookUrl, account_id: user.account_id

    can :read, User, id: user.id
    can :update, User, id: user.id
    can :read, Team, id: user.team_id
  end
end
