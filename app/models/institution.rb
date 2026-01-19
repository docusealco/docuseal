# frozen_string_literal: true

# == Schema Information
#
# Table name: institutions
#
#  id             :bigint           not null, primary key
#  contact_person :string
#  deleted_at     :datetime
#  email          :string           not null
#  name           :string           not null
#  phone          :string
#  settings       :jsonb
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Institution < ApplicationRecord
  include SoftDeletable

  # Strip whitespace from string attributes
  strip_attributes only: %i[name email contact_person phone]

  # Associations
  has_many :cohorts, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 255 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  # Scopes
  # Note: 'active' scope is provided by SoftDeletable concern

  # Single-record pattern: Get the current institution
  # @return [Institution, nil] the first institution record
  def self.current
    first
  end

  # Settings accessor with defaults
  # @return [ActiveSupport::HashWithIndifferentAccess] settings with defaults applied
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
