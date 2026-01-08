# frozen_string_literal: true

# == Schema Information
#
# Table name: institutions
#
#  id                 :bigint           not null, primary key
#  account_id         :bigint           not null
#  super_admin_id     :bigint           not null
#  name               :string           not null
#  registration_number :string
#  address            :text
#  contact_email      :string
#  contact_phone      :string
#  settings           :jsonb            not null, default: {}
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_institutions_on_account_id                  (account_id) UNIQUE
#  index_institutions_on_account_id_and_registration_number  (account_id,registration_number) UNIQUE WHERE (registration_number IS NOT NULL)
#  index_institutions_on_super_admin_id              (super_admin_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (super_admin_id => users.id)
#

class Institution < ApplicationRecord
  belongs_to :account
  belongs_to :super_admin, class_name: 'User'

  # Layer 1: Foundation relationships
  has_many :cohorts, dependent: :destroy
  has_many :sponsors, dependent: :destroy
  has_many :account_accesses, dependent: :destroy
  has_many :cohort_admin_invitations, dependent: :destroy

  # Layer 2: User access relationships
  has_many :users, through: :account_accesses

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 255 }
  validates :registration_number, uniqueness: { scope: :account_id, case_sensitive: false }, allow_nil: true
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
  validates :contact_phone, format: { with: /\A\+?[1-9]\d{1,14}\z/ }, allow_nil: true

  # CRITICAL SCOPE: Layer 3 isolation - used in ALL queries
  scope :for_user, ->(user) { where(id: user.institutions.select(:id)) }

  # CRITICAL SCOPE: Super admin management scope
  scope :managed_by, ->(user) { where(super_admin_id: user.id) }

  # CRITICAL METHOD: Security check for user access
  def accessible_by?(user)
    account_accesses.exists?(user_id: user.id)
  end

  # Helper methods for role checking
  def super_admin?(user)
    super_admin_id == user.id
  end

  def user_role(user)
    account_accesses.find_by(user_id: user)&.role
  end

  # Settings accessor with defaults
  def settings_with_defaults
    {
      allow_student_enrollment: settings['allow_student_enrollment'] || true,
      require_verification: settings['require_verification'] || true,
      auto_finalize: settings['auto_finalize'] || false,
      email_notifications: settings['email_notifications'] || true,
      **settings
    }.with_indifferent_access
  end
end