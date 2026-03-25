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
  end
end
