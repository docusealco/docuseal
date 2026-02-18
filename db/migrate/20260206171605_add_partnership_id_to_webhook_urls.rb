class AddPartnershipIdToWebhookUrls < ActiveRecord::Migration[8.0]
  def change
    # Make account_id nullable since webhooks can now belong to either account or partnership
    change_column_null :webhook_urls, :account_id, true

    # Add partnership_id as optional reference
    add_reference :webhook_urls, :partnership, null: true, foreign_key: true

    # Add check constraint to ensure exactly one of account_id or partnership_id is set
    add_check_constraint :webhook_urls,
                         '(account_id IS NOT NULL AND partnership_id IS NULL) OR (account_id IS NULL AND partnership_id IS NOT NULL)',
                         name: 'webhook_urls_owner_check'
  end
end
