class Reservation < ApplicationRecord
  belongs_to :room
  belongs_to :user

  validates :starts_at, :ends_at, presence: true
  validate :ends_at_after_starts_at
  validate :duration_not_exceeded
  validate :within_business_hours
  validate :room_capacity_allowed
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

  def duration_not_exceeded
    return if starts_at.blank? || ends_at.blank?

    if ends_at - starts_at > 4.hours
      errors.add(:ends_at, 'cannot be more than 4 hours after starts_at')
    end
  end

  def within_business_hours
    return if starts_at.blank? || ends_at.blank?

    # Check if Mon-Fri (1 is Monday, 5 is Friday)
    unless starts_at.wday.between?(1, 5)
      errors.add(:base, 'Reservations can only be between 9:00 AM and 6:00 PM, Monday through Friday')
      return
    end

    # Business hours: 9:00 AM to 6:00 PM (18:00)
    # We compare the time of day
    business_start = starts_at.change(hour: 9, min: 0)
    business_end = starts_at.change(hour: 18, min: 0)

    if starts_at < business_start || ends_at > business_end
      errors.add(:base, 'Reservations can only be between 9:00 AM and 6:00 PM, Monday through Friday')
    end
  end

  def room_capacity_allowed
    return if user.blank? || room.blank?
    return if user.is_admin?

    if room.capacity > user.max_capacity_allowed
      errors.add(:base, 'This room exceeds your maximum allowed capacity')
    end
  end
end
