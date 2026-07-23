class CrazyEightsGame < Game
  MAX_PLAYERS = 7

  self.game_class = CrazyEights::Game
  self.player_class = CrazyEights::Player

  serialize :state, coder: CrazyEights::Game

  def self.permitted_turn_params = %i[card suit]

  private

  def turn_target(card:, suit: nil)
    [ card_from_string(card), suit ]
  end

  def card_from_string(card)
    CardGame::Card.from_s(card)
  end
end
