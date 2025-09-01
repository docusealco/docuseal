# frozen_string_literal: true

class PopulateExpireLinkConfigs < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  class MigrationAccount < ActiveRecord::Base
    self.table_name = 'accounts'
  end

  class MigrationAccountConfig < ActiveRecord::Base
    self.table_name = 'account_configs'

    serialize :value, coder: JSON
  end

  def up
    MigrationAccount.find_each do |account|
      config = MigrationAccountConfig.find_or_initialize_by(key: 'download_links_expire', account_id: account.id)

      next if config.persisted?

      config.value = false
      config.save!
    end
  end

  def down
    nil
  end
end
