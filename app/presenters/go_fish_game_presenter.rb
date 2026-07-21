class GoFishGamePresenter < GamePresenter
  def name = game.name
  def player = game.player_from_user(user)

  def user_turn? = game.user_turn?(user)

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

  def score_label = "Books"

  private

  def score_for(player) = player.book_count
  def score_order = :desc
end
