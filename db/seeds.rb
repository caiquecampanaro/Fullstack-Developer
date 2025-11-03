# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create admin user
admin = User.find_or_create_by(email: 'admin@example.com') do |user|
  user.full_name = 'Admin User'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.role = :admin
end

puts "Admin user created: #{admin.email}"

# Create some sample users
10.times do |i|
  User.find_or_create_by(email: "user#{i + 1}@example.com") do |user|
    user.full_name = Faker::Name.name
    user.password = 'password123'
    user.password_confirmation = 'password123'
    user.role = :user
  end
end

puts "Sample users created"

