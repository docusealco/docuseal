# frozen_string_literal: true

# == Schema Information
#
# Table name: template_folders
#
#  id               :bigint           not null, primary key
#  archived_at      :datetime
#  name             :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  author_id        :bigint           not null
#  parent_folder_id :bigint
#
# Indexes
#
#  index_template_folders_on_account_id        (account_id)
#  index_template_folders_on_author_id         (author_id)
#  index_template_folders_on_parent_folder_id  (parent_folder_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (author_id => users.id)
#  fk_rails_...  (parent_folder_id => template_folders.id)
#
class TemplateFolder < ApplicationRecord
  DEFAULT_NAME = 'Default'

  belongs_to :author, class_name: 'User'
  belongs_to :account
  belongs_to :parent_folder, class_name: 'TemplateFolder', optional: true

  has_many :templates, dependent: :destroy, foreign_key: :folder_id, inverse_of: :folder
  has_many :subfolders, class_name: 'TemplateFolder', foreign_key: :parent_folder_id, inverse_of: :parent_folder,
                        dependent: :destroy
  has_many :active_templates, -> { where(archived_at: nil) },
           class_name: 'Template', dependent: :destroy, foreign_key: :folder_id, inverse_of: :folder

  scope :active, -> { where(archived_at: nil) }

  def full_name
    if parent_folder_id?
      [parent_folder.name, name].join(' / ')
    else
      name
    end
  end

  def default?
    name == DEFAULT_NAME
  end
end
