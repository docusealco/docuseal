# frozen_string_literal: true

class RemoveUserFirstLastNameNotNull < ActiveRecord::Migration[7.0]
  def change
    change_table :users, bulk: true do |t|
      t.change_null :first_name, true
      t.change_null :last_name, true
    end
  end
end
