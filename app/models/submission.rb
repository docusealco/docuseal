# frozen_string_literal: true

# == Schema Information
#
# Table name: submissions
#
#  id           :bigint           not null, primary key
#  completed_at :datetime
#  deleted_at   :datetime
#  email        :string           not null
#  ip           :string
#  opened_at    :datetime
#  sent_at      :datetime
#  slug         :string           not null
#  ua           :string
#  values       :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  template_id  :bigint           not null
#
# Indexes
#
#  index_submissions_on_email        (email)
#  index_submissions_on_slug         (slug) UNIQUE
#  index_submissions_on_template_id  (template_id)
#
# Foreign Keys
#
#  fk_rails_...  (template_id => templates.id)
#
class Submission < ApplicationRecord
  belongs_to :template

  attribute :values, :string, default: -> { {} }
  attribute :slug, :string, default: -> { SecureRandom.base58(8) }

  serialize :values, JSON

  has_one_attached :archive
  has_many_attached :documents

  has_many_attached :attachments

  scope :active, -> { where(deleted_at: nil) }

  def status
    if completed_at?
      'completed'
    elsif opened_at?
      'opened'
    elsif sent_at?
      'sent'
    else
      'awaiting'
    end
  end
end
