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
#  flow_id      :bigint           not null
#
# Indexes
#
#  index_submissions_on_email    (email)
#  index_submissions_on_flow_id  (flow_id)
#  index_submissions_on_slug     (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (flow_id => flows.id)
#
class Submission < ApplicationRecord
  belongs_to :flow

  attribute :values, :string, default: -> { {} }
  attribute :slug, :string, default: -> { SecureRandom.base58(8) }

  serialize :values, JSON

  has_one_attached :archive
  has_many_attached :documents

  has_many_attached :attachments
  has_many_attached :images
  has_many_attached :signatures

  scope :active, -> { where(deleted_at: nil) }
end
