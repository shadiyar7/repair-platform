require_relative 'config/environment'

client = IDocs::Client.new
puts client.get_document("e4180138-af98-457e-506d-08de7a8e178b").to_json
