# frozen_string_literal: true

class AddPhoneAndNameToSubmitters < ActiveRecord::Migration[7.0]
  def change
    add_column :submitters, :name, :string
    add_column :submitters, :phone, :string

    change_column_null :submitters, :email, true
  end
end
