# frozen_string_literal: true

class CreateDocumentGenerationEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :document_generation_events do |t|
      t.references :submitter, null: false, foreign_key: true, index: true
      t.string :event_name, null: false

      t.index %i[submitter_id event_name], unique: true, where: "event_name IN ('start', 'complete')"

      t.timestamps
    end
  end
end
