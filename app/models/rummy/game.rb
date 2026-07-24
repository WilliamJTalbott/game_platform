module Rummy
  class Game < CardGame::Game
    attr_accessor :discard, :melds, :phase, :locked_card

    serializes :phase, players: [ Player ], discard: Discard, melds: [ Meld ], locked_card: CardGame::Card

    def initialize(players)
      super
      @discard = Discard.new
      @melds = []
      @phase = "draw"
      @locked_card = nil
    end

    def deal
      deck.shuffle
      players.each { |player| player.receive(deck.deal(hand_size)) }
      discard.place(deck.draw)
    end

    def play_turn(action, cards = [], meld_index = nil)
      turn_result = TurnResult.new(players, active_player)
      dispatch_action(action, turn_result, cards, meld_index)
    end

    # A card drawn from the discard can't be discarded again this turn —
    # unless it's the only card left, which would otherwise soft-lock the turn.
    def locked?(card)
      card == locked_card && active_player.cards.size > 1
    end

    private

    # 2 players use a 10-card hand; larger tables shrink so the single 52-card
    # deck still leaves a workable stock.
    def hand_size
      case players.size
      when 2 then 10
      when 3, 4 then 7
      else 6
      end
    end

    def dispatch_action(action, turn_result, cards, meld_index)
      case action
      when "draw_stock" then draw_from_stock(turn_result)
      when "draw_discard" then draw_from_discard(turn_result)
      when "meld" then meld(turn_result, cards)
      when "lay_off" then lay_off(turn_result, cards, meld_index)
      when "discard" then discard_card(turn_result, cards)
      end
    end

    def draw_from_stock(turn_result)
      recycle_discard_if_depleted
      return declare_blocked(turn_result) if deck.depleted?

      card = deck.draw
      active_player.receive([ card ])
      turn_result.drew_from_stock(card)
      self.phase = "meld"
      nil
    end

    def draw_from_discard(turn_result)
      card = discard.take
      active_player.receive([ card ])
      self.locked_card = card
      turn_result.drew_from_discard(card)
      self.phase = "meld"
      nil
    end

    def meld(turn_result, cards)
      new_meld = Meld.build(cards: cards, owner: active_player.user_id)
      return nil unless new_meld

      active_player.cards -= new_meld.cards
      self.melds = melds + [ new_meld ]
      turn_result.melded(new_meld)
      finish_if_out(turn_result)
    end

    def lay_off(turn_result, cards, meld_index)
      target = melds[meld_index]
      return nil unless active_player_has_meld?
      return nil unless target&.can_add?(cards)

      active_player.cards -= cards
      melds[meld_index] = target.add(cards)
      turn_result.laid_off(cards, target)
      finish_if_out(turn_result)
    end

    def active_player_has_meld?
      melds.any? { |meld| meld.owner == active_player.user_id }
    end

    def discard_card(turn_result, cards)
      card = cards.first
      active_player.cards -= [ card ]
      discard.place(card)
      turn_result.discarded(card)
      return declare_winner(turn_result) if active_player.out_of_cards?
      advance_turn
      nil
    end

    def finish_if_out(turn_result)
      declare_winner(turn_result) if active_player.out_of_cards?
    end

    def declare_winner(turn_result)
      turn_result.winner
      active_player
    end

    # No card can be drawn and the discard can't be recycled — the hand is dead.
    # End it with a random winner rather than tracking a draw/tie.
    def declare_blocked(turn_result)
      winner = players.sample
      turn_result.blocked(winner)
      winner
    end

    def advance_turn
      self.phase = "draw"
      self.locked_card = nil
      self.turn_index = (turn_index + 1) % players.size
    end

    def recycle_discard_if_depleted
      return unless deck.depleted? && discard.remaining > 1

      deck.cards = discard.recycle
      deck.shuffle
    end
  end
end
