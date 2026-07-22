class GoFishGamePresenter < GamePresenter
  def opponents
    game.state.players - [ player ]
  end

  def opponent_names
    opponents.map(&:name)
  end

  def books
    player&.books
  end

  def ranks
    player.unique_cards.map(&:rank)
  end

  def score_label = "Books"

  private

  def score_for(player) = player.book_count
  def score_order = :desc
end
