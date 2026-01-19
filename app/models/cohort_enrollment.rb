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
  include SoftDeletable

  # Strip whitespace from string attributes
  strip_attributes only: %i[student_email student_name student_surname student_id role]

  # Associations
  belongs_to :cohort
  belongs_to :submission

  # Validations
  validates :student_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :submission_id, uniqueness: true
  validates :student_email, uniqueness: { scope: :cohort_id, case_sensitive: false }
  validates :status, inclusion: { in: %w[waiting in_progress complete] }
  validates :role, inclusion: { in: %w[student sponsor] }

  # Scopes
  # Note: 'active' scope is provided by SoftDeletable concern
  scope :students, -> { where(role: 'student') }
  scope :sponsor, -> { where(role: 'sponsor') }
  scope :waiting, -> { where(status: 'waiting') }
  scope :in_progress, -> { where(status: 'in_progress') }
  scope :complete, -> { where(status: 'complete') }

  # Mark enrollment as complete
  # @return [Boolean] true if successful
  def complete!
    update(status: 'complete', completed_at: Time.current)
  end

  # Mark enrollment as in progress
  # @return [Boolean] true if successful
  def mark_in_progress!
    update(status: 'in_progress')
  end

  # Check if enrollment is waiting
  # @return [Boolean] true if status is waiting
  def waiting?
    status == 'waiting'
  end

  # Check if enrollment is completed
  # @return [Boolean] true if status is complete
  def completed?
    status == 'complete'
  end
end
