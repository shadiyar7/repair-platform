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

ActiveRecord::Schema[7.1].define(version: 2026_02_15_015335) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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
    t.boolean "is_verified"
    t.text "invoice_base64"
    t.string "city"
    t.text "driver_comment"
    t.float "current_lat"
    t.float "current_lng"
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
    t.boolean "is_active", default: true
    t.string "nomenclature_code"
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
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "job_title"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "warehouse_stocks", force: :cascade do |t|
    t.integer "warehouse_id", null: false
    t.string "product_sku"
    t.decimal "quantity", precision: 10, scale: 2, default: "0.0"
    t.datetime "synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "nomenclature_code"
    t.index ["product_sku"], name: "index_warehouse_stocks_on_product_sku"
    t.index ["warehouse_id", "product_sku"], name: "index_warehouse_stocks_on_warehouse_id_and_product_sku", unique: true
    t.index ["warehouse_id"], name: "index_warehouse_stocks_on_warehouse_id"
  end

  create_table "warehouses", force: :cascade do |t|
    t.string "name"
    t.integer "external_id_1c"
    t.string "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_synced_at"
    t.index ["external_id_1c"], name: "index_warehouses_on_external_id_1c"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "company_requisites", "users"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "company_requisites"
  add_foreign_key "orders", "users"
  add_foreign_key "warehouse_stocks", "warehouses"
end
