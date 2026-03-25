class Reservation < ApplicationRecord
  belongs_to :room
  belongs_to :user

  validates :starts_at, :ends_at, presence: true
  validate :ends_at_after_starts_at
  validate :no_overlap

  def no_overlap
    return if room_id.blank? || starts_at.blank? || ends_at.blank?

    overlapping_reservations = Reservation.where(room_id: room_id)
                                          .where.not(id: id)
                                          .where(cancelled_at: nil)
                                          .where('starts_at < ? AND ends_at > ?', ends_at, starts_at)

    if overlapping_reservations.exists?
      errors.add(:base, 'Room is already booked for this time')
    end
  end

  private

  def ends_at_after_starts_at
    return if starts_at.blank? || ends_at.blank?

    if ends_at <= starts_at
      errors.add(:ends_at, 'must be after starts_at')
    end
  end
end
