# frozen_string_literal: true

# == Schema Information
#
# Table name: templates
#
#  id          :bigint           not null, primary key
#  archived_at :datetime
#  fields      :text             not null
#  name        :string           not null
#  preferences :text             not null
#  schema      :text             not null
#  slug        :string           not null
#  source      :text             not null
#  submitters  :text             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#  author_id   :bigint           not null
#  external_id :string
#  folder_id   :bigint           not null
#
# Indexes
#
#  index_templates_on_account_id   (account_id)
#  index_templates_on_author_id    (author_id)
#  index_templates_on_external_id  (external_id)
#  index_templates_on_folder_id    (folder_id)
#  index_templates_on_slug         (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (author_id => users.id)
#  fk_rails_...  (folder_id => template_folders.id)
#
class Template < ApplicationRecord
  DEFAULT_SUBMITTER_NAME = 'First Party'

  belongs_to :author, class_name: 'User'
  belongs_to :account
  belongs_to :folder, class_name: 'TemplateFolder'

  before_validation :maybe_set_default_folder, on: :create

  attribute :preferences, :string, default: -> { {} }
  attribute :fields, :string, default: -> { [] }
  attribute :schema, :string, default: -> { [] }
  attribute :submitters, :string, default: -> { [{ name: DEFAULT_SUBMITTER_NAME, uuid: SecureRandom.uuid }] }
  attribute :slug, :string, default: -> { SecureRandom.base58(14) }
  attribute :source, :string, default: 'native'

  serialize :preferences, coder: JSON
  serialize :fields, coder: JSON
  serialize :schema, coder: JSON
  serialize :submitters, coder: JSON

  has_many_attached :documents

  has_many :schema_documents, ->(e) { where(uuid: e.schema.pluck('attachment_uuid')) },
           class_name: 'ActiveStorage::Attachment', dependent: :destroy, as: :record, inverse_of: :record

  has_many :submissions, dependent: :destroy
  has_many :template_sharings, dependent: :destroy

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  delegate :name, to: :folder, prefix: true

  def application_key
    external_id
  end

  private

  def maybe_set_default_folder
    self.folder ||= account.default_template_folder
  end
end
