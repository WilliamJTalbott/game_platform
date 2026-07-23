class RummyGame < Game
  self.game_class = Rummy::Game
  self.player_class = Rummy::Player

  serialize :state, coder: Rummy::Game

  def self.permitted_turn_params = %i[action card meld_index]

  private

  def turn_target(action:, card: nil, meld_index: nil)
    [ action, card_from_key(card), meld_index.presence&.to_i ]
  end

  def card_from_key(key)
    return nil if key.blank?

    rank, suit = key.split("-", 2)
    state.active_player.cards.find { |card| card.rank == rank && card.suit == suit }
  end
end
