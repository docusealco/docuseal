# frozen_string_literal: true

class AddSubmittersTemplateIdIndexes < ActiveRecord::Migration[8.1]
  def up
    add_index :submitters, %i[email template_id], where: 'email IS NOT NULL', if_not_exists: true
    add_index :submitters, %i[template_id id], if_not_exists: true
    remove_index :submitters, :email, if_exists: true
  end

  def down
    add_index :submitters, :email, if_not_exists: true
    remove_index :submitters, %i[template_id id], if_exists: true
    remove_index :submitters, %i[email template_id], if_exists: true
  end
end
