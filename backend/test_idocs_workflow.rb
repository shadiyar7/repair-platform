require_relative 'config/environment'

client = IDocs::Client.new
puts client.get_workflow_info("1d07285b-760c-4ac9-a827-5d9af7974956")
