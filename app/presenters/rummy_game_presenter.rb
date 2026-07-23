class RummyGamePresenter < GamePresenter
  OpponentView = Struct.new(:name, :turn, :you, keyword_init: true)
  HandCardView = Struct.new(:card, :selected, keyword_init: true)

  def players_in_turn_order
    game.state.players.map { |other_player| opponent_view(other_player) }
  end

  def discard_top
    game.state.discard.top
  end

  def melds
    game.state.melds
  end

  def phase
    game.state.phase
  end

  def can_draw?
    user_turn? && phase == "draw"
  end

  def can_discard?
    user_turn? && phase == "discard"
  end

  def hand_cards
    cards.to_a.map { |card| HandCardView.new(card: card, selected: false) }
  end

  def score_label = "Cards left"

  private

  def opponent_view(other_player)
    OpponentView.new(
      name: other_player == player ? "You" : other_player.name,
      turn: other_player == game.state.active_player,
      you: other_player == player
    )
  end

  def score_for(player) = player.cards.size
  def score_order = :asc
end
