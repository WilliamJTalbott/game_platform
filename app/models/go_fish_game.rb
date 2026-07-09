class GoFishGame < Game
  serialize :go_fish, coder: GoFish::Game

end
