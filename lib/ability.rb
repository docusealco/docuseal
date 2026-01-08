# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # Existing DocuSeal permissions (unchanged)
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

    # FloDoc Institution Management Permissions
    # Layer 2: Model-level authorization

    # Super Admin Permissions
    if user.cohort_super_admin?
      can :manage, Institution, id: user.managed_institutions.select(:id)
      can :manage, Cohort, institution_id: user.managed_institutions.select(:id)
      can :manage, Sponsor, institution_id: user.managed_institutions.select(:id)
      can :manage, CohortAdminInvitation, institution_id: user.managed_institutions.select(:id)
      can :read, SecurityEvent, user_id: user.id
    end

    # Regular Admin Permissions
    if user.cohort_admin?
      can :read, Institution, id: user.institutions.select(:id)
      can :manage, Cohort, institution_id: user.institutions.select(:id)
      can :read, Sponsor, institution_id: user.institutions.select(:id)
    end

    # Security Event Access (for monitoring)
    can :read, SecurityEvent do |event|
      event.user_id == user.id || user.cohort_super_admin?
    end
  end
end
