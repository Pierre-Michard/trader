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

ActiveRecord::Schema.define(version: 20210330200031) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "settings", force: :cascade do |t|
    t.string   "var",                   null: false
    t.text     "value"
    t.integer  "thing_id"
    t.string   "thing_type", limit: 30
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.index ["thing_type", "thing_id", "var"], name: "index_settings_on_thing_type_and_thing_id_and_var", unique: true, using: :btree
  end

  create_table "stats", force: :cascade do |t|
    t.float    "paymium_eur_balance"
    t.float    "paymium_btc_balance"
    t.float    "kraken_eur_balance"
    t.float    "kraken_btc_balance"
    t.float    "price"
    t.float    "paymium_best_bid"
    t.float    "paymium_best_ask"
    t.float    "kraken_best_bid"
    t.float    "kraken_best_ask"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.float    "gdax_eur_balance"
    t.float    "gdax_btc_balance"
    t.float    "gdax_best_bid"
    t.float    "gdax_best_ask"
  end

  create_table "trades", force: :cascade do |t|
    t.string   "paymium_uuid"
    t.string   "counter_order_uuid"
    t.float    "btc_amount"
    t.float    "eur_amount"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.float    "counter_order_price"
    t.float    "counter_order_fee"
    t.float    "counter_order_cost"
    t.float    "paymium_cost"
    t.float    "paymium_price"
    t.string   "aasm_state"
    t.string   "paymium_order_uuid"
    t.float    "paymium_fee"
    t.index ["paymium_uuid"], name: "index_trades_on_paymium_uuid", unique: true, using: :btree
  end

end
