# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return if user.blank?

    grant_personal_abilities(user)

    case user.role
    when User::ADMIN_ROLE  then grant_admin_abilities(user)
    when User::EDITOR_ROLE then grant_editor_abilities(user)
    when User::VIEWER_ROLE then grant_viewer_abilities(user)
    end
  end

  private

  def grant_personal_abilities(user)
    can :read,   Account,             id: user.account_id
    can :manage, User,                id: user.id
    can :manage, UserConfig,          user_id: user.id
    can :manage, EncryptedUserConfig, user_id: user.id
    can :manage, AccessToken,         user_id: user.id
  end

  def grant_admin_abilities(user)
    can %i[read create update], Template, Abilities::TemplateConditions.collection(user) do |template|
      Abilities::TemplateConditions.entity(template, user:, ability: 'manage')
    end

    can :destroy, Template,        account_id: user.account_id
    can :manage,  TemplateFolder,  account_id: user.account_id
    can :manage,  TemplateSharing, template:   { account_id: user.account_id }
    can :manage,  Submission,      account_id: user.account_id
    can :manage,  Submitter,       account_id: user.account_id
    can :manage,  User,            account_id: user.account_id
    can :manage,  EncryptedConfig, account_id: user.account_id
    can :manage,  AccountConfig,   account_id: user.account_id
    can :manage,  Account,         id:         user.account_id
    can :manage,  McpToken,        user_id:    user.id
    can :manage,  WebhookUrl,      account_id: user.account_id

    can :manage, :mcp
  end

  def grant_editor_abilities(user)
    can %i[read create update], Template, Abilities::TemplateConditions.collection(user) do |template|
      Abilities::TemplateConditions.entity(template, user:, ability: 'manage')
    end

    can :destroy, Template,        account_id: user.account_id
    can :manage,  TemplateFolder,  account_id: user.account_id
    can :manage,  TemplateSharing, template:   { account_id: user.account_id }
    can :manage,  Submission,      account_id: user.account_id
    can :manage,  Submitter,       account_id: user.account_id
    can :read,    AccountConfig,   account_id: user.account_id
  end

  def grant_viewer_abilities(user)
    can :read, Template, Abilities::TemplateConditions.collection(user, ability: :read) do |template|
      Abilities::TemplateConditions.entity(template, user:, ability: 'read')
    end

    can :read, TemplateFolder,  account_id: user.account_id
    can :read, TemplateSharing, template:   { account_id: user.account_id }
    can :read, Submission,      account_id: user.account_id
    can :read, Submitter,       account_id: user.account_id
    can :read, AccountConfig,   account_id: user.account_id
  end
end
