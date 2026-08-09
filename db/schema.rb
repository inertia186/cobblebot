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

ActiveRecord::Schema[8.1].define(version: 2026_08_09_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "ips", force: :cascade do |t|
    t.string "address", null: false
    t.string "cc"
    t.string "city"
    t.string "created_at", null: false
    t.string "origin", null: false
    t.integer "player_id", null: false
    t.string "state"
    t.index ["address", "player_id"], name: "index_ips_on_address_and_player_id", unique: true
    t.index ["cc", "player_id"], name: "index_ips_on_cc_and_player_id"
    t.index ["player_id"], name: "index_ips_on_player_id"
  end

  create_table "links", force: :cascade do |t|
    t.integer "actor_id"
    t.string "actor_type"
    t.boolean "can_embed"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.datetime "last_modified_at"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["actor_type", "actor_id"], name: "index_links_on_actor_type_and_actor_id"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "author_id"
    t.string "author_type"
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "keywords"
    t.datetime "read_at"
    t.integer "recipient_id"
    t.string "recipient_term", null: false
    t.string "recipient_type"
    t.integer "reply_id"
    t.string "type"
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
    t.index ["author_id"], name: "index_messages_on_author_id"
    t.index ["recipient_id"], name: "index_messages_on_recipient_id"
    t.index ["type", "author_id"], name: "index_messages_on_type_and_author_id"
    t.index ["type", "recipient_id"], name: "index_messages_on_type_and_recipient_id"
  end

  create_table "mutes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "muted_player_id", null: false
    t.integer "player_id", null: false
    t.index ["player_id", "muted_player_id"], name: "index_mutes_on_player_id_and_muted_player_id", unique: true
    t.index ["player_id"], name: "index_mutes_on_player_id"
  end

  create_table "players", force: :cascade do |t|
    t.integer "biomes_explored", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "deaths", default: 0, null: false
    t.string "last_chat"
    t.datetime "last_chat_at"
    t.string "last_ip"
    t.string "last_location"
    t.datetime "last_login_at"
    t.datetime "last_logout_at"
    t.string "last_nick"
    t.integer "leave_game", default: 0, null: false
    t.boolean "may_autolink", default: true, null: false
    t.integer "mob_kills", default: 0, null: false
    t.string "nick"
    t.boolean "play_sounds", default: true, null: false
    t.integer "player_kills", default: 0, null: false
    t.datetime "registered_at"
    t.boolean "shall_update_stats", default: false, null: false
    t.float "spam_ratio"
    t.integer "time_since_death", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "uuid"
    t.datetime "vetted_at"
  end

  create_table "preferences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key"
    t.boolean "system", default: false, null: false
    t.datetime "updated_at", null: false
    t.string "value"
  end

  create_table "reputations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "rate"
    t.integer "trustee_id"
    t.integer "truster_id"
    t.datetime "updated_at", null: false
    t.index ["truster_id", "trustee_id"], name: "index_reputation_on_truster_id_and_trustee_id", unique: true
    t.index ["truster_id"], name: "index_reputation_on_truster_id"
  end

  create_table "server_callbacks", force: :cascade do |t|
    t.text "command", null: false
    t.string "cooldown", default: "+0 seconds", null: false
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true, null: false
    t.datetime "error_flag_at"
    t.string "help_doc"
    t.string "help_doc_key"
    t.text "last_command_output"
    t.text "last_match"
    t.string "name", null: false
    t.string "pattern", null: false
    t.text "pretty_command"
    t.string "pretty_pattern"
    t.datetime "ran_at"
    t.boolean "system", default: false, null: false
    t.string "type"
    t.datetime "updated_at", null: false
  end
end
