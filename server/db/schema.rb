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

ActiveRecord::Schema[8.1].define(version: 2026_03_29_090004) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

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
    t.bigint "initiator_id", null: false
    t.bigint "recipient_id", null: false
    t.integer "status", default: 0, null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
    t.index ["initiator_id", "status"], name: "index_conversations_on_initiator_id_and_status"
    t.index ["initiator_id"], name: "index_conversations_on_initiator_id"
    t.index ["recipient_id", "status"], name: "index_conversations_on_recipient_id_and_status"
    t.index ["recipient_id"], name: "index_conversations_on_recipient_id"
  end

  create_table "documents", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.string "category", default: "document", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.vector "embedding", limit: 768
    t.bigint "parent_id"
    t.text "tags", default: [], null: false, array: true
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_documents_on_author_id"
    t.index ["parent_id"], name: "index_documents_on_parent_id"
  end

  create_table "humans", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "llm_context_messages", force: :cascade do |t|
    t.integer "cache_creation_tokens"
    t.integer "cached_tokens"
    t.text "content"
    t.json "content_raw"
    t.datetime "created_at", null: false
    t.integer "input_tokens"
    t.bigint "llm_context_id", null: false
    t.bigint "llm_context_tool_call_id"
    t.bigint "llm_model_id"
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
    t.bigint "llm_context_message_id", null: false
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
    t.bigint "llm_model_id"
    t.bigint "synthetic_id", null: false
    t.datetime "updated_at", null: false
    t.index ["llm_model_id"], name: "index_llm_contexts_on_llm_model_id"
    t.index ["synthetic_id"], name: "index_llm_contexts_on_synthetic_id"
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
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "read_at"
    t.bigint "sender_id", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id", "sender_id", "read_at"], name: "index_messages_on_conversation_id_and_sender_id_and_read_at"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.datetime "created_at", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.bigint "resource_owner_id", null: false
    t.datetime "revoked_at"
    t.string "scopes", default: "", null: false
    t.string "token", null: false
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.datetime "created_at", null: false
    t.integer "expires_in"
    t.string "previous_refresh_token", default: "", null: false
    t.string "refresh_token"
    t.bigint "resource_owner_id"
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
    t.string "codebase_location", comment: "File and line number (e.g., app/models/user.rb:25)"
    t.datetime "created_at", null: false
    t.decimal "duration", precision: 15, scale: 6, null: false, comment: "Operation duration in milliseconds"
    t.string "label", null: false, comment: "Descriptive name (e.g., SELECT FROM users WHERE id = 1, render layout)"
    t.datetime "occurred_at", precision: nil, null: false, comment: "When the request started"
    t.string "operation_type", null: false, comment: "Type of operation (e.g., database, view, gem_call)"
    t.bigint "query_id", comment: "Link to the normalized SQL query"
    t.bigint "request_id", null: false, comment: "Link to the request"
    t.float "start_time", default: 0.0, null: false, comment: "Operation start time in milliseconds"
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
    t.datetime "analyzed_at", comment: "When query analysis was last performed"
    t.text "backtrace_analysis", comment: "JSON object with call chain and N+1 detection"
    t.datetime "created_at", null: false
    t.text "explain_plan", comment: "EXPLAIN output from actual SQL execution"
    t.text "index_recommendations", comment: "JSON array of database index recommendations"
    t.text "issues", comment: "JSON array of detected performance issues"
    t.text "metadata", comment: "JSON object containing query complexity metrics"
    t.text "n_plus_one_analysis", comment: "JSON object with enhanced N+1 query detection results"
    t.string "normalized_sql", limit: 1000, null: false, comment: "Normalized SQL query string (e.g., SELECT * FROM users WHERE id = ?)"
    t.text "query_stats", comment: "JSON object with query characteristics analysis"
    t.text "suggestions", comment: "JSON array of optimization recommendations"
    t.text "tags", comment: "JSON array of tags for filtering and categorization"
    t.datetime "updated_at", null: false
    t.index ["normalized_sql"], name: "index_rails_pulse_queries_on_normalized_sql", unique: true
  end

  create_table "rails_pulse_requests", force: :cascade do |t|
    t.string "controller_action", comment: "Controller and action handling the request (e.g., PostsController#show)"
    t.datetime "created_at", null: false
    t.decimal "duration", precision: 15, scale: 6, null: false, comment: "Total request duration in milliseconds"
    t.boolean "is_error", default: false, null: false, comment: "True if status >= 500"
    t.datetime "occurred_at", precision: nil, null: false, comment: "When the request started"
    t.string "request_uuid", null: false, comment: "Unique identifier for the request (e.g., UUID)"
    t.bigint "route_id", null: false, comment: "Link to the route"
    t.integer "status", null: false, comment: "HTTP status code (e.g., 200, 500)"
    t.text "tags", comment: "JSON array of tags for filtering and categorization"
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
    t.string "method", null: false, comment: "HTTP method (e.g., GET, POST)"
    t.string "path", null: false, comment: "Request path (e.g., /posts/index)"
    t.text "tags", comment: "JSON array of tags for filtering and categorization"
    t.datetime "updated_at", null: false
    t.index ["method", "path"], name: "index_rails_pulse_routes_on_method_and_path", unique: true
  end

  create_table "rails_pulse_summaries", force: :cascade do |t|
    t.float "avg_duration", comment: "Average duration in milliseconds"
    t.integer "count", default: 0, null: false, comment: "Total number of requests/operations"
    t.datetime "created_at", null: false
    t.integer "error_count", default: 0, comment: "Number of error responses (5xx)"
    t.float "max_duration", comment: "Maximum duration in milliseconds"
    t.float "min_duration", comment: "Minimum duration in milliseconds"
    t.float "p50_duration", comment: "50th percentile duration"
    t.float "p95_duration", comment: "95th percentile duration"
    t.float "p99_duration", comment: "99th percentile duration"
    t.datetime "period_end", null: false, comment: "End of the aggregation period"
    t.datetime "period_start", null: false, comment: "Start of the aggregation period"
    t.string "period_type", null: false, comment: "Aggregation period type: hour, day, week, month"
    t.integer "status_2xx", default: 0, comment: "Number of 2xx responses"
    t.integer "status_3xx", default: 0, comment: "Number of 3xx responses"
    t.integer "status_4xx", default: 0, comment: "Number of 4xx responses"
    t.integer "status_5xx", default: 0, comment: "Number of 5xx responses"
    t.float "stddev_duration", comment: "Standard deviation of duration"
    t.integer "success_count", default: 0, comment: "Number of successful responses"
    t.bigint "summarizable_id", null: false, comment: "Link to Route or Query"
    t.string "summarizable_type", null: false
    t.float "total_duration", comment: "Total duration in milliseconds"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_rails_pulse_summaries_on_created_at"
    t.index ["period_type", "period_start"], name: "index_rails_pulse_summaries_on_period"
    t.index ["summarizable_type", "summarizable_id", "period_type", "period_start"], name: "idx_pulse_summaries_unique", unique: true
    t.index ["summarizable_type", "summarizable_id"], name: "index_rails_pulse_summaries_on_summarizable"
  end

  create_table "synthetic_class_skills", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "document_id", null: false
    t.bigint "synthetic_class_id", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_synthetic_class_skills_on_document_id"
    t.index ["synthetic_class_id", "document_id"], name: "idx_synthetic_class_skills_unique", unique: true
    t.index ["synthetic_class_id"], name: "index_synthetic_class_skills_on_synthetic_class_id"
  end

  create_table "synthetic_classes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "llm_tier", default: "low", null: false
    t.string "name", null: false
    t.text "operating_system", default: ""
    t.datetime "updated_at", null: false
  end

  create_table "synthetic_memories", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.vector "embedding", limit: 768
    t.string "scope", default: "personal", null: false
    t.bigint "synthetic_class_id"
    t.bigint "synthetic_id"
    t.text "tags", default: [], null: false, array: true
    t.datetime "updated_at", null: false
    t.index ["scope"], name: "index_synthetic_memories_on_scope"
    t.index ["synthetic_class_id"], name: "index_synthetic_memories_on_synthetic_class_id"
    t.index ["synthetic_id"], name: "index_synthetic_memories_on_synthetic_id"
  end

  create_table "synthetics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "emotions", default: {"joy" => 50, "sadness" => 10, "fear" => 10, "anger" => 10, "surprise" => 20, "disgust" => 5, "anticipation" => 30, "trust" => 50}
    t.integer "fatigue", default: 0
    t.string "personality", default: ""
    t.bigint "synthetic_class_id"
    t.decimal "temperature", precision: 3, scale: 2, default: "0.4"
    t.datetime "updated_at", null: false
    t.index ["synthetic_class_id"], name: "index_synthetics_on_synthetic_class_id"
  end

  create_table "task_dependencies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "dependency_id", null: false
    t.bigint "task_id", null: false
    t.datetime "updated_at", null: false
    t.index ["dependency_id"], name: "index_task_dependencies_on_dependency_id"
    t.index ["task_id", "dependency_id"], name: "index_task_dependencies_on_task_id_and_dependency_id", unique: true
    t.index ["task_id"], name: "index_task_dependencies_on_task_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "assignee_id"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.bigint "creator_id", null: false
    t.text "description"
    t.datetime "due_at"
    t.bigint "parent_id"
    t.string "schedule"
    t.integer "status", default: 0, null: false
    t.string "subject", null: false
    t.text "tags", default: [], null: false, array: true
    t.datetime "updated_at", null: false
    t.index ["assignee_id", "status"], name: "index_tasks_on_assignee_id_and_status"
    t.index ["assignee_id"], name: "index_tasks_on_assignee_id"
    t.index ["creator_id", "status"], name: "index_tasks_on_creator_id_and_status"
    t.index ["creator_id"], name: "index_tasks_on_creator_id"
    t.index ["due_at"], name: "index_tasks_on_due_at"
    t.index ["parent_id"], name: "index_tasks_on_parent_id"
  end

  create_table "user_identities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "data"
    t.bigint "human_id", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["human_id"], name: "index_user_identities_on_human_id"
    t.index ["provider", "uid"], name: "index_user_identities_on_provider_and_uid", unique: true
  end

  create_table "user_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "data"
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_user_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "role_id", null: false
    t.string "role_type", null: false
    t.integer "status", default: 0, null: false
    t.boolean "system_administrator", default: false, null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["role_type", "role_id"], name: "index_users_on_role_type_and_role_id", unique: true
    t.index ["status", "uid"], name: "index_users_on_status_and_uid", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "conversations", "users", column: "initiator_id"
  add_foreign_key "conversations", "users", column: "recipient_id"
  add_foreign_key "documents", "documents", column: "parent_id"
  add_foreign_key "documents", "users", column: "author_id"
  add_foreign_key "llm_context_messages", "llm_context_tool_calls"
  add_foreign_key "llm_context_messages", "llm_contexts"
  add_foreign_key "llm_context_messages", "llm_models"
  add_foreign_key "llm_context_tool_calls", "llm_context_messages"
  add_foreign_key "llm_contexts", "llm_models"
  add_foreign_key "llm_contexts", "synthetics"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "rails_pulse_operations", "rails_pulse_queries", column: "query_id"
  add_foreign_key "rails_pulse_operations", "rails_pulse_requests", column: "request_id"
  add_foreign_key "rails_pulse_requests", "rails_pulse_routes", column: "route_id"
  add_foreign_key "synthetic_class_skills", "documents"
  add_foreign_key "synthetic_class_skills", "synthetic_classes"
  add_foreign_key "synthetic_memories", "synthetic_classes"
  add_foreign_key "synthetic_memories", "synthetics"
  add_foreign_key "synthetics", "synthetic_classes"
  add_foreign_key "task_dependencies", "tasks"
  add_foreign_key "task_dependencies", "tasks", column: "dependency_id"
  add_foreign_key "tasks", "tasks", column: "parent_id"
  add_foreign_key "tasks", "users", column: "assignee_id"
  add_foreign_key "tasks", "users", column: "creator_id"
  add_foreign_key "user_identities", "humans"
  add_foreign_key "user_sessions", "users"
end
