# frozen_string_literal: true

class AddIndexOnExternalId < ActiveRecord::Migration[7.1]
  def change
    add_index :submitters, :external_id
    add_index :templates, :external_id
  end
end
