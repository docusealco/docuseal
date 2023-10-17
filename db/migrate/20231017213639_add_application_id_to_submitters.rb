# frozen_string_literal: true

class AddApplicationIdToSubmitters < ActiveRecord::Migration[7.0]
  def change
    add_column :submitters, :application_key, :string
  end
end
