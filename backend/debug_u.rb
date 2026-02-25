require_relative 'config/environment'
user = User.find_by(email: 'client@repair.com') || User.last
puts "User #{user.id} #{user.email}: company_name=#{user.company_name}"
