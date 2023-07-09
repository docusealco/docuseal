# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_07_01_075115) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "name", null: false
    t.string "timezone", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "uuid", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
    t.index ["uuid"], name: "index_active_storage_attachments_on_uuid"
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "document_generation_events", force: :cascade do |t|
    t.bigint "submitter_id", null: false
    t.string "event_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["submitter_id", "event_name"], name: "index_document_generation_events_on_submitter_id_and_event_name", unique: true, where: "((event_name)::text = ANY ((ARRAY['start'::character varying, 'complete'::character varying])::text[]))"
    t.index ["submitter_id"], name: "index_document_generation_events_on_submitter_id"
  end

  create_table "encrypted_configs", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "key", null: false
    t.text "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "key"], name: "index_encrypted_configs_on_account_id_and_key", unique: true
    t.index ["account_id"], name: "index_encrypted_configs_on_account_id"
  end

  create_table "submissions", force: :cascade do |t|
    t.bigint "template_id", null: false
    t.bigint "created_by_user_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_user_id"], name: "index_submissions_on_created_by_user_id"
    t.index ["template_id"], name: "index_submissions_on_template_id"
  end

  create_table "submitters", force: :cascade do |t|
    t.bigint "submission_id", null: false
    t.string "uuid", null: false
    t.string "email", null: false
    t.string "slug", null: false
    t.text "values", null: false
    t.string "ua"
    t.string "ip"
    t.datetime "sent_at"
    t.datetime "opened_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_submitters_on_email"
    t.index ["slug"], name: "index_submitters_on_slug", unique: true
    t.index ["submission_id"], name: "index_submitters_on_submission_id"
  end

  create_table "templates", force: :cascade do |t|
    t.string "slug", null: false
    t.string "name", null: false
    t.text "schema", null: false
    t.text "fields", null: false
    t.text "submitters", null: false
    t.bigint "author_id", null: false
    t.bigint "account_id", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_templates_on_account_id"
    t.index ["author_id"], name: "index_templates_on_author_id"
    t.index ["slug"], name: "index_templates_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.string "role", null: false
    t.string "encrypted_password", null: false
    t.bigint "account_id", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "document_generation_events", "submitters"
  add_foreign_key "encrypted_configs", "accounts"
  add_foreign_key "submissions", "templates"
  add_foreign_key "submissions", "users", column: "created_by_user_id"
  add_foreign_key "submitters", "submissions"
  add_foreign_key "templates", "accounts"
  add_foreign_key "templates", "users", column: "author_id"
  add_foreign_key "users", "accounts"
end
