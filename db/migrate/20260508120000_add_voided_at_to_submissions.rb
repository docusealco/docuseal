# frozen_string_literal: true

class AddVoidedAtToSubmissions < ActiveRecord::Migration[8.1]
  def change
    add_column :submissions, :voided_at, :datetime

    add_index :submissions,
              %i[account_id template_id id],
              where: 'voided_at IS NOT NULL',
              name: :index_submissions_on_account_id_and_template_id_and_id_voided
  end
end
