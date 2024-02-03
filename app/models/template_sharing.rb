# frozen_string_literal: true

# == Schema Information
#
# Table name: template_sharings
#
#  id          :bigint           not null, primary key
#  ability     :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#  template_id :bigint           not null
#
# Indexes
#
#  index_template_sharings_on_account_id_and_template_id  (account_id,template_id) UNIQUE
#  index_template_sharings_on_template_id                 (template_id)
#
# Foreign Keys
#
#  fk_rails_...  (template_id => templates.id)
#
class TemplateSharing < ApplicationRecord
  ALL_ID = -1

  belongs_to :template
  belongs_to :account, optional: true
end
