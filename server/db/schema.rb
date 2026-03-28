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

ActiveRecord::Schema[8.1].define(version: 2026_03_28_212542) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "conversations", force: :cascade do |t|
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.integer "initiator_id", null: false
    t.integer "recipient_id", null: false
    t.integer "status", default: 0, null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
    t.index ["initiator_id", "status"], name: "index_conversations_on_initiator_id_and_status"
    t.index ["initiator_id"], name: "index_conversations_on_initiator_id"
    t.index ["recipient_id", "status"], name: "index_conversations_on_recipient_id_and_status"
    t.index ["recipient_id"], name: "index_conversations_on_recipient_id"
  end

  create_table "llm_context_messages", force: :cascade do |t|
    t.integer "cache_creation_tokens"
    t.integer "cached_tokens"
    t.text "content"
    t.json "content_raw"
    t.datetime "created_at", null: false
    t.integer "input_tokens"
    t.integer "llm_context_id", null: false
    t.integer "llm_context_tool_call_id"
    t.integer "llm_model_id"
    t.integer "output_tokens"
    t.string "role", null: false
    t.text "thinking_signature"
    t.text "thinking_text"
    t.integer "thinking_tokens"
    t.datetime "updated_at", null: false
    t.index ["llm_context_id"], name: "index_llm_context_messages_on_llm_context_id"
    t.index ["llm_context_tool_call_id"], name: "index_llm_context_messages_on_llm_context_tool_call_id"
    t.index ["llm_model_id"], name: "index_llm_context_messages_on_llm_model_id"
    t.index ["role"], name: "index_llm_context_messages_on_role"
  end

  create_table "llm_context_tool_calls", force: :cascade do |t|
    t.json "arguments", default: {}
    t.datetime "created_at", null: false
    t.integer "llm_context_message_id", null: false
    t.string "name", null: false
    t.text "thought_signature"
    t.string "tool_call_id", null: false
    t.datetime "updated_at", null: false
    t.index ["llm_context_message_id"], name: "index_llm_context_tool_calls_on_llm_context_message_id"
    t.index ["name"], name: "index_llm_context_tool_calls_on_name"
    t.index ["tool_call_id"], name: "index_llm_context_tool_calls_on_tool_call_id", unique: true
  end

  create_table "llm_contexts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "llm_model_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["llm_model_id"], name: "index_llm_contexts_on_llm_model_id"
    t.index ["user_id"], name: "index_llm_contexts_on_user_id"
  end

  create_table "llm_models", force: :cascade do |t|
    t.json "capabilities", default: []
    t.integer "context_window"
    t.datetime "created_at", null: false
    t.string "family"
    t.date "knowledge_cutoff"
    t.integer "max_output_tokens"
    t.json "metadata", default: {}
    t.json "modalities", default: {}
    t.datetime "model_created_at"
    t.string "model_id", null: false
    t.string "name", null: false
    t.json "pricing", default: {}
    t.string "provider", null: false
    t.datetime "updated_at", null: false
    t.index ["family"], name: "index_llm_models_on_family"
    t.index ["provider", "model_id"], name: "index_llm_models_on_provider_and_model_id", unique: true
    t.index ["provider"], name: "index_llm_models_on_provider"
  end

  create_table "messages", force: :cascade do |t|
    t.text "content", null: false
    t.integer "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "read_at"
    t.integer "sender_id", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer "application_id", null: false
    t.datetime "created_at", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.integer "resource_owner_id", null: false
    t.datetime "revoked_at"
    t.string "scopes", default: "", null: false
    t.string "token", null: false
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer "application_id", null: false
    t.datetime "created_at", null: false
    t.integer "expires_in"
    t.string "previous_refresh_token", default: "", null: false
    t.string "refresh_token"
    t.integer "resource_owner_id"
    t.datetime "revoked_at"
    t.string "scopes"
    t.string "token", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.string "secret", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "rails_pulse_operations", force: :cascade do |t|
    t.string "codebase_location"
    t.datetime "created_at", null: false
    t.decimal "duration", precision: 15, scale: 6, null: false
    t.string "label", null: false
    t.datetime "occurred_at", null: false
    t.string "operation_type", null: false
    t.integer "query_id"
    t.integer "request_id", null: false
    t.float "start_time", default: 0.0, null: false
    t.datetime "updated_at", null: false
    t.index ["created_at", "query_id"], name: "idx_operations_for_aggregation"
    t.index ["created_at"], name: "idx_operations_created_at"
    t.index ["occurred_at", "duration", "operation_type"], name: "index_rails_pulse_operations_on_time_duration_type"
    t.index ["occurred_at"], name: "index_rails_pulse_operations_on_occurred_at"
    t.index ["operation_type"], name: "index_rails_pulse_operations_on_operation_type"
    t.index ["query_id", "duration", "occurred_at"], name: "index_rails_pulse_operations_query_performance"
    t.index ["query_id", "occurred_at"], name: "index_rails_pulse_operations_on_query_and_time"
    t.index ["query_id"], name: "index_rails_pulse_operations_on_query_id"
    t.index ["request_id"], name: "index_rails_pulse_operations_on_request_id"
  end

  create_table "rails_pulse_queries", force: :cascade do |t|
    t.datetime "analyzed_at"
    t.text "backtrace_analysis"
    t.datetime "created_at", null: false
    t.text "explain_plan"
    t.text "index_recommendations"
    t.text "issues"
    t.text "metadata"
    t.text "n_plus_one_analysis"
    t.string "normalized_sql", limit: 1000, null: false
    t.text "query_stats"
    t.text "suggestions"
    t.text "tags"
    t.datetime "updated_at", null: false
    t.index ["normalized_sql"], name: "index_rails_pulse_queries_on_normalized_sql", unique: true
  end

  create_table "rails_pulse_requests", force: :cascade do |t|
    t.string "controller_action"
    t.datetime "created_at", null: false
    t.decimal "duration", precision: 15, scale: 6, null: false
    t.boolean "is_error", default: false, null: false
    t.datetime "occurred_at", null: false
    t.string "request_uuid", null: false
    t.integer "route_id", null: false
    t.integer "status", null: false
    t.text "tags"
    t.datetime "updated_at", null: false
    t.index ["created_at", "route_id"], name: "idx_requests_for_aggregation"
    t.index ["created_at"], name: "idx_requests_created_at"
    t.index ["occurred_at"], name: "index_rails_pulse_requests_on_occurred_at"
    t.index ["request_uuid"], name: "index_rails_pulse_requests_on_request_uuid", unique: true
    t.index ["route_id", "occurred_at"], name: "index_rails_pulse_requests_on_route_id_and_occurred_at"
    t.index ["route_id"], name: "index_rails_pulse_requests_on_route_id"
  end

  create_table "rails_pulse_routes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "method", null: false
    t.string "path", null: false
    t.text "tags"
    t.datetime "updated_at", null: false
    t.index ["method", "path"], name: "index_rails_pulse_routes_on_method_and_path", unique: true
  end

  create_table "rails_pulse_summaries", force: :cascade do |t|
    t.float "avg_duration"
    t.integer "count", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "error_count", default: 0
    t.float "max_duration"
    t.float "min_duration"
    t.float "p50_duration"
    t.float "p95_duration"
    t.float "p99_duration"
    t.datetime "period_end", null: false
    t.datetime "period_start", null: false
    t.string "period_type", null: false
    t.integer "status_2xx", default: 0
    t.integer "status_3xx", default: 0
    t.integer "status_4xx", default: 0
    t.integer "status_5xx", default: 0
    t.float "stddev_duration"
    t.integer "success_count", default: 0
    t.integer "summarizable_id", null: false
    t.string "summarizable_type", null: false
    t.float "total_duration"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_rails_pulse_summaries_on_created_at"
    t.index ["period_type", "period_start"], name: "index_rails_pulse_summaries_on_period"
    t.index ["summarizable_type", "summarizable_id", "period_type", "period_start"], name: "idx_pulse_summaries_unique", unique: true
    t.index ["summarizable_type", "summarizable_id"], name: "index_rails_pulse_summaries_on_summarizable"
  end

  create_table "user_identities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "data"
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_user_identities_on_user_id"
  end

  create_table "user_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "data"
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_user_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "data"
    t.string "name", null: false
    t.integer "status", default: 0, null: false
    t.boolean "system_administrator", default: false, null: false
    t.string "type", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["status", "uid"], name: "index_users_on_status_and_uid", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "conversations", "users", column: "initiator_id"
  add_foreign_key "conversations", "users", column: "recipient_id"
  add_foreign_key "llm_context_messages", "llm_context_tool_calls"
  add_foreign_key "llm_context_messages", "llm_contexts"
  add_foreign_key "llm_context_messages", "llm_models"
  add_foreign_key "llm_context_tool_calls", "llm_context_messages"
  add_foreign_key "llm_contexts", "llm_models"
  add_foreign_key "llm_contexts", "users"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "rails_pulse_operations", "rails_pulse_queries", column: "query_id"
  add_foreign_key "rails_pulse_operations", "rails_pulse_requests", column: "request_id"
  add_foreign_key "rails_pulse_requests", "rails_pulse_routes", column: "route_id"
  add_foreign_key "user_identities", "users"
  add_foreign_key "user_sessions", "users"
end
