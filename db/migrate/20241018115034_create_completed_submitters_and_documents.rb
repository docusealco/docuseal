# frozen_string_literal: true

class CreateCompletedSubmittersAndDocuments < ActiveRecord::Migration[7.2]
  def change
    create_table :completed_submitters do |t|
      t.bigint :submitter_id, null: false, index: true
      t.bigint :submission_id, null: false
      t.bigint :account_id, null: false, index: true
      t.bigint :template_id, null: false
      t.string :source, null: false
      t.integer :sms_count, null: false
      t.datetime :completed_at, null: false

      t.timestamps
    end

    create_table :completed_documents do |t|
      t.bigint :submitter_id, null: false, index: true
      t.string :sha256, null: false, index: true

      t.timestamps
    end
  end
end
