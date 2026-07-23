class RummyGamePresenter < GamePresenter
  OpponentView = Struct.new(:name, :turn, keyword_init: true)
  HandCardView = Struct.new(:card, :selected, keyword_init: true)

  def opponents
    (game.state.players - [ player ]).map { |opponent| opponent_view(opponent) }
  end

  def discard_top
    game.state.discard.top
  end

  def melds
    game.state.melds
  end

  def hand_cards
    cards.to_a.map { |card| HandCardView.new(card: card, selected: false) }
  end

  def score_label = "Cards left"

  private

  def opponent_view(opponent)
    OpponentView.new(name: opponent.name, turn: opponent == game.state.active_player)
  end

  def score_for(player) = player.cards.size
  def score_order = :asc
end
