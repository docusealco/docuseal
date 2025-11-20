# frozen_string_literal: true

# == Schema Information
#
# Table name: account_accesses
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_account_accesses_on_account_id_and_user_id  (account_id,user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class AccountAccess < ApplicationRecord
  belongs_to :account
  belongs_to :user
end
