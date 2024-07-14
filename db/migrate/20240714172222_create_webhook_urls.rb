# frozen_string_literal: true

class CreateWebhookUrls < ActiveRecord::Migration[7.1]
  def change
    create_table :webhook_urls do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.text :url, null: false
      t.text :events, null: false
      t.string :sha1, null: false, index: true

      t.timestamps
    end
  end
end
