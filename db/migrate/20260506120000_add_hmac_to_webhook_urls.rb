# frozen_string_literal: true

class AddHmacToWebhookUrls < ActiveRecord::Migration[8.1]
  class MigrationWebhookUrl < ApplicationRecord
    self.table_name = 'webhook_urls'

    encrypts :hmac_secret
  end

  def up
    add_column :webhook_urls, :hmac_secret, :text

    MigrationWebhookUrl.find_each do |webhook_url|
      webhook_url.update_columns(hmac_secret: WebhookUrls::Signatures.generate_secret)
    end

    change_column_null :webhook_urls, :hmac_secret, false
  end

  def down
    remove_column :webhook_urls, :hmac_secret
  end
end
