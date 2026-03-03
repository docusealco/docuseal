# frozen_string_literal: true

class Ability
  include CanCan::Ability

  # Maps config resource names → CanCan model + action rules.
  # All condition procs MUST return hashes (not AR relations) so that
  # class-level can?/authorize! checks work (e.g. `authorize! :index, Template`).
  RESOURCE_MAP = {
    'templates'   => [
      [Template,         :read,    ->(u) { { account_id: u.account_id } }],
      [Template,         :create,  ->(u) { { account_id: u.account_id } }],
      [Template,         :update,  ->(u) { { account_id: u.account_id } }],
      [Template,         :destroy, ->(u) { { account_id: u.account_id } }],
      [TemplateFolder,   :manage,  ->(u) { { account_id: u.account_id } }],
      [TemplateSharing,  :manage,  ->(u) { { template: { account_id: u.account_id } } }]
    ],
    'submissions' => [
      [Submission, :manage, ->(u) { { account_id: u.account_id } }],
      [Submitter,  :manage, ->(u) { { account_id: u.account_id } }]
    ],
    'users' => [
      [User, :manage, ->(u) { { account_id: u.account_id } }]
    ],
    'settings' => [
      [EncryptedConfig, :manage, ->(u) { { account_id: u.account_id } }],
      [AccountConfig,   :manage, ->(u) { { account_id: u.account_id } }],
      [Account,         :manage, ->(u) { { id: u.account_id } }],
      [WebhookUrl,      :manage, ->(u) { { account_id: u.account_id } }]
    ]
  }.freeze

  def initialize(user)
    return unless user

    always_allowed(user)
    apply_role_permissions(user)
  end

  private

  # Personal resources — always available regardless of role.
  def always_allowed(user)
    can :manage, EncryptedUserConfig, user_id: user.id
    can :manage, UserConfig, user_id: user.id
    can :manage, User, id: user.id
    can :read,   Account, id: user.account_id
    can :manage, AccessToken, user_id: user.id
  end

  def apply_role_permissions(user)
    role = user.role.to_s

    RESOURCE_MAP.each do |resource_key, model_rules|
      config_actions = Whitelabel.role_permissions(role, resource_key)

      model_rules.each do |model, cancan_action, condition_proc|
        grant_if_allowed(user, model, cancan_action, condition_proc, config_actions)
      end
    end
  end

  def grant_if_allowed(user, model, cancan_action, condition_proc, config_actions)
    needed = action_to_config(cancan_action)
    return unless (needed & config_actions).any?

    conditions = condition_proc.call(user)
    granted = map_cancan_actions(cancan_action, config_actions)
    return if granted.empty?

    # Hash-only conditions. Shared-template / linked-account filtering
    # is handled at the controller level (TemplateConditions.collection,
    # filter_templates, etc.) — CanCanCan forbids hash + block together.
    can granted, model, conditions
  end

  # Map a CanCan :manage action to the individual config actions that are allowed.
  def map_cancan_actions(cancan_action, config_actions)
    if cancan_action == :manage
      mapped = []
      mapped << :read    if config_actions.include?('read')
      mapped << :create  if config_actions.include?('create')
      mapped << :update  if config_actions.include?('update')
      mapped << :destroy if config_actions.include?('delete')
      mapped
    elsif cancan_action == :destroy
      config_actions.include?('delete') ? [:destroy] : []
    else
      config_actions.include?(cancan_action.to_s) ? [cancan_action] : []
    end
  end

  def action_to_config(cancan_action)
    case cancan_action
    when :manage  then %w[read create update delete]
    when :read    then %w[read]
    when :create  then %w[create]
    when :update  then %w[update]
    when :destroy then %w[delete]
    else [cancan_action.to_s]
    end
  end
end
