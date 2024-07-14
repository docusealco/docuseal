# frozen_string_literal: true

# == Schema Information
#
# Table name: accounts
#
#  id          :bigint           not null, primary key
#  archived_at :datetime
#  locale      :string           not null
#  name        :string           not null
#  timezone    :string           not null
#  uuid        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_accounts_on_uuid  (uuid) UNIQUE
#
class Account < ApplicationRecord
  attribute :uuid, :string, default: -> { SecureRandom.uuid }

  has_many :users, dependent: :destroy
  has_many :encrypted_configs, dependent: :destroy
  has_many :account_configs, dependent: :destroy
  has_many :email_messages, dependent: :destroy
  has_many :templates, dependent: :destroy
  has_many :template_folders, dependent: :destroy
  has_one :default_template_folder, -> { where(name: TemplateFolder::DEFAULT_NAME) },
          class_name: 'TemplateFolder', dependent: :destroy, inverse_of: :account
  has_many :submissions, dependent: :destroy
  has_many :submitters, through: :submissions
  has_many :account_linked_accounts, dependent: :destroy
  has_many :email_events, dependent: :destroy
  has_many :webhook_urls, dependent: :destroy
  has_many :account_testing_accounts, -> { testing }, dependent: :destroy,
                                                      class_name: 'AccountLinkedAccount',
                                                      inverse_of: :account
  has_one :linked_account_account, dependent: :destroy,
                                   foreign_key: :linked_account_id,
                                   class_name: 'AccountLinkedAccount',
                                   inverse_of: :linked_account
  has_many :linked_account_accounts, dependent: :destroy,
                                     foreign_key: :linked_account_id,
                                     class_name: 'AccountLinkedAccount',
                                     inverse_of: :linked_account
  has_many :linked_accounts, through: :account_linked_accounts
  has_many :testing_accounts, through: :account_testing_accounts, source: :linked_account
  has_many :active_users, -> { active }, dependent: :destroy,
                                         inverse_of: :account, class_name: 'User'

  attribute :timezone, :string, default: 'UTC'
  attribute :locale, :string, default: 'en-US'

  scope :active, -> { where(archived_at: nil) }

  def testing?
    linked_account_account&.testing?
  end

  def default_template_folder
    super || build_default_template_folder(name: TemplateFolder::DEFAULT_NAME,
                                           author_id: users.minimum(:id)).tap(&:save!)
  end
end
