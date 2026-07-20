class User < ApplicationRecord
  has_secure_password

  after_validation :create_name, if: :name_blank?

  has_many :sessions, dependent: :destroy

  has_many :participants, dependent: :destroy
  has_many :games, through: :participants

  validates :email_address, presence: true, uniqueness: { case_insensitive: true }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, on: :create

  def games_played = self.games.where.not(finished_at: nil).size
  def games_won = self.participants.where(winner: true).size
  def win_percentage = ((games_won.to_f / games_played) * 100).round(1)

  def create_name
    username = email_address.split("@").first
    self.name = username.titleize
  end

  def name_blank?
    name.blank?
  end
end
