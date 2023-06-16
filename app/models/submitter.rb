# frozen_string_literal: true

# == Schema Information
#
# Table name: submitters
#
#  id            :bigint           not null, primary key
#  completed_at  :datetime
#  email         :string           not null
#  ip            :string
#  opened_at     :datetime
#  sent_at       :datetime
#  slug          :string           not null
#  ua            :string
#  uuid          :string           not null
#  values        :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  submission_id :bigint           not null
#
# Indexes
#
#  index_submitters_on_email          (email)
#  index_submitters_on_slug           (slug) UNIQUE
#  index_submitters_on_submission_id  (submission_id)
#
# Foreign Keys
#
#  fk_rails_...  (submission_id => submissions.id)
#
class Submitter < ApplicationRecord
  belongs_to :submission

  attribute :values, :string, default: -> { {} }
  attribute :slug, :string, default: -> { SecureRandom.base58(8) }

  serialize :values, JSON

  has_many_attached :documents
  has_many_attached :attachments

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
