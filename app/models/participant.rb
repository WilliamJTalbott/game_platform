class Participant < ApplicationRecord
  belongs_to :game
  belongs_to :user

  after_create_commit -> { broadcast_refresh_to "games" }
  after_create_commit -> { broadcast_refresh_to game }

  validates :game_id, uniqueness: { scope: :user }
  validates :host, uniqueness: { scope: :game_id }, if: :host?
  validate :not_started, on: :create
  validate :not_full, on: :create

  def not_started
    if game&.started_at.present?
      errors.add(:base, "Game has already started")
    end
  end

  def not_full
    errors.add(:base, "Game is full") if game&.full?
  end
end
