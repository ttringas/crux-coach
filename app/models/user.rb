class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum role: { climber: 0, coach: 1, admin: 2 }

  has_one :climber_profile, dependent: :destroy
  has_one :coach, dependent: :destroy
  has_many :ai_interactions, dependent: :destroy

  validates :role, presence: true
end
