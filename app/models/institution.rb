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
  # Layer 1: Foundation relationships (FloDoc - standalone institutions)
  has_many :cohorts, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 255 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

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
