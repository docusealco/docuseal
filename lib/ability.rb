# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # Personal config is always accessible regardless of role.
    can :manage, EncryptedUserConfig, user_id: user.id
    can :manage, UserConfig, user_id: user.id
    can :manage, AccessToken, user_id: user.id

    case user.role
    when User::VIEWER_ROLE
      viewer_abilities(user)
    when User::EDITOR_ROLE
      editor_abilities(user)
    else
      admin_abilities(user)
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

    # Submissions/Submitters are scoped to creator or assigned signer,
    # regardless of role (admin included).
    can :create, Submission, account_id: user.account_id
    can %i[read update destroy], Submission, Submission.visible_to(user) do |submission|
      submission.account_id == user.account_id &&
        (submission.created_by_user_id == user.id ||
         submission.submitters.exists?(email: user.email))
    end
    can %i[read update destroy], Submitter, Submitter.visible_to(user) do |submitter|
      submitter.submission.account_id == user.account_id &&
        (submitter.submission.created_by_user_id == user.id ||
         submitter.submission.submitters.exists?(email: user.email))
    end

    can :manage, User, account_id: user.account_id
    can :manage, EncryptedConfig, account_id: user.account_id
    can :manage, AccountConfig, account_id: user.account_id
    can :manage, Account, id: user.account_id
    can :manage, McpToken, user_id: user.id
    can :manage, WebhookUrl, account_id: user.account_id
    can :manage, :mcp
  end

  def editor_abilities(user)
    can %i[read create update], Template, Abilities::TemplateConditions.collection(user) do |template|
      Abilities::TemplateConditions.entity(template, user:, ability: 'manage')
    end

    can :manage, TemplateFolder, account_id: user.account_id
    can :manage, TemplateSharing, template: { account_id: user.account_id }

    can :create, Submission, account_id: user.account_id
    can %i[read update], Submission, Submission.visible_to(user) do |submission|
      submission.account_id == user.account_id &&
        (submission.created_by_user_id == user.id ||
         submission.submitters.exists?(email: user.email))
    end
    can %i[read update], Submitter, Submitter.visible_to(user) do |submitter|
      submitter.submission.account_id == user.account_id &&
        (submitter.submission.created_by_user_id == user.id ||
         submitter.submission.submitters.exists?(email: user.email))
    end

    can :read, User, account_id: user.account_id
    can :read, Account, id: user.account_id
    can :read, AccountConfig, account_id: user.account_id
  end

  def viewer_abilities(user)
    can :read, Template, Abilities::TemplateConditions.collection(user) do |template|
      Abilities::TemplateConditions.entity(template, user:, ability: 'read')
    end

    can :read, TemplateFolder, account_id: user.account_id
    can :read, Submission, account_id: user.account_id, created_by_user_id: user.id
    can :read, Submitter, submission: { account_id: user.account_id, created_by_user_id: user.id }

    can :read, User, id: user.id
    can :read, Account, id: user.account_id
    can :read, AccountConfig, account_id: user.account_id
  end
end
