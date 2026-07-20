class GoFishGamePresenter < GamePresenter
  def name = game.name
  def player = game.player_from_user(user)

  def user_turn? = game.user_turn?(user)

  def started?
    game.started_at.present?
  end

  def messages
    player.messages.reverse
  end

  def opponents
    game.state.players - [ player ]
  end

  def opponent_names
    opponents.map(&:name)
  end

  def cards
    player&.cards
  end

  def ranks
    player.unique_cards.map(&:rank)
  end

  private

  def score_for(player) = player.book_count
end
