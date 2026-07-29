class PlayerStat < ApplicationRecord
  RANSACKABLE = %w[name country games_played games_won win_percentage play_seconds].freeze

  self.primary_key = "user_id"

  belongs_to :user

  def self.ransackable_attributes(_auth_object = nil) = RANSACKABLE
  def self.ransackable_associations(_auth_object = nil) = []

  def readonly? = true
end
