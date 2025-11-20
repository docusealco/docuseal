# frozen_string_literal: true

class AddTimezoneToSubmitters < ActiveRecord::Migration[8.0]
  def change
    add_column :submitters, :timezone, :string
  end
end
