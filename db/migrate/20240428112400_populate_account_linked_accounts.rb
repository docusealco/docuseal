# frozen_string_literal: true

class PopulateAccountLinkedAccounts < ActiveRecord::Migration[7.1]
  class MigrationAccount < ApplicationRecord
    self.table_name = 'accounts'
  end

  class MigrationAccountLinkedAccount < ApplicationRecord
    self.table_name = 'account_linked_accounts'
  end

  def up
    return if Docuseal.multitenant?

    MigrationAccount.order(:id).each do |account|
      next if account.id == 1
      next if MigrationAccountLinkedAccount.exists?(linked_account_id: account.id)

      MigrationAccountLinkedAccount.create!(account_id: 1,
                                            linked_account_id: account.id,
                                            account_type: :linked)
    end
  end

  def down
    nil
  end
end
