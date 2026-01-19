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

ActiveRecord::Schema[7.1].define(version: 2026_01_19_190832) do
  create_table "company_requisites", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "company_name"
    t.string "bin"
    t.string "inn"
    t.string "legal_address"
    t.string "actual_address"
    t.string "director_name"
    t.string "acting_on_basis"
    t.string "iban"
    t.string "swift"
    t.string "kbe"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "bank_name"
    t.index ["user_id"], name: "index_company_requisites_on_user_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "product_id", null: false
    t.integer "quantity"
    t.decimal "price", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "status"
    t.decimal "total_amount", precision: 10, scale: 2
    t.integer "driver_id"
    t.string "delivery_address"
    t.text "delivery_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "smart_link_token"
    t.integer "company_requisite_id"
    t.string "driver_name"
    t.string "driver_phone"
    t.string "driver_car_number"
    t.datetime "driver_arrival_time"
    t.datetime "director_signed_at"
    t.index ["company_requisite_id"], name: "index_orders_on_company_requisite_id"
    t.index ["smart_link_token"], name: "index_orders_on_smart_link_token"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.string "sku"
    t.decimal "price", precision: 10, scale: 2
    t.string "category"
    t.integer "stock"
    t.text "description"
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "warehouse_location"
    t.text "characteristics", default: "{}"
    t.index ["sku"], name: "index_products_on_sku"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role"
    t.string "company_name"
    t.string "inn"
    t.string "phone"
    t.string "jti", null: false
    t.string "director_name"
    t.string "acting_on_basis"
    t.string "legal_address"
    t.string "actual_address"
    t.string "bin"
    t.string "iban"
    t.string "swift"
    t.string "otp_secret"
    t.string "otp_attempt"
    t.datetime "otp_sent_at"
    t.boolean "email_confirmed"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "company_requisites", "users"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "company_requisites"
  add_foreign_key "orders", "users"
end
