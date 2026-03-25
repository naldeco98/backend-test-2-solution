class Reservation < ApplicationRecord
  belongs_to :room
  belongs_to :user

  scope :active, -> { where(cancelled_at: nil) }

  attr_accessor :recurring_execution
  after_create :create_recurring_occurrences, if: -> { recurring.present? && !recurring_execution }

  validates :starts_at, :ends_at, presence: true
  validate :ends_at_after_starts_at
  validate :duration_not_exceeded
  validate :within_business_hours
  validate :room_capacity_allowed
  validate :active_reservation_limit
  validate :advance_cancellation_required
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

  def active_reservation_limit
    return if user.blank?
    return if user.is_admin?

    active_count = user.reservations
                       .where('starts_at >= ?', Time.current)
                       .where(cancelled_at: nil)
                       .where.not(id: id)
                       .count

    if active_count >= 3
      errors.add(:base, 'You have reached the limit of 3 active reservations')
    end
  end

  def advance_cancellation_required
    return unless cancelled_at_changed? && cancelled_at.present?

    if starts_at - Time.current < 60.minutes
      errors.add(:base, 'Reservations can only be cancelled at least 60 minutes before its start time')
    end
  end

  def create_recurring_occurrences
    step = case recurring
           when 'daily' then 1.day
           when 'weekly' then 1.week
           else return
           end

    current_start = starts_at + step
    current_end = ends_at + step

    while current_start.to_date <= recurring_until
      occurrence = self.dup
      occurrence.starts_at = current_start
      occurrence.ends_at = current_end
      occurrence.recurring_execution = true

      occurrence.save!

      current_start += step
      current_end += step
    end
  end
end
