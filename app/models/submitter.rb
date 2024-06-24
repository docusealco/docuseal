# frozen_string_literal: true

# == Schema Information
#
# Table name: submitters
#
#  id            :bigint           not null, primary key
#  completed_at  :datetime
#  email         :string
#  ip            :string
#  metadata      :text             not null
#  name          :string
#  opened_at     :datetime
#  phone         :string
#  preferences   :text             not null
#  sent_at       :datetime
#  slug          :string           not null
#  ua            :string
#  uuid          :string           not null
#  values        :text             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  external_id   :string
#  submission_id :bigint           not null
#
# Indexes
#
#  index_submitters_on_email          (email)
#  index_submitters_on_external_id    (external_id)
#  index_submitters_on_slug           (slug) UNIQUE
#  index_submitters_on_submission_id  (submission_id)
#
# Foreign Keys
#
#  fk_rails_...  (submission_id => submissions.id)
#
class Submitter < ApplicationRecord
  belongs_to :submission
  has_one :template, through: :submission
  has_one :account, through: :submission

  attribute :values, :string, default: -> { {} }
  attribute :preferences, :string, default: -> { {} }
  attribute :metadata, :string, default: -> { {} }
  attribute :slug, :string, default: -> { SecureRandom.base58(14) }

  serialize :values, coder: JSON
  serialize :preferences, coder: JSON
  serialize :metadata, coder: JSON

  has_many_attached :documents
  has_many_attached :attachments

  has_many :document_generation_events, dependent: :destroy
  has_many :submission_events, dependent: :destroy

  scope :completed, -> { where.not(completed_at: nil) }

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

  def application_key
    external_id
  end

  def friendly_name
    if name.present? && email.present? && email.exclude?(',')
      %("#{name.delete('"')}" <#{email}>)
    else
      email
    end
  end

  def status_event_at
    completed_at || opened_at || sent_at || created_at
  end
end
