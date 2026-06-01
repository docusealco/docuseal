# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  archived_at            :datetime
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
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
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :string           not null
#  sign_in_count          :integer          default(0), not null
#  unconfirmed_email      :string
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
    ADMIN_ROLE  = 'admin',
    EDITOR_ROLE = 'editor',
    VIEWER_ROLE = 'viewer'
  ].freeze

  EMAIL_REGEXP = /[^@;,<>\s]+@[^@;,<>\s]+/

  FULL_EMAIL_REGEXP =
    /\A[a-z0-9][.']?(?:(?:[a-z0-9_-]+[.+'])*[a-z0-9_-]+)*@(?:[a-z0-9]+[.-])*[a-z0-9]+\.[a-z]{2,}\z/i

  has_one_attached :signature
  has_one_attached :initials

  belongs_to :account
  has_one :access_token, dependent: :destroy
  has_many :access_tokens, dependent: :destroy
  has_many :mcp_tokens, dependent: :destroy
  has_many :templates, dependent: :destroy, foreign_key: :author_id, inverse_of: :author
  has_many :template_folders, dependent: :destroy, foreign_key: :author_id, inverse_of: :author
  has_many :user_configs, dependent: :destroy
  has_many :encrypted_configs, dependent: :destroy, class_name: 'EncryptedUserConfig'
  has_many :email_messages, dependent: :destroy, foreign_key: :author_id, inverse_of: :author

  devise :two_factor_authenticatable, :recoverable, :rememberable, :validatable, :trackable, :lockable, :omniauthable

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

  def admin?  = role == ADMIN_ROLE
  def editor? = role == EDITOR_ROLE
  def viewer? = role == VIEWER_ROLE

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

  def signed_in_via_sso?
    provider == 'google_oauth2' && uid.present?
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

  def self.from_google_omniauth(auth)
    raw_info = auth.extra&.raw_info
    hosted_domain = raw_info.respond_to?(:hd) ? raw_info.hd : raw_info&.dig('hd')
    return nil unless Wabosign.google_domain_allowed?(hosted_domain)

    email = auth.info.email.to_s.downcase
    return nil if email.blank?

    user = find_by('lower(email) = ?', email)
    if user
      return nil if user.provider.present? && user.uid != auth.uid

      user.update!(provider: 'google_oauth2', uid: auth.uid) if user.provider.blank?
      return user
    end

    account = default_sso_account
    return nil if account.nil?

    create!(
      account: account,
      email: email,
      first_name: auth.info.first_name,
      last_name: auth.info.last_name,
      role: ADMIN_ROLE,
      password: SecureRandom.hex(32),
      provider: 'google_oauth2',
      uid: auth.uid,
      confirmed_at: Time.current
    )
  end

  def self.default_sso_account
    Account.where(archived_at: nil).order(:created_at).first
  end
end
