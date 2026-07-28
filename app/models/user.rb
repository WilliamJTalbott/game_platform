class User < ApplicationRecord
  has_secure_password

  after_validation :create_name, if: :name_blank?

  has_many :sessions, dependent: :destroy

  has_many :participants, dependent: :destroy
  has_many :games, through: :participants

  has_one :player_stat

  validates :email_address, presence: true, uniqueness: { case_insensitive: true }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, on: :create

  def create_name
    username = email_address.split("@").first
    self.name = username.titleize
  end

  def name_blank?
    name.blank?
  end
end
