class CrazyEightsGame < Game
  serialize :state, coder: CrazyEights::Game

  def play_turn(card:, suit: nil)
    state.play_turn(card_from_string(card), suit)
    save!
  end

  def build_game
    CrazyEights::Game.new(create_players)
  end

  def presenter(user)
    CrazyEightsGamePresenter.new(self, user)
  end

  private

  def card_from_string(card)
    CrazyEights::Card.from_s(card)
  end

  def create_players
    users.map { |user| CrazyEights::Player.new(user.id, user.email_address) }
  end

end
