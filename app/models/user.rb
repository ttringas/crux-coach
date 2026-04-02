class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :rememberable, :validatable

  before_validation :normalize_email

  enum :role, { climber: 0, coach: 1, admin: 2 }

  has_one :climber_profile, dependent: :destroy
  has_one :coach, dependent: :destroy
  has_many :ai_interactions, dependent: :destroy

  validates :role, presence: true

  def password_required?
    false
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
