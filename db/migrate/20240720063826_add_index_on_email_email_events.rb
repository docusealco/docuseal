# frozen_string_literal: true

class AddIndexOnEmailEmailEvents < ActiveRecord::Migration[7.1]
  def change
    add_index :email_events, :email
  end
end
