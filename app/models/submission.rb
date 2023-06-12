# frozen_string_literal: true

# == Schema Information
#
# Table name: submissions
#
#  id          :bigint           not null, primary key
#  deleted_at  :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  template_id :bigint           not null
#
# Indexes
#
#  index_submissions_on_template_id  (template_id)
#
# Foreign Keys
#
#  fk_rails_...  (template_id => templates.id)
#
class Submission < ApplicationRecord
  belongs_to :template

  has_many :submitters, dependent: :destroy

  scope :active, -> { where(deleted_at: nil) }
end
