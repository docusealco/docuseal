# frozen_string_literal: true

# == Schema Information
#
# Table name: webhook_urls
#
#  id             :bigint           not null, primary key
#  events         :text             not null
#  secret         :text             not null
#  sha1           :string           not null
#  url            :text             not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :integer
#  partnership_id :bigint
#
# Indexes
#
#  index_webhook_urls_on_account_id      (account_id)
#  index_webhook_urls_on_partnership_id  (partnership_id)
#  index_webhook_urls_on_sha1            (sha1)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (partnership_id => partnerships.id)
#
class WebhookUrl < ApplicationRecord
  EVENTS = %w[
    form.viewed
    form.started
    form.completed
    form.declined
    form.changes_requested
    submission.created
    submission.completed
    submission.expired
    submission.archived
    template.created
    template.updated
    template.preferences_updated
  ].freeze

  # Partnership webhooks can only use template events since partnerships don't have submissions/submitters
  PARTNERSHIP_EVENTS = %w[
    template.preferences_updated
  ].freeze

  belongs_to :account, optional: true
  belongs_to :partnership, optional: true

  attribute :events, :string, default: -> { %w[form.viewed form.started form.completed form.declined] }
  attribute :secret, :string, default: -> { {} }

  serialize :events, coder: JSON
  serialize :secret, coder: JSON

  before_validation :set_sha1
  validate :validate_owner_presence

  encrypts :url, :secret

  def set_sha1
    self.sha1 = Digest::SHA1.hexdigest(url)
  end

  private

  def validate_owner_presence
    return if account_id.present? ^ partnership_id.present?

    errors.add(:base, 'Must have either account_id or partnership_id, but not both')
  end
end
