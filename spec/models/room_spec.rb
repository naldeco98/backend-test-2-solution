require 'rails_helper'

RSpec.describe Room, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:capacity) }
    it { is_expected.to validate_numericality_of(:capacity).is_greater_than(0) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:reservations) }
  end

  describe '.available_at' do
    let!(:room1) { create(:room) }
    let!(:room2) { create(:room) }
    let(:start_time) { Time.zone.parse('2026-03-30 10:00:00') }
    let(:end_time) { Time.zone.parse('2026-03-30 11:00:00') }

    it 'returns rooms that have no active reservations in the given time period' do
      create(:reservation, room: room1, starts_at: start_time, ends_at: end_time)
      
      available = Room.available_at(start_time, end_time)
      expect(available).to include(room2)
      expect(available).not_to include(room1)
    end

    it 'includes rooms with cancelled reservations in the given time period' do
      create(:reservation, room: room1, starts_at: start_time, ends_at: end_time, cancelled_at: Time.current)
      
      available = Room.available_at(start_time, end_time)
      expect(available).to include(room1)
      expect(available).to include(room2)
    end
  end
end
