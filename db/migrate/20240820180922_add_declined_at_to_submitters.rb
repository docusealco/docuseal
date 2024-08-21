# frozen_string_literal: true

class AddDeclinedAtToSubmitters < ActiveRecord::Migration[7.1]
  def change
    add_column :submitters, :declined_at, :datetime
  end
end
