# frozen_string_literal: true

# == Schema Information
#
# Table name: cohort_enrollments
#
#  id                 :bigint           not null, primary key
#  completed_at       :datetime
#  deleted_at         :datetime
#  role               :string           default("student")
#  status             :string           default("waiting")
#  student_email      :string           not null
#  student_name       :string
#  student_surname    :string
#  uploaded_documents :jsonb
#  values             :jsonb
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  cohort_id          :bigint           not null
#  student_id         :string
#  submission_id      :bigint           not null
#
# Indexes
#
#  index_cohort_enrollments_on_cohort_id                    (cohort_id)
#  index_cohort_enrollments_on_cohort_id_and_status         (cohort_id,status)
#  index_cohort_enrollments_on_cohort_id_and_student_email  (cohort_id,student_email) UNIQUE
#  index_cohort_enrollments_on_submission_id                (submission_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (cohort_id => cohorts.id)
#  fk_rails_...  (submission_id => submissions.id)
#
class CohortEnrollment < ApplicationRecord
  belongs_to :cohort
  belongs_to :submission

  # Validations
  validates :student_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :submission_id, uniqueness: true

  # Unique constraint: one enrollment per student per cohort
  validates :student_email, uniqueness: { scope: :cohort_id, case_sensitive: false }

  # Soft delete scope
  scope :active, -> { where(deleted_at: nil) }
  scope :archived, -> { where.not(deleted_at: nil) }

  # Status scopes
  scope :waiting, -> { where(status: 'waiting') }
  scope :in_progress, -> { where(status: 'in_progress') }
  scope :complete, -> { where(status: 'complete') }
end
