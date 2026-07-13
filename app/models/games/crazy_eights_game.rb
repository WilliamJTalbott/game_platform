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

  def presenter(user)
    CrazyEightsGamePresenter.new(self, user)
  end

  def form_class
    CrazyEightsForm
  end

  private

  def end_game(winner)
    winner_participant = participants.find_by!(user_id: winner.user_id)
    winner_participant.update!(winner: true)
    finish
  end

  def card_from_string(card)
    CrazyEights::Card.from_s(card)
  end

  def create_players
    users.map { |user| CrazyEights::Player.new(user.id, user.email_address) }
  end

end
