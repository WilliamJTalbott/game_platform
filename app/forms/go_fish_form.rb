class GoFishForm
  include ActiveModel::Model

  attr_accessor :game, :player_name, :rank

  validates :player_name, presence: true
  validates :rank, presence: true

  validate :player_is_an_opponent
  validate :rank_is_valid
  validate :active_player_has_rank

  private

  def selected_player
    @selected_player ||= game.players.find { |player| player.name == player_name }
  end

  def player_is_an_opponent
    return if player_name.blank?

    if selected_player.nil?
      errors.add(:player_name, "is not a player in this game")
    elsif selected_player == game.active_player
      errors.add(:player_name, "cannot be yourself")
    end
  end

  def rank_is_valid
    return if rank.blank?
    return if GoFish::Card::RANKS.include?(rank)

    errors.add(:rank, "is not valid")
  end

  def active_player_has_rank
    return if rank.blank? || errors.include?(:rank)
    return if game.active_player.cards.any? { |card| card.rank == rank }

    errors.add(:rank, "must be a rank in your hand")
  end
end
