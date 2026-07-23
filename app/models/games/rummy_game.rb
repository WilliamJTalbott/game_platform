class RummyGame < Game
  MAX_PLAYERS = 5 # 10-card hands from a single 52-card deck cap the table at five

  self.game_class = Rummy::Game
  self.player_class = Rummy::Player

  serialize :state, coder: Rummy::Game

  def self.permitted_turn_params = [ :action, :meld_index, { cards: [] } ]

  private

  def turn_target(action:, cards: [], meld_index: nil)
    [ action, cards.map { |key| card_from_key(key) }.compact, meld_index.presence&.to_i ]
  end

  def card_from_key(key)
    return nil if key.blank?

    rank, suit = key.split("-", 2)
    state.active_player.cards.find { |card| card.rank == rank && card.suit == suit }
  end
end
