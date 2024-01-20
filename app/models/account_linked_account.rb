# frozen_string_literal: true

# == Schema Information
#
# Table name: account_linked_accounts
#
#  id                :bigint           not null, primary key
#  account_type      :text             not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  linked_account_id :bigint           not null
#
# Indexes
#
#  idx_on_account_id_linked_account_id_48ab9f79d2      (account_id,linked_account_id) UNIQUE
#  index_account_linked_accounts_on_account_id         (account_id)
#  index_account_linked_accounts_on_linked_account_id  (linked_account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (linked_account_id => accounts.id)
#
class AccountLinkedAccount < ApplicationRecord
  belongs_to :account
  belongs_to :linked_account, class_name: 'Account'

  attribute :account_type, :string, default: 'testing'

  scope :testing, -> { where(account_type: :testing) }

  def testing?
    account_type == 'testing'
  end
end
