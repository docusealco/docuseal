# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    case user.role
    when User::ADMIN_ROLE
      admin_abilities(user)
    when User::GESTIONNAIRE_ROLE
      gestionnaire_abilities(user)
    when User::USER_ROLE
      user_abilities(user)
    end
  end

  private

  # Accès complet à tout le compte
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
    can :manage, EncryptedUserConfig, user_id: user.id
    can :manage, AccountConfig, account_id: user.account_id
    can :manage, UserConfig, user_id: user.id
    can :manage, Account, id: user.account_id
    can :manage, AccessToken, user_id: user.id
    can :manage, WebhookUrl, account_id: user.account_id
  end

  # Peut créer/gérer documents et envois — pas les paramètres ni les utilisateurs
  def gestionnaire_abilities(user)
    can %i[read create update], Template, Abilities::TemplateConditions.collection(user) do |template|
      Abilities::TemplateConditions.entity(template, user:, ability: 'manage')
    end

    can :destroy, Template, account_id: user.account_id
    can :manage, TemplateFolder, account_id: user.account_id
    can :manage, TemplateSharing, template: { account_id: user.account_id }
    can :manage, Submission, account_id: user.account_id
    can :manage, Submitter, account_id: user.account_id
    can :manage, EncryptedUserConfig, user_id: user.id
    can :manage, UserConfig, user_id: user.id
    can :manage, User, id: user.id
    can :read,   Account, id: user.account_id
    can :manage, AccessToken, user_id: user.id
  end

  # Lecture seule — ne peut pas créer ni modifier
  def user_abilities(user)
    can :read, Template, Abilities::TemplateConditions.collection(user) do |template|
      Abilities::TemplateConditions.entity(template, user:)
    end

    can :read, TemplateFolder, account_id: user.account_id
    can :read, Submission, account_id: user.account_id
    can :read, Submitter, account_id: user.account_id
    can :manage, EncryptedUserConfig, user_id: user.id
    can :manage, UserConfig, user_id: user.id
    can :manage, User, id: user.id
    can :read,   Account, id: user.account_id
    can :manage, AccessToken, user_id: user.id
  end
end
