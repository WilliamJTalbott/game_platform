class RummyGame < Game
  self.game_class = Rummy::Game
  self.player_class = Rummy::Player

  serialize :state, coder: Rummy::Game
end
