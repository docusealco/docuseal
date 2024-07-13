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

ActiveRecord::Schema[7.1].define(version: 2024_07_20_063827) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "access_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "token", null: false
    t.text "sha256", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sha256"], name: "index_access_tokens_on_sha256", unique: true
    t.index ["user_id"], name: "index_access_tokens_on_user_id"
  end

  create_table "account_configs", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "key", null: false
    t.text "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "key"], name: "index_account_configs_on_account_id_and_key", unique: true
    t.index ["account_id"], name: "index_account_configs_on_account_id"
  end

  create_table "account_linked_accounts", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "linked_account_id", null: false
    t.text "account_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "linked_account_id"], name: "idx_on_account_id_linked_account_id_48ab9f79d2", unique: true
    t.index ["account_id"], name: "index_account_linked_accounts_on_account_id"
    t.index ["linked_account_id"], name: "index_account_linked_accounts_on_linked_account_id"
  end

  create_table "accounts", force: :cascade do |t|
    t.string "name", null: false
    t.string "timezone", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
    t.datetime "archived_at"
    t.index ["uuid"], name: "index_accounts_on_uuid", unique: true
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
    t.string "uuid"
    t.index ["checksum"], name: "index_active_storage_blobs_on_checksum"
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
    t.index ["uuid"], name: "index_active_storage_blobs_on_uuid", unique: true
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

  create_table "email_events", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "emailable_type", null: false
    t.bigint "emailable_id", null: false
    t.string "message_id", null: false
    t.string "tag", null: false
    t.string "event_type", null: false
    t.string "email", null: false
    t.text "data", null: false
    t.datetime "event_datetime", null: false
    t.datetime "created_at", null: false
    t.index ["account_id"], name: "index_email_events_on_account_id"
    t.index ["email"], name: "index_email_events_on_email"
    t.index ["emailable_type", "emailable_id"], name: "index_email_events_on_emailable"
    t.index ["message_id"], name: "index_email_events_on_message_id"
  end

  create_table "email_messages", force: :cascade do |t|
    t.string "uuid", null: false
    t.bigint "author_id", null: false
    t.bigint "account_id", null: false
    t.text "subject", null: false
    t.text "body", null: false
    t.string "sha1", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_email_messages_on_account_id"
    t.index ["sha1"], name: "index_email_messages_on_sha1"
    t.index ["uuid"], name: "index_email_messages_on_uuid"
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

  create_table "encrypted_user_configs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "key", null: false
    t.text "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "key"], name: "index_encrypted_user_configs_on_user_id_and_key", unique: true
    t.index ["user_id"], name: "index_encrypted_user_configs_on_user_id"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.string "scopes"
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri"
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "submission_events", force: :cascade do |t|
    t.bigint "submission_id", null: false
    t.bigint "submitter_id"
    t.text "data", null: false
    t.string "event_type", null: false
    t.datetime "event_timestamp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_submission_events_on_created_at"
    t.index ["submission_id"], name: "index_submission_events_on_submission_id"
    t.index ["submitter_id"], name: "index_submission_events_on_submitter_id"
  end

  create_table "submissions", force: :cascade do |t|
    t.bigint "template_id", null: false
    t.bigint "created_by_user_id"
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "template_fields"
    t.text "template_schema"
    t.text "template_submitters"
    t.text "source", null: false
    t.string "submitters_order", null: false
    t.string "slug", null: false
    t.text "preferences", null: false
    t.bigint "account_id", null: false
    t.index ["account_id"], name: "index_submissions_on_account_id"
    t.index ["created_by_user_id"], name: "index_submissions_on_created_by_user_id"
    t.index ["slug"], name: "index_submissions_on_slug", unique: true
    t.index ["template_id"], name: "index_submissions_on_template_id"
  end

  create_table "submitters", force: :cascade do |t|
    t.bigint "submission_id", null: false
    t.string "uuid", null: false
    t.string "email"
    t.string "slug", null: false
    t.text "values", null: false
    t.string "ua"
    t.string "ip"
    t.datetime "sent_at"
    t.datetime "opened_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "phone"
    t.string "external_id"
    t.text "preferences", null: false
    t.text "metadata", null: false
    t.index ["email"], name: "index_submitters_on_email"
    t.index ["external_id"], name: "index_submitters_on_external_id"
    t.index ["slug"], name: "index_submitters_on_slug", unique: true
    t.index ["submission_id"], name: "index_submitters_on_submission_id"
  end

  create_table "template_folders", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "author_id", null: false
    t.bigint "account_id", null: false
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_template_folders_on_account_id"
    t.index ["author_id"], name: "index_template_folders_on_author_id"
  end

  create_table "template_sharings", force: :cascade do |t|
    t.bigint "template_id", null: false
    t.bigint "account_id", null: false
    t.string "ability", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "template_id"], name: "index_template_sharings_on_account_id_and_template_id", unique: true
    t.index ["template_id"], name: "index_template_sharings_on_template_id"
  end

  create_table "templates", force: :cascade do |t|
    t.string "slug", null: false
    t.string "name", null: false
    t.text "schema", null: false
    t.text "fields", null: false
    t.text "submitters", null: false
    t.bigint "author_id", null: false
    t.bigint "account_id", null: false
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "source", null: false
    t.bigint "folder_id", null: false
    t.string "external_id"
    t.text "preferences", null: false
    t.index ["account_id"], name: "index_templates_on_account_id"
    t.index ["author_id"], name: "index_templates_on_author_id"
    t.index ["external_id"], name: "index_templates_on_external_id"
    t.index ["folder_id"], name: "index_templates_on_folder_id"
    t.index ["slug"], name: "index_templates_on_slug", unique: true
  end

  create_table "user_configs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "key", null: false
    t.text "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "key"], name: "index_user_configs_on_user_id_and_key", unique: true
    t.index ["user_id"], name: "index_user_configs_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
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
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "uuid", null: false
    t.string "otp_secret"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login", default: false, null: false
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["uuid"], name: "index_users_on_uuid", unique: true
  end

  create_table "webhook_urls", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.text "url", null: false
    t.text "events", null: false
    t.string "sha1", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_webhook_urls_on_account_id"
    t.index ["sha1"], name: "index_webhook_urls_on_sha1"
  end

  add_foreign_key "access_tokens", "users"
  add_foreign_key "account_configs", "accounts"
  add_foreign_key "account_linked_accounts", "accounts"
  add_foreign_key "account_linked_accounts", "accounts", column: "linked_account_id"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "document_generation_events", "submitters"
  add_foreign_key "email_events", "accounts"
  add_foreign_key "email_messages", "accounts"
  add_foreign_key "email_messages", "users", column: "author_id"
  add_foreign_key "encrypted_configs", "accounts"
  add_foreign_key "encrypted_user_configs", "users"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "users", column: "resource_owner_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "users", column: "resource_owner_id"
  add_foreign_key "submission_events", "submissions"
  add_foreign_key "submission_events", "submitters"
  add_foreign_key "submissions", "templates"
  add_foreign_key "submissions", "users", column: "created_by_user_id"
  add_foreign_key "submitters", "submissions"
  add_foreign_key "template_folders", "accounts"
  add_foreign_key "template_folders", "users", column: "author_id"
  add_foreign_key "template_sharings", "templates"
  add_foreign_key "templates", "accounts"
  add_foreign_key "templates", "template_folders", column: "folder_id"
  add_foreign_key "templates", "users", column: "author_id"
  add_foreign_key "user_configs", "users"
  add_foreign_key "users", "accounts"
  add_foreign_key "webhook_urls", "accounts"
end
