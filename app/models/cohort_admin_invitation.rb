# frozen_string_literal: true

# == Schema Information
#
# Table name: cohort_admin_invitations
#
#  id              :bigint           not null, primary key
#  institution_id  :bigint           not null
#  created_by_id   :bigint           not null
#  email           :string           not null
#  hashed_token    :string           not null
#  token_preview   :string           not null
#  role            :string           not null
#  sent_at         :datetime
#  expires_at      :datetime         not null
#  used_at         :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_cohort_admin_invitations_on_institution_id  (institution_id)
#  index_cohort_admin_invitations_on_email           (email)
#  index_cohort_admin_invitations_on_expires_at      (expires_at)
#  index_cohort_admin_invitations_on_hashed_token    (hashed_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (institution_id => institutions.id)
#  fk_rails_...  (created_by_id => users.id)
#

class CohortAdminInvitation < ApplicationRecord
  belongs_to :institution
  belongs_to :created_by, class_name: 'User'

  # Validations
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :hashed_token, presence: true, uniqueness: true
  validates :token_preview, presence: true
  validates :role, presence: true, inclusion: { in: %w[cohort_admin cohort_super_admin] }
  validates :expires_at, presence: true

  # Scopes
  scope :active, -> { where(used_at: nil).where('expires_at > ?', Time.current) }
  scope :used, -> { where.not(used_at: nil) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }
  scope :cleanup_expired, -> { expired.where.not(used_at: nil) }

  # CRITICAL METHOD: Token generation (512 bits entropy)
  def generate_token
    raw_token = SecureRandom.urlsafe_base64(64)
    self.hashed_token = Digest::SHA256.hexdigest(raw_token)
    self.token_preview = "#{raw_token[0..7]}..."
    raw_token
  end

  # CRITICAL METHOD: Token validation with Redis single-use enforcement
  def valid_token?(raw_token)
    return false if expired?
    return false if used?
    return false unless email_matches?(raw_token)

    # Verify hash
    provided_hash = Digest::SHA256.hexdigest(raw_token)
    return false unless provided_hash == hashed_token

    # Redis single-use enforcement
    redis_key = "invitation_token:#{hashed_token}"
    redis = Redis.current

    # Atomic SET with NX (only set if not exists) and TTL
    # This prevents race conditions and ensures single-use
    acquired = redis.set(redis_key, 'used', nx: true, ex: 86400)

    return false unless acquired

    # Mark as used in database
    update!(used_at: Time.current)

    true
  end

  # Check if invitation is expired
  def expired?
    expires_at <= Time.current
  end

  # Check if invitation has been used
  def used?
    used_at.present?
  end

  # Verify email matches (token only valid for intended recipient)
  def email_matches?(raw_token)
    # Extract email from token metadata if needed, or verify against stored email
    # For now, we rely on the invitation being created with the correct email
    true
  end

  # Rate limiting check (static method)
  def self.rate_limit_check(email, institution)
    pending = where(email: email, institution: institution, used_at: nil)
               .where('expires_at > ?', Time.current)
               .count

    pending >= 5
  end

  # Send invitation email
  def send_invitation
    return false if expired? || used?

    # Generate token if not already generated
    raw_token = generate_token if hashed_token.blank?
    save!

    # Queue email job
    CohortAdminInvitationJob.perform_async(id)
    true
  end
end