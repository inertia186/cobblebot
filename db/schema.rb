# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150913064149) do

  create_table "ips", force: :cascade do |t|
    t.string  "address",    null: false
    t.integer "player_id",  null: false
    t.string  "origin",     null: false
    t.string  "created_at", null: false
    t.string  "cc"
    t.string  "state"
    t.string  "city"
  end

  add_index "ips", ["cc", "player_id"], name: "index_ips_on_cc_and_player_id"
  add_index "ips", ["player_id"], name: "index_ips_on_player_id"

  create_table "links", force: :cascade do |t|
    t.string   "url",              null: false
    t.string   "title"
    t.integer  "actor_id"
    t.string   "actor_type"
    t.datetime "expires_at"
    t.datetime "last_modified_at"
    t.boolean  "can_embed"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "links", ["actor_type", "actor_id"], name: "index_links_on_actor_type_and_actor_id"

  create_table "messages", force: :cascade do |t|
    t.string   "type"
    t.text     "body",           null: false
    t.text     "keywords"
    t.string   "recipient_term", null: false
    t.string   "recipient_type"
    t.integer  "recipient_id"
    t.string   "author_type"
    t.integer  "author_id"
    t.datetime "read_at"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.datetime "deleted_at"
  end

  add_index "messages", ["author_id"], name: "index_messages_on_author_id"
  add_index "messages", ["recipient_id"], name: "index_messages_on_recipient_id"
  add_index "messages", ["type", "author_id"], name: "index_messages_on_type_and_author_id"
  add_index "messages", ["type", "recipient_id"], name: "index_messages_on_type_and_recipient_id"

  create_table "mutes", force: :cascade do |t|
    t.integer  "player_id",       null: false
    t.integer  "muted_player_id", null: false
    t.datetime "created_at",      null: false
  end

  add_index "mutes", ["player_id", "muted_player_id"], name: "index_mutes_on_player_id_and_muted_player_id"
  add_index "mutes", ["player_id"], name: "index_mutes_on_player_id"

  create_table "players", force: :cascade do |t|
    t.string   "uuid"
    t.string   "nick"
    t.string   "last_nick"
    t.string   "last_ip"
    t.string   "last_chat"
    t.string   "last_location"
    t.datetime "last_login_at"
    t.datetime "last_logout_at"
    t.float    "spam_ratio"
    t.boolean  "play_sounds",      default: true, null: false
    t.integer  "biomes_explored",  default: 0,    null: false
    t.datetime "registered_at"
    t.datetime "vetted_at"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.boolean  "may_autolink",     default: true, null: false
    t.datetime "last_chat_at"
    t.integer  "leave_game",       default: 0,    null: false
    t.integer  "deaths",           default: 0,    null: false
    t.integer  "mob_kills",        default: 0,    null: false
    t.integer  "time_since_death", default: 0,    null: false
    t.integer  "player_kills",     default: 0,    null: false
  end

  create_table "preferences", force: :cascade do |t|
    t.string   "key"
    t.string   "value"
    t.boolean  "system",     default: false, null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "reputations", force: :cascade do |t|
    t.integer  "truster_id"
    t.integer  "trustee_id"
    t.integer  "rate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "reputations", ["truster_id", "trustee_id"], name: "index_reputation_on_truster_id_and_trustee_id"
  add_index "reputations", ["truster_id"], name: "index_reputation_on_truster_id"

  create_table "server_callbacks", force: :cascade do |t|
    t.string   "type"
    t.string   "name",                                       null: false
    t.string   "pattern",                                    null: false
    t.string   "pretty_pattern"
    t.text     "last_match"
    t.text     "command",                                    null: false
    t.text     "pretty_command"
    t.text     "last_command_output"
    t.datetime "ran_at"
    t.datetime "error_flag_at"
    t.string   "cooldown",            default: "+0 seconds", null: false
    t.boolean  "enabled",             default: true,         null: false
    t.boolean  "system",              default: false,        null: false
    t.string   "help_doc_key"
    t.string   "help_doc"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
  end

end
