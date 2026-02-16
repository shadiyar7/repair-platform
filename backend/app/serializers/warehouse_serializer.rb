class WarehouseSerializer
  include JSONAPI::Serializer
  attributes :id, :name, :external_id_1c, :address
end
