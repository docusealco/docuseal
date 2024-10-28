# frozen_string_literal: true

class AddSecretToWebhookUrls < ActiveRecord::Migration[7.2]
  def change
    add_column :webhook_urls, :secret, :text
  end
end
