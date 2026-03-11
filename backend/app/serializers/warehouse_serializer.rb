class WarehouseSerializer
  include JSONAPI::Serializer
  attributes :id, :name, :external_id_1c, :address, :display_name, :is_active
end
