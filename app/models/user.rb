# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  archived_at            :datetime
#  consumed_timestep      :integer
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           not null
#  encrypted_password     :string           not null
#  failed_attempts        :integer          default(0), not null
#  first_name             :string
#  last_name              :string
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  locked_at              :datetime
#  otp_required_for_login :boolean          default(FALSE), not null
#  otp_secret             :string
#  provider               :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :string           not null
#  sign_in_count          :integer          default(0), not null
#  uid                    :string
#  unlock_token           :string
#  uuid                   :string           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :bigint           not null
#
# Indexes
#
#  index_users_on_account_id            (account_id)
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_provider_and_uid      (provider,uid) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#  index_users_on_uuid                  (uuid) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class User < ApplicationRecord
  ROLES = [
    ADMIN_ROLE = 'admin'
  ].freeze

  EMAIL_REGEXP = /[^@;,<>\s]+@[^@;,<>\s]+/

  FULL_EMAIL_REGEXP =
    /\A[a-z0-9][\.']?(?:(?:[a-z0-9_-]+[\.\+'])*[a-z0-9_-]+)*@(?:[a-z0-9]+[\.-])*[a-z0-9]+\.[a-z]{2,}\z/i

  has_one_attached :signature
  has_one_attached :initials

  belongs_to :account
  has_one :access_token, dependent: :destroy
  has_many :access_tokens, dependent: :destroy
  has_many :templates, dependent: :destroy, foreign_key: :author_id, inverse_of: :author
  has_many :template_folders, dependent: :destroy, foreign_key: :author_id, inverse_of: :author
  has_many :user_configs, dependent: :destroy
  has_many :encrypted_configs, dependent: :destroy, class_name: 'EncryptedUserConfig'
  has_many :email_messages, dependent: :destroy, foreign_key: :author_id, inverse_of: :author

  devise :two_factor_authenticatable, :recoverable, :rememberable, :validatable, :trackable, :lockable, :omniauthable, omniauth_providers: %i[saml google_oauth2 microsoft_graph]

  attribute :role, :string, default: ADMIN_ROLE
  attribute :uuid, :string, default: -> { SecureRandom.uuid }

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :admins, -> { where(role: ADMIN_ROLE) }

  validates :email, format: { with: /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\z/ }

  def access_token
    super || build_access_token.tap(&:save!)
  end

  def active_for_authentication?
    super && !archived_at? && !account.archived_at?
  end

  def remember_me
    true
  end

  def sidekiq?
    return true if Rails.env.development?

    role == 'admin'
  end

  def self.sign_in_after_reset_password
    if PasswordsController::Current.user.present?
      !PasswordsController::Current.user.otp_required_for_login
    else
      true
    end
  end

  def initials
    [first_name&.first, last_name&.first].compact_blank.join.upcase
  end

  def full_name
    [first_name, last_name].compact_blank.join(' ')
  end

  def friendly_name
    if full_name.present?
      %("#{full_name.delete('"')}" <#{email}>)
    else
      email
    end
  end

  # Omniauth callback method
  def self.from_omniauth(auth)
    # Find existing user by provider and uid
    user = User.find_by(provider: auth.provider, uid: auth.uid)
    
    if user
      # Update user info from provider if needed
      user.update(
        email: auth.info.email,
        first_name: auth.info.first_name || auth.info.name&.split&.first,
        last_name: auth.info.last_name || auth.info.name&.split&.last
      ) if auth.info.email.present?
      return user
    end

    # Try to find user by email if no provider/uid match
    existing_user = User.find_by(email: auth.info.email) if auth.info.email.present?
    
    if existing_user
      # Link existing account with omniauth provider
      existing_user.update(
        provider: auth.provider,
        uid: auth.uid
      )
      return existing_user
    end

    # Create new user from omniauth data
    # For multitenant setups, we need to determine the account
    account = if Docuseal.multitenant?
                # In multitenant mode, create account from domain or use default logic
                Account.find_or_create_by(name: auth.info.email&.split('@')&.last || 'SSO Account')
              else
                # In single-tenant mode, use the first account or create one
                Account.first || Account.create!(name: 'Default Account')
              end

    User.create!(
      email: auth.info.email,
      first_name: auth.info.first_name || auth.info.name&.split&.first,
      last_name: auth.info.last_name || auth.info.name&.split&.last,
      provider: auth.provider,
      uid: auth.uid,
      account: account,
      # Skip password validation for omniauth users
      password: Devise.friendly_token[0, 20]
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create user from omniauth: #{e.message}"
    nil
  end
end
