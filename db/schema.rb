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

ActiveRecord::Schema.define(version: 20140409224226) do

  create_table "mutual_informations", force: true do |t|
    t.integer  "user_id"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "total"
  end

  add_index "mutual_informations", ["user_id"], name: "index_mutual_informations_on_user_id"

  create_table "settings", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "key"
    t.string   "value"
    t.string   "description"
    t.string   "type"
  end

  create_table "tweets", force: true do |t|
    t.datetime "created_at"
    t.text     "text"
    t.string   "screen_name"
    t.float    "geo_longitude"
    t.float    "geo_latitude"
    t.datetime "updated_at"
    t.boolean  "geo_enabled"
    t.integer  "user_id"
    t.integer  "cluster"
    t.string   "text_cleaned"
  end

  add_index "tweets", ["user_id"], name: "index_tweets_on_user_id"

  create_table "users", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "tweets_updated"
    t.datetime "geo_clustered"
  end

end
