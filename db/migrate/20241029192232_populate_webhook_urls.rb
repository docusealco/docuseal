# frozen_string_literal: true

class PopulateWebhookUrls < ActiveRecord::Migration[7.2]
  disable_ddl_transaction

  class MigrationWebhookUrl < ActiveRecord::Base
    self.table_name = 'webhook_urls'

    serialize :events, coder: JSON
    serialize :secret, coder: JSON

    encrypts :url, :secret
  end

  class MigrationEncryptedConfig < ActiveRecord::Base
    self.table_name = 'encrypted_configs'

    encrypts :value
    serialize :value, coder: JSON
  end

  class MigrationAccountConfig < ActiveRecord::Base
    self.table_name = 'account_configs'

    serialize :value, coder: JSON
  end

  def up
    MigrationEncryptedConfig.where(key: 'webhook_url').find_each do |config|
      webhook_url = MigrationWebhookUrl.find_or_initialize_by(account_id: config.account_id,
                                                              sha1: Digest::SHA1.hexdigest(config.value))

      webhook_url.secret =
        MigrationEncryptedConfig.find_by(account_id: config.account_id, key: 'webhook_secret')&.value.to_h

      preferences =
        MigrationAccountConfig.find_by(account_id: config.account_id, key: 'webhook_preferences')&.value.to_h

      events = %w[form.viewed form.started form.completed form.declined].reject { |event| preferences[event] == false }

      events += preferences.compact_blank.keys

      webhook_url.events = events.uniq
      webhook_url.url = config.value

      webhook_url.save!
    end
  end

  def down
    nil
  end
end
