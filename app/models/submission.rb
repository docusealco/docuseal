# frozen_string_literal: true

# == Schema Information
#
# Table name: submissions
#
#  id                  :bigint           not null, primary key
#  deleted_at          :datetime
#  source              :text             not null
#  submitters_order    :string           not null
#  template_fields     :text
#  template_schema     :text
#  template_submitters :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  created_by_user_id  :bigint
#  template_id         :bigint           not null
#
# Indexes
#
#  index_submissions_on_created_by_user_id  (created_by_user_id)
#  index_submissions_on_template_id         (template_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_user_id => users.id)
#  fk_rails_...  (template_id => templates.id)
#
class Submission < ApplicationRecord
  belongs_to :template
  has_one :account, through: :template
  belongs_to :created_by_user, class_name: 'User', optional: true

  has_many :submitters, dependent: :destroy
  has_many :submission_events, dependent: :destroy

  serialize :template_fields, JSON
  serialize :template_schema, JSON
  serialize :template_submitters, JSON

  attribute :source, :string, default: 'link'
  attribute :submitters_order, :string, default: 'random'

  has_one_attached :audit_trail

  has_many :template_schema_documents,
           ->(e) { where(uuid: (e.template_schema.presence || e.template.schema).pluck('attachment_uuid')) },
           through: :template, source: :documents_attachments

  scope :active, -> { where(deleted_at: nil) }
  scope :pending, -> { joins(:submitters).where(submitters: { completed_at: nil }).distinct }
  scope :completed, -> { left_joins(:submitters).where.not(submitters: { completed_at: nil }).distinct }

  enum :source, {
    invite: 'invite',
    api: 'api',
    embed: 'embed',
    link: 'link'
  }, scope: false, prefix: true

  enum :submitters_order, {
    random: 'random',
    preserved: 'preserved'
  }, scope: false, prefix: true
end
