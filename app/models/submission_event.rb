# frozen_string_literal: true

# == Schema Information
#
# Table name: submission_events
#
#  id              :bigint           not null, primary key
#  data            :text             not null
#  event_timestamp :datetime         not null
#  event_type      :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  submission_id   :bigint           not null
#  submitter_id    :bigint
#
# Indexes
#
#  index_submission_events_on_created_at     (created_at)
#  index_submission_events_on_submission_id  (submission_id)
#  index_submission_events_on_submitter_id   (submitter_id)
#
# Foreign Keys
#
#  fk_rails_...  (submission_id => submissions.id)
#  fk_rails_...  (submitter_id => submitters.id)
#
class SubmissionEvent < ApplicationRecord
  belongs_to :submission
  has_one :account, through: :submission
  belongs_to :submitter, optional: true

  attribute :data, :string, default: -> { {} }
  attribute :event_timestamp, :datetime, default: -> { Time.current }

  serialize :data, coder: JSON

  before_validation :set_submission_id, on: :create

  enum :event_type, {
    send_email: 'send_email',
    send_reminder_email: 'send_reminder_email',
    send_sms: 'send_sms',
    send_2fa_sms: 'send_2fa_sms',
    open_email: 'open_email',
    click_email: 'click_email',
    click_sms: 'click_sms',
    phone_verified: 'phone_verified',
    start_form: 'start_form',
    view_form: 'view_form',
    complete_form: 'complete_form',
    api_complete_form: 'api_complete_form'
  }, scope: false

  private

  def set_submission_id
    self.submission_id = submitter&.submission_id
  end
end
