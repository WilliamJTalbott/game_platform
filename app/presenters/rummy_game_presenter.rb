class RummyGamePresenter < GamePresenter
  OpponentView = Struct.new(:name, :turn, :you, keyword_init: true)
  HandCardView = Struct.new(:card, :locked, :rank_value, :rank_index, :suit_index, keyword_init: true)
  MeldView = Struct.new(:label, :owner, :cards, keyword_init: true)

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
    cards.to_a.map { |card| hand_card_view(card) }
  end

  def score_label = "Cards left"

  private

  def card_locked?(card)
    user_turn? && game.state.locked?(card)
  end

  def hand_card_view(card)
    HandCardView.new(
      card: card,
      locked: card_locked?(card),
      rank_value: Rummy::Meld::RANK_VALUES.fetch(card.rank),
      rank_index: CardGame::Card::RANKS.index(card.rank),
      suit_index: CardGame::Card::SUITS.index(card.suit)
    )
  end

  def opponent_view(other_player)
    OpponentView.new(
      name: other_player == player ? "You" : other_player.name,
      turn: other_player == game.state.active_player,
      you: other_player == player
    )
  end

  def meld_view(meld)
    MeldView.new(label: meld_label(meld), owner: owner_name(meld.owner), cards: meld.cards)
  end

  # A set is defined by its shared rank, a run by its shared suit — surface that
  # key next to the kind, e.g. "Set · 7" or "Run · ♠".
  def meld_label(meld)
    "#{meld.kind.capitalize} · #{meld_key(meld)}"
  end

  def meld_key(meld)
    card = meld.cards.first
    meld.kind == "set" ? card.rank : CardGame::Card::SUIT_SYMBOLS.fetch(card.suit)
  end

  def owner_name(owner_user_id)
    return "you" if owner_user_id == user.id

    game.state.players.find { |other_player| other_player.user_id == owner_user_id }&.name
  end

  def score_for(player) = player.cards.size
  def score_order = :asc
end
