class GoFishGame < Game
  serialize :state, coder: GoFish::Game

  def self.permitted_turn_params = %i[player_name rank]

  def build_game
    GoFish::Game.new(create_players)
  end

  def play_turn(player_name:, rank:)
    winner = state.play_turn(player_from_name(player_name), rank)
    end_game(winner) if winner

    save!
  end

  def presenter(user, form = nil)
    GoFishGamePresenter.new(self, user, form)
  end

  def form_class
    GoFishForm
  end

  private

  def player_from_name(name)
    state.players.find { |player| player.name == name }
  end

  def create_players
    users.map { |user| GoFish::Player.new(user.id, user.name) }
  end
end
