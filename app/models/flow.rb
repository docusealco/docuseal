# frozen_string_literal: true

# == Schema Information
#
# Table name: flows
#
#  id         :bigint           not null, primary key
#  deleted_at :datetime
#  fields     :string           not null
#  name       :string           not null
#  schema     :string           not null
#  slug       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  author_id  :bigint           not null
#
# Indexes
#
#  index_flows_on_account_id  (account_id)
#  index_flows_on_author_id   (author_id)
#  index_flows_on_slug        (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (author_id => users.id)
#
class Flow < ApplicationRecord
  belongs_to :author, class_name: 'User'
  belongs_to :account

  attribute :fields, :string, default: -> { [] }
  attribute :schema, :string, default: -> { [] }
  attribute :slug, :string, default: -> { SecureRandom.base58(8) }

  serialize :fields, JSON
  serialize :schema, JSON

  has_many_attached :documents

  has_many :submissions, dependent: :destroy

  scope :active, -> { where(deleted_at: nil) }
end
