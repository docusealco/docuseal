# frozen_string_literal: true

class AddExpireAtToSubmissions < ActiveRecord::Migration[7.1]
  def change
    add_column :submissions, :expire_at, :datetime
  end
end
