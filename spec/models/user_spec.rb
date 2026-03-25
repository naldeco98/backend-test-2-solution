require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to have_many(:reservations) }
  end

  describe '#active_reservations' do
    let(:user) { create(:user) }
    let(:room) { create(:room) }
    let(:future_time) { Time.zone.parse('2026-03-30 10:00:00') }

    it 'returns future non-cancelled reservations' do
      res1 = create(:reservation, user: user, room: room, starts_at: future_time, ends_at: future_time + 1.hour)
      res2 = create(:reservation, user: user, room: room, starts_at: future_time + 1.day, ends_at: future_time + 1.day + 1.hour)
      res3 = create(:reservation, user: user, room: room, starts_at: future_time + 2.days, ends_at: future_time + 2.days + 1.hour, cancelled_at: Time.current)
      
      active = user.active_reservations
      expect(active).to include(res1, res2)
      expect(active).not_to include(res3)
    end
  end

  describe '#admin?' do
    it 'returns true if user is admin' do
      user = build(:user, is_admin: true)
      expect(user.admin?).to be true
    end

    it 'returns false if user is not admin' do
      user = build(:user, is_admin: false)
      expect(user.admin?).to be false
    end
  end
end
