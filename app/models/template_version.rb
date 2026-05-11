# frozen_string_literal: true

# == Schema Information
#
# Table name: template_versions
#
#  id          :bigint           not null, primary key
#  data        :text             not null
#  sha1        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#  author_id   :bigint           not null
#  template_id :bigint           not null
#
# Indexes
#
#  index_template_versions_on_account_id            (account_id)
#  index_template_versions_on_author_id             (author_id)
#  index_template_versions_on_template_id_and_sha1  (template_id,sha1) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (author_id => users.id)
#  fk_rails_...  (template_id => templates.id)
#
class TemplateVersion < ApplicationRecord
  belongs_to :template
  belongs_to :account
  belongs_to :author, class_name: 'User'

  attribute :data, :string, default: -> { {} }

  serialize :data, coder: JSON

  before_validation :set_account, on: :create

  private

  def set_account
    self.account ||= template.account
  end
end
