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

ActiveRecord::Schema[8.1].define(version: 2026_04_05_000010) do
  create_table "hub_system_command_log_entries", force: :cascade do |t|
    t.integer "actor_id"
    t.string "actor_type"
    t.string "command_class", null: false
    t.datetime "created_at", null: false
    t.text "error"
    t.json "params", default: {}
    t.text "result"
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.index ["actor_type", "actor_id"], name: "index_hub_system_command_log_entries_on_actor"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "widgets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "size", default: 0
    t.datetime "updated_at", null: false
  end
end
