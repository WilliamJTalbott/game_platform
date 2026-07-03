class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  has_many :players, dependent: :destroy
  has_many :games, through: :players

  validates :email_address, presence: true, uniqueness: { case_insensitive: true }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }
end
