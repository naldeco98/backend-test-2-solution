# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Destroying existing data..."
Reservation.destroy_all
Room.destroy_all
User.destroy_all

puts "Creating Users..."
admin = User.find_or_create_by!(email: 'admin@meetingrooms.inc') do |u|
  u.name = 'Admin User'
  u.department = 'IT'
  u.max_capacity_allowed = 100
  u.is_admin = true
end

john = User.find_or_create_by!(email: 'john@meetingrooms.inc') do |u|
  u.name = 'John Doe'
  u.department = 'Engineering'
  u.max_capacity_allowed = 20
  u.is_admin = false
end

sarah = User.find_or_create_by!(email: 'sarah@meetingrooms.inc') do |u|
  u.name = 'Sarah Smith'
  u.department = 'Marketing'
  u.max_capacity_allowed = 5
  u.is_admin = false
end

puts "Creating Rooms..."
boardroom = Room.find_or_create_by!(name: 'Boardroom') do |r|
  r.capacity = 50
  r.has_projector = true
  r.has_video_conference = true
  r.floor = 10
end

creative_hub = Room.find_or_create_by!(name: 'Creative Hub') do |r|
  r.capacity = 15
  r.has_projector = true
  r.has_video_conference = false
  r.floor = 2
end

phone_booth = Room.find_or_create_by!(name: 'Phone Booth 1') do |r|
  r.capacity = 2
  r.has_projector = false
  r.has_video_conference = false
  r.floor = 1
end

puts "Creating Reservations..."
next_monday = Time.zone.now.next_occurring(:monday)

# John books a room (valid: capacity 15 <= 20)
Reservation.create!(
  user: john,
  room: creative_hub,
  title: 'Engineering Sync',
  starts_at: next_monday.change(hour: 10, min: 0),
  ends_at: next_monday.change(hour: 11, min: 30)
)

# Admin books any room (valid: capacities don't matter for admin)
Reservation.create!(
  user: admin,
  room: boardroom,
  title: 'Executive Board Meeting',
  starts_at: next_monday.change(hour: 14, min: 0),
  ends_at: next_monday.change(hour: 16, min: 0)
)

# Sarah books a small room (valid: capacity 2 <= 5)
Reservation.create!(
  user: sarah,
  room: phone_booth,
  title: 'Client Call',
  starts_at: next_monday.change(hour: 9, min: 0),
  ends_at: next_monday.change(hour: 10, min: 0)
)

# A cancelled reservation
Reservation.create!(
  user: john,
  room: phone_booth,
  title: 'Old Sync',
  starts_at: (next_monday + 1.day).change(hour: 10, min: 0),
  ends_at: (next_monday + 1.day).change(hour: 11, min: 0),
  cancelled_at: Time.zone.now
)

# A daily recurring reservation (if implemented properly, this should create records)
# Note: Based on BR7, we just create the main record and its occurrences should be handled by logic.
begin
  Reservation.create!(
    user: john,
    room: creative_hub,
    title: 'Daily Standup',
    starts_at: (next_monday + 7.days).change(hour: 9, min: 30),
    ends_at: (next_monday + 7.days).change(hour: 10, min: 0),
    recurring: 'daily',
    recurring_until: (next_monday + 11.days).to_date
  )
rescue StandardError => e
  puts "Note: Could not create recurring reservation. Error: #{e.message}"
end

puts "Seed data created successfully!"
