class Room < ApplicationRecord
  has_many :reservations
  validates :name, :capacity, presence: true
  validates :capacity, numericality: { greater_than: 0 }
end
