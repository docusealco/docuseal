# frozen_string_literal: true

class AddPhoneAndNameToSubmitters < ActiveRecord::Migration[7.0]
  def change
    change_table :submitters, bulk: true do |t|
      t.string :name
      t.string :phone
      t.change_null :email, true
    end
  end
end
