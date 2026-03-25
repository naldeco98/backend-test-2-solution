require 'rails_helper'

RSpec.describe Reservation, type: :model do
  describe 'validations' do
    let(:room) { create(:room) }
    let(:user) { create(:user) }
    let(:start_time) { Time.zone.parse('2026-03-25 10:00:00') }
    let(:end_time) { Time.zone.parse('2026-03-25 11:00:00') }

    it 'is valid if there are no overlapping reservations' do
      reservation = build(:reservation, room: room, user: user, starts_at: start_time, ends_at: end_time)
      expect(reservation).to be_valid
    end

    context 'when there is an overlapping reservation' do
      before do
        create(:reservation, room: room, user: user, starts_at: start_time, ends_at: end_time)
      end

      it 'is invalid if it overlaps at the start' do
        overlap_start = start_time - 30.minutes
        overlap_end = start_time + 30.minutes
        reservation = build(:reservation, room: room, starts_at: overlap_start, ends_at: overlap_end)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:base]).to include('Room is already booked for this time')
      end

      it 'is invalid if it overlaps at the end' do
        overlap_start = end_time - 30.minutes
        overlap_end = end_time + 30.minutes
        reservation = build(:reservation, room: room, starts_at: overlap_start, ends_at: overlap_end)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:base]).to include('Room is already booked for this time')
      end

      it 'is invalid if it is contained within another reservation' do
        overlap_start = start_time + 15.minutes
        overlap_end = end_time - 15.minutes
        reservation = build(:reservation, room: room, starts_at: overlap_start, ends_at: overlap_end)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:base]).to include('Room is already booked for this time')
      end

      it 'is invalid if it completely covers another reservation' do
        overlap_start = start_time - 15.minutes
        overlap_end = end_time + 15.minutes
        reservation = build(:reservation, room: room, starts_at: overlap_start, ends_at: overlap_end)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:base]).to include('Room is already booked for this time')
      end

      it 'is valid if the other reservation is cancelled' do
        Reservation.last.update!(cancelled_at: Time.current)
        reservation = build(:reservation, room: room, starts_at: start_time, ends_at: end_time)
        expect(reservation).to be_valid
      end

      it 'is valid if the reservation is for a different room' do
        other_room = create(:room)
        reservation = build(:reservation, room: other_room, starts_at: start_time, ends_at: end_time)
        expect(reservation).to be_valid
      end
    end

    describe 'maximum duration (BR2)' do
      let(:room) { create(:room) }
      let(:user) { create(:user) }
      let(:start_time) { Time.zone.parse('2026-03-25 10:00:00') }

      it 'is valid if it is exactly 4 hours' do
        reservation = build(:reservation, room: room, user: user, starts_at: start_time, ends_at: start_time + 4.hours)
        expect(reservation).to be_valid
      end

      it 'is valid if it is less than 4 hours' do
        reservation = build(:reservation, room: room, user: user, starts_at: start_time, ends_at: start_time + 2.hours)
        expect(reservation).to be_valid
      end

      it 'is invalid if it is more than 4 hours' do
        reservation = build(:reservation, room: room, user: user, starts_at: start_time, ends_at: start_time + 4.hours + 1.minute)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:ends_at]).to include('cannot be more than 4 hours after starts_at')
      end
    end

    describe 'business hours (BR3)' do
      let(:room) { create(:room) }
      let(:user) { create(:user) }

      it 'is valid if it is on a Monday at 10:00 AM' do
        monday = Time.zone.parse('2026-03-23 10:00:00') # Monday
        reservation = build(:reservation, room: room, user: user, starts_at: monday, ends_at: monday + 1.hour)
        expect(reservation).to be_valid
      end

      it 'is valid if it ends exactly at 6:00 PM' do
        monday = Time.zone.parse('2026-03-23 15:00:00')
        reservation = build(:reservation, room: room, user: user, starts_at: monday, ends_at: monday + 3.hours)
        expect(reservation).to be_valid
      end

      it 'is invalid if it starts before 9:00 AM' do
        monday = Time.zone.parse('2026-03-23 08:59:00')
        reservation = build(:reservation, room: room, user: user, starts_at: monday, ends_at: monday + 1.hour)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:base]).to include('Reservations can only be between 9:00 AM and 6:00 PM, Monday through Friday')
      end

      it 'is invalid if it ends after 6:00 PM' do
        monday_start = Time.zone.parse('2026-03-23 17:30:00')
        monday_end = Time.zone.parse('2026-03-23 18:01:00')
        reservation = build(:reservation, room: room, user: user, starts_at: monday_start, ends_at: monday_end)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:base]).to include('Reservations can only be between 9:00 AM and 6:00 PM, Monday through Friday')
      end

      it 'is invalid on a Saturday' do
        saturday = Time.zone.parse('2026-03-21 10:00:00')
        reservation = build(:reservation, room: room, user: user, starts_at: saturday, ends_at: saturday + 1.hour)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:base]).to include('Reservations can only be between 9:00 AM and 6:00 PM, Monday through Friday')
      end

      it 'is invalid on a Sunday' do
        sunday = Time.zone.parse('2026-03-22 10:00:00')
        reservation = build(:reservation, room: room, user: user, starts_at: sunday, ends_at: sunday + 1.hour)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:base]).to include('Reservations can only be between 9:00 AM and 6:00 PM, Monday through Friday')
      end
    end

    describe 'capacity restriction by user (BR4)' do
      it 'is valid if user is an admin even if room capacity is huge' do
        admin = create(:user, is_admin: true, max_capacity_allowed: 5)
        room = create(:room, capacity: 50)
        reservation = build(:reservation, user: admin, room: room)
        expect(reservation).to be_valid
      end

      it 'is valid if regular user max_capacity is >= room capacity' do
        user = create(:user, is_admin: false, max_capacity_allowed: 10)
        room = create(:room, capacity: 10)
        reservation = build(:reservation, user: user, room: room)
        expect(reservation).to be_valid
      end

      it 'is invalid if regular user max_capacity is < room capacity' do
        user = create(:user, is_admin: false, max_capacity_allowed: 5)
        room = create(:room, capacity: 10)
        reservation = build(:reservation, user: user, room: room)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:base]).to include('This room exceeds your maximum allowed capacity')
      end
    end

    describe 'active reservation limit (BR5)' do
      let(:room) { create(:room) }
      let(:user) { create(:user, is_admin: false) }
      let(:future_time) { Time.zone.parse('2026-03-26 10:00:00') } # Thursday

      it 'is valid if user has 2 active future reservations' do
        [0, 1].each do |i|
          create(:reservation, user: user, room: room, starts_at: future_time + i.days, ends_at: future_time + i.days + 1.hour)
        end
        reservation = build(:reservation, user: user, room: room, starts_at: future_time + 4.days, ends_at: future_time + 4.days + 1.hour) # Monday
        expect(reservation).to be_valid
      end

      it 'is invalid if user already has 3 active future reservations' do
        [0, 1, 4].each do |i| # Thu, Fri, Mon
          create(:reservation, user: user, room: room, starts_at: future_time + i.days, ends_at: future_time + i.days + 1.hour)
        end
        reservation = build(:reservation, user: user, room: room, starts_at: future_time + 5.days, ends_at: future_time + 5.days + 1.hour) # Tue
        expect(reservation).not_to be_valid
        expect(reservation.errors[:base]).to include('You have reached the limit of 3 active reservations')
      end

      it 'is valid if user has 3 reservations but one is cancelled' do
        [0, 1, 4].each do |i|
          create(:reservation, user: user, room: room, starts_at: future_time + i.days, ends_at: future_time + i.days + 1.hour)
        end
        user.reservations.first.update!(cancelled_at: Time.current)
        reservation = build(:reservation, user: user, room: room, starts_at: future_time + 5.days, ends_at: future_time + 5.days + 1.hour)
        expect(reservation).to be_valid
      end

      it 'is valid for admin regardless of count' do
        admin = create(:user, is_admin: true)
        [0, 1, 4, 5].each do |i|
          create(:reservation, user: admin, room: room, starts_at: future_time + i.days, ends_at: future_time + i.days + 1.hour)
        end
        reservation = build(:reservation, user: admin, room: room, starts_at: future_time + 6.days, ends_at: future_time + 6.days + 1.hour) # Wed
        expect(reservation).to be_valid
      end
    end
  end
end
