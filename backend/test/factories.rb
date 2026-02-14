FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    role { "client" }
    confirmed_at { Time.current } # Auto-confirm all test users

    trait :admin do
      role { "admin" }
    end

    trait :driver do
      role { "driver" }
    end

    trait :warehouse do
      role { "warehouse" }
    end
  end

  factory :product do
    sequence(:name) { |n| "Product #{n}" }
    price { 1000.0 }
    description { "Test Product Description" }
    sku { "SKU-#{SecureRandom.hex(4).upcase}" }
  end

  factory :order do
    association :user
    status { "cart" }

    trait :with_items do
      transient do
        items_count { 2 }
      end

      after(:create) do |order, evaluator|
        create_list(:order_item, evaluator.items_count, order: order)
      end
    end
  end

  factory :order_item do
    association :order
    association :product
    quantity { 1 }
    price { 1000.0 } 
  end

  factory :warehouse do
    name { "Main Warehouse" }
    sequence(:external_id_1c) { |n| n }
    address { "123 Storage St" }
  end

  factory :warehouse_stock do
    association :warehouse
    product_sku { "A-123" }
    quantity { 10.0 }
  end

  factory :company_requisite do
    association :user
    company_name { "Default Company" }
    bin { "123456789012" }
    legal_address { "Legal Addr" }
    actual_address { "Actual Addr" }
  end
end
