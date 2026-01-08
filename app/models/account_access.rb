# frozen_string_literal: true

# == Schema Information
#
# Table name: account_accesses
#
#  id              :bigint           not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  user_id         :bigint           not null
#  institution_id  :bigint           not null
#  role            :string           not null, default: 'member'
#
# Indexes
#
#  index_account_accesses_on_account_id_and_user_id  (account_id,user_id) UNIQUE
#  index_account_accesses_on_user_id_and_institution_id  (user_id,institution_id) UNIQUE
#  index_account_accesses_on_role                    (role)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_account_accesses_to_institutions  (institution_id => institutions.id)
#
class AccountAccess < ApplicationRecord
  belongs_to :account
  belongs_to :user
  belongs_to :institution  # Layer 1: Critical for data isolation

  # Layer 2: Role enum with new cohort roles
  enum :role, {
    # Existing DocuSeal roles
    member: 'member',
    admin: 'admin',
    # New FloDoc cohort roles
    cohort_admin: 'cohort_admin',
    cohort_super_admin: 'cohort_super_admin'
  }

  # Layer 3: Validations for security
  validates :user_id, uniqueness: { scope: :institution_id }
  validates :role, presence: true, inclusion: { in: roles.keys }

  # Layer 4: Scopes for efficient querying
  scope :cohort_admins, -> { where(role: 'cohort_admin') }
  scope :cohort_super_admins, -> { where(role: 'cohort_super_admin') }
  scope :for_institution, ->(institution) { where(institution: institution) }
  scope :for_user, ->(user) { where(user: user) }

  # Helper methods
  def cohort_super_admin?
    role == 'cohort_super_admin'
  end

  def cohort_admin?
    role == 'cohort_admin'
  end
end
