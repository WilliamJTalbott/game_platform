class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  has_many :players, dependent: :destroy
  has_many :games, through: :players

  validates :email_address, presence: true, uniqueness: { case_insensitive: true }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }

  def games_played = self.games.count

  def games_won = self.players.find_by(winner: true)
    
  def win_percentage = (games_won.to_f / games_played) * 100


end
