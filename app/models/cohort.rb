# frozen_string_literal: true

# == Schema Information
#
# Table name: cohorts
#
#  id                       :bigint           not null, primary key
#  cohort_metadata          :jsonb
#  deleted_at               :datetime
#  finalized_at             :datetime
#  name                     :string           not null
#  program_type             :string           not null
#  required_student_uploads :jsonb
#  sponsor_completed_at     :datetime
#  sponsor_email            :string           not null
#  status                   :string           default("draft")
#  students_completed_at    :datetime
#  tp_signed_at             :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  institution_id           :bigint           not null
#  template_id              :bigint           not null
#
# Indexes
#
#  index_cohorts_on_institution_id             (institution_id)
#  index_cohorts_on_institution_id_and_status  (institution_id,status)
#  index_cohorts_on_sponsor_email              (sponsor_email)
#  index_cohorts_on_template_id                (template_id)
#
# Foreign Keys
#
#  fk_rails_...  (institution_id => institutions.id)
#  fk_rails_...  (template_id => templates.id)
#
class Cohort < ApplicationRecord
  belongs_to :institution
  belongs_to :template

  has_many :cohort_enrollments, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :program_type, presence: true
  validates :sponsor_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  # Default scope for soft delete
  default_scope { where(deleted_at: nil) }

  # Soft delete scope
  scope :active, -> { where(deleted_at: nil) }
  scope :archived, -> { where.not(deleted_at: nil) }

  # Status scopes
  scope :draft, -> { where(status: 'draft') }
  scope :active_status, -> { where(status: 'active') }
  scope :completed, -> { where(status: 'completed') }
end
