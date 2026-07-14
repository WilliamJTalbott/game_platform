class Participant < ApplicationRecord
  belongs_to :game
  belongs_to :user

  validates :game_id, uniqueness: { scope: :user }
  validate :not_started
  
  def not_started
    if game&.started_at.present?
      errors.add(:base, "Game has already started")
    end
  end

end
