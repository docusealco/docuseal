class AddChangesRequestedAtToSubmitters < ActiveRecord::Migration[8.0]
  def change
    add_column :submitters, :changes_requested_at, :datetime
  end
end
