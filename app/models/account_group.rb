# frozen_string_literal: true

# == Schema Information
#
# Table name: account_groups
#
#  id                        :bigint           not null, primary key
#  name                      :string           not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  external_account_group_id :integer          not null
#
# Indexes
#
#  index_account_groups_on_external_account_group_id  (external_account_group_id) UNIQUE
#
class AccountGroup < ApplicationRecord
  has_many :accounts, dependent: :nullify
  has_many :users, dependent: :nullify
  has_many :templates, dependent: :destroy
  has_many :template_folders, dependent: :destroy

  validates :external_account_group_id, presence: true, uniqueness: true
  validates :name, presence: true

  def self.find_or_create_by_external_id(external_id, attributes = {})
    find_by(external_account_group_id: external_id) ||
      create!(attributes.merge(external_account_group_id: external_id))
  end

  def default_template_folder
    template_folders.find_by(name: TemplateFolder::DEFAULT_NAME) ||
      template_folders.create!(name: TemplateFolder::DEFAULT_NAME,
                               author_id: users.minimum(:id))
  end
end
