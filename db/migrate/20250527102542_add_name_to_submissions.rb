# frozen_string_literal: true

class AddNameToSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :submissions, :name, :text
  end
end
