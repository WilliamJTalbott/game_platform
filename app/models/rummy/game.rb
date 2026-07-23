module Rummy
  class Game < CardGame::Game
    attr_accessor :discard, :melds, :phase

    HAND_SIZE = 10 # Needs to be 7 for more than 2 players?

    serializes :phase, players: [ Player ], discard: Discard, melds: [ Meld ]

    def initialize(players)
      super
      @discard = Discard.new
      @melds = []
      @phase = "draw"
    end

    def deal
      deck.shuffle
      players.each { |player| player.receive(deck.deal(HAND_SIZE)) }
      discard.place(deck.draw)
    end

    def play_turn(action, cards = [], meld_index = nil)
      turn_result = TurnResult.new(players, active_player)
      dispatch_action(action, turn_result, cards, meld_index)
    end

    private

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
      card = deck.draw
      active_player.receive([ card ])
      turn_result.drew_from_stock(card)
      self.phase = "meld"
      nil
    end

    def draw_from_discard(turn_result)
      card = discard.take
      active_player.receive([ card ])
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
      return nil unless target&.can_add?(cards)

      active_player.cards -= cards
      melds[meld_index] = target.add(cards)
      turn_result.laid_off(cards, target)
      finish_if_out(turn_result)
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

    def advance_turn
      self.phase = "draw"
      self.turn_index = (turn_index + 1) % players.size
    end

    def recycle_discard_if_depleted
      return unless deck.depleted?

      deck.cards = discard.recycle
      deck.shuffle
    end
  end
end
