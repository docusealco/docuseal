# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    template_scope = Abilities::TemplateConditions.collection(user)
    template_check = ->(template) { Abilities::TemplateConditions.entity(template, user: user, ability: 'manage') }

    can :read, Template, template_scope, &template_check
    can :read, TemplateFolder, account_id: user.account_id
    can :read, Submission, account_id: user.account_id
    can :read, Submitter, account_id: user.account_id
    can :manage, UserConfig, user_id: user.id
    can :manage, EncryptedUserConfig, user_id: user.id
    can :read, Account, id: user.account_id

    return if user.viewer?

    can %i[create update], Template, template_scope, &template_check
    can :destroy, Template, account_id: user.account_id
    can :manage, TemplateFolder, account_id: user.account_id
    can :manage, TemplateSharing, template: { account_id: user.account_id }
    can :manage, Submission, account_id: user.account_id
    can :manage, Submitter, account_id: user.account_id
    can :manage, AccessToken, user_id: user.id

    return unless user.admin?

    can :manage, User, account_id: user.account_id
    can :manage, EncryptedConfig, account_id: user.account_id
    can :manage, AccountConfig, account_id: user.account_id
    can :manage, Account, id: user.account_id
    can :manage, McpToken, user_id: user.id
    can :manage, WebhookUrl, account_id: user.account_id

    can :manage, :mcp
    can :manage, :personalization_advanced
    can :manage, :reply_to
    can :manage, :download_users
    can :manage, :bulk_send
    can :manage, :disable_decline
    can :manage, :delegate_form
    can :manage, :countless
  end
end
