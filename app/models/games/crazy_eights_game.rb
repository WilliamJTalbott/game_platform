class CrazyEightsGame < Game
  serialize :state, coder: CrazyEights::Game

  def play_turn(card:, suit: nil)
    winner = state.play_turn(card_from_string(card), suit)
    end_game(winner) if winner

    save!
  end

  def build_game
    CrazyEights::Game.new(create_players)
  end

  def presenter(user, form = nil)
    CrazyEightsGamePresenter.new(self, user, form)
  end

  def form_class
    CrazyEightsForm
  end

  private

  def card_from_string(card)
    CrazyEights::Card.from_s(card)
  end

  def create_players
    users.map { |user| CrazyEights::Player.new(user.id, user.name) }
  end
end
