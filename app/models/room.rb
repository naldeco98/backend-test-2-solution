class Room < ApplicationRecord
  has_many :reservations
  validates :name, :capacity, presence: true
  validates :capacity, numericality: { greater_than: 0 }

  scope :available_at, ->(starts_at, ends_at) {
    where.not(id: Reservation.active.where('starts_at < ? AND ends_at > ?', ends_at, starts_at).select(:room_id))
  }
end
