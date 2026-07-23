class RummyGamePresenter < GamePresenter
  OpponentView = Struct.new(:name, :turn, :you, keyword_init: true)
  HandCardView = Struct.new(:card, keyword_init: true)
  MeldView = Struct.new(:kind, :owner, :cards, keyword_init: true)

  def players_in_turn_order
    game.state.players.map { |other_player| opponent_view(other_player) }
  end

  def discard_top
    game.state.discard.top
  end

  def melds
    game.state.melds.map { |meld| meld_view(meld) }
  end

  def phase
    game.state.phase
  end

  def can_draw?
    user_turn? && phase == "draw"
  end

  def can_select?
    user_turn? && phase == "meld"
  end

  def hand_cards
    cards.to_a.map { |card| HandCardView.new(card: card) }
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

  def meld_view(meld)
    MeldView.new(kind: meld.kind, owner: owner_name(meld.owner), cards: meld.cards)
  end

  def owner_name(owner_user_id)
    return "you" if owner_user_id == user.id

    game.state.players.find { |other_player| other_player.user_id == owner_user_id }&.name
  end

  def score_for(player) = player.cards.size
  def score_order = :asc
end
