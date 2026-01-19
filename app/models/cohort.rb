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
  include SoftDeletable
  include AASM

  # Strip whitespace from string attributes
  strip_attributes only: %i[name program_type sponsor_email]

  # Associations
  belongs_to :institution
  belongs_to :template
  has_many :cohort_enrollments, dependent: :destroy
  has_many :submissions, through: :cohort_enrollments

  # Validations
  validates :name, presence: true
  validates :program_type, presence: true, inclusion: { in: %w[learnership internship candidacy] }
  validates :sponsor_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, inclusion: { in: %w[draft active completed] }

  # Scopes
  # Note: 'active' scope is provided by SoftDeletable concern
  scope :draft, -> { where(status: 'draft') }
  scope :active_status, -> { where(status: 'active') }
  scope :completed, -> { where(status: 'completed') }
  scope :ready_for_sponsor, -> { where(status: 'active').where.not(students_completed_at: nil) }

  # State Machine (Basic 3-state version for Story 1.2)
  # Enhanced 7-state machine will be implemented in Story 2.2
  aasm column: :status do
    state :draft, initial: true
    state :active
    state :completed

    # Transition from draft to active (TP signs)
    event :activate do
      transitions from: :draft, to: :active, after: :mark_tp_signed
    end

    # Transition from active to completed (all phases done)
    event :complete do
      transitions from: :active, to: :completed, after: :mark_finalized
    end
  end

  # Check if all students have completed their submissions
  # @return [Boolean] true if all student enrollments are completed
  def all_students_completed?
    return false if cohort_enrollments.students.empty?

    cohort_enrollments.students.all?(&:completed?)
  end

  # Check if sponsor access is ready (TP signed and students completed)
  # @return [Boolean] true if ready for sponsor review
  def sponsor_access_ready?
    active? && tp_signed_at.present? && all_students_completed?
  end

  # Check if TP can sign (cohort is in draft state)
  # @return [Boolean] true if TP can sign
  def tp_can_sign?
    draft?
  end

  private

  # Callback: Mark TP signing timestamp
  def mark_tp_signed
    update_column(:tp_signed_at, Time.current)
  end

  # Callback: Mark finalization timestamp
  def mark_finalized
    update_column(:finalized_at, Time.current)
  end
end
