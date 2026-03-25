class User < ApplicationRecord
  has_many :reservations
  validates :name, :email, presence: true
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def active_reservations
    reservations.where('starts_at >= ?', Time.current).active
  end

  def admin?
    is_admin == true
  end
end
