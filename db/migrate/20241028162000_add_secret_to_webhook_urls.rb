# frozen_string_literal: true

class AddSecretToWebhookUrls < ActiveRecord::Migration[7.2]
  class MigrationWebhookUrl < ApplicationRecord
    self.table_name = 'webhook_urls'

    serialize :secret, coder: JSON

    encrypts :url, :secret
  end

  def change
    add_column :webhook_urls, :secret, :text

    MigrationWebhookUrl.all.each do |url|
      url.update_columns(secret: {})
    end

    change_column_null :webhook_urls, :secret, false
  end
end
