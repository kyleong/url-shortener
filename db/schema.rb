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

ActiveRecord::Schema[8.1].define(version: 2026_02_16_101521) do
  create_table "urls", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_active"
    t.string "short_code", limit: 15
    t.string "target_url"
    t.datetime "updated_at", null: false
  end

  create_table "visits", force: :cascade do |t|
    t.string "city", limit: 100
    t.string "country", limit: 100
    t.string "country_code", limit: 10
    t.datetime "created_at", null: false
    t.string "ip_address", limit: 45
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.string "referer", limit: 255
    t.datetime "updated_at", null: false
    t.integer "url_id", null: false
    t.string "user_agent", limit: 255
    t.datetime "visited_at"
    t.index ["url_id"], name: "index_visits_on_url_id"
  end

  add_foreign_key "visits", "urls"
end
