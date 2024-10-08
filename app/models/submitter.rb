# frozen_string_literal: true

# == Schema Information
#
# Table name: submitters
#
#  id            :bigint           not null, primary key
#  completed_at  :datetime
#  declined_at   :datetime
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
#  account_id    :bigint           not null
#  external_id   :string
#  submission_id :bigint           not null
#
# Indexes
#
#  index_submitters_on_account_id_and_id  (account_id,id)
#  index_submitters_on_email              (email)
#  index_submitters_on_external_id        (external_id)
#  index_submitters_on_slug               (slug) UNIQUE
#  index_submitters_on_submission_id      (submission_id)
#
# Foreign Keys
#
#  fk_rails_...  (submission_id => submissions.id)
#
class Submitter < ApplicationRecord
  belongs_to :submission
  belongs_to :account
  has_one :template, through: :submission

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
  has_many :start_form_submission_events, -> { where(event_type: :start_form) },
           class_name: 'SubmissionEvent', dependent: :destroy, inverse_of: :submitter

  scope :completed, -> { where.not(completed_at: nil) }

  def status
    if declined_at?
      'declined'
    elsif completed_at?
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

  def first_name
    name&.split(/\s+/, 2)&.first
  end

  def last_name
    name&.split(/\s+/, 2)&.last
  end

  def status_event_at
    declined_at || completed_at || opened_at || sent_at || created_at
  end

  def with_signature_fields?
    @with_signature_fields ||= begin
      fields = submission.template_fields || template.fields
      signature_field_types = %w[signature initials]
      fields.any? { |f| f['submitter_uuid'] == uuid && signature_field_types.include?(f['type']) }
    end
  end
end
