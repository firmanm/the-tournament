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

ActiveRecord::Schema.define(version: 20171009091104) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "documents", force: :cascade do |t|
    t.integer  "category_id"
    t.integer  "document_id"
    t.string   "title",       limit: 255
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "plans", force: :cascade do |t|
    t.integer  "user_id",    null: false
    t.integer  "count",      null: false
    t.integer  "size",       null: false
    t.date     "expires_at", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["expires_at"], name: "index_plans_on_expires_at", using: :btree
    t.index ["user_id"], name: "index_plans_on_user_id", using: :btree
  end

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type", limit: 255
    t.integer  "tagger_id"
    t.string   "tagger_type",   limit: 255
    t.string   "context",       limit: 128
    t.datetime "created_at"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true, using: :btree
  end

  create_table "tags", force: :cascade do |t|
    t.string  "name",           limit: 255
    t.integer "taggings_count",             default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true, using: :btree
  end

  create_table "tournaments", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "size"
    t.string   "title",             limit: 255
    t.string   "place",             limit: 255
    t.text     "detail"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "consolation_round",             default: true
    t.string   "url",               limit: 255
    t.boolean  "secondary_final",               default: false
    t.boolean  "scoreless",                     default: false
    t.boolean  "finished",                      default: false
    t.string   "facebook_album_id", limit: 255
    t.json     "teams"
    t.json     "results"
    t.string   "token",             limit: 255
    t.boolean  "double_mountain",               default: false
    t.boolean  "private",                       default: false
    t.string   "name_width",        limit: 255
    t.string   "score_width",       limit: 255
    t.boolean  "no_ads",                        default: false
    t.boolean  "profile_images",                default: false
    t.index ["finished"], name: "index_tournaments_on_finished", using: :btree
    t.index ["user_id"], name: "index_tournaments_on_user_id", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "",    null: false
    t.string   "encrypted_password",     limit: 255, default: "",    null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "admin",                              default: false
    t.boolean  "email_subscription",                 default: true
    t.string   "name",                   limit: 255
    t.text     "profile"
    t.string   "url",                    limit: 255
    t.string   "facebook_url",           limit: 255
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

end
