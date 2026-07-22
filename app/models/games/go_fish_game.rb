class GoFishGame < Game
  self.game_class = GoFish::Game
  self.player_class = GoFish::Player

  serialize :state, coder: GoFish::Game

  def self.permitted_turn_params = %i[player_name rank]

  private

  def turn_target(player_name:, rank:)
    [ player_from_name(player_name), rank ]
  end

  def player_from_name(name)
    state.players.find { |player| player.name == name }
  end
end
