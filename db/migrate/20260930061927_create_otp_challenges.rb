# frozen_string_literal: true

class CreateOtpChallenges < ActiveRecord::Migration[8.1]
  def change
    create_table :otp_challenges do |t|
      t.string :key, null: false
      t.integer :version, null: false
      t.string :nonce, null: false
      t.integer :attempts, null: false, default: 0
      t.datetime :expire_at, null: false
      t.datetime :verified_at
      t.datetime :created_at, null: false

      t.index %i[key version], unique: true
    end
  end
end
