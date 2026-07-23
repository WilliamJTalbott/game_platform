module Rummy
  class Game < CardGame::Game
    attr_accessor :discard, :melds, :phase

    HAND_SIZE = 10

    serializes :melds, :phase, players: [ Player ], discard: Discard

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

    def play_turn(action, card = nil)
      turn_result = TurnResult.new(players, active_player)

      case action
      when "draw_stock" then draw_from_stock(turn_result)
      when "draw_discard" then draw_from_discard(turn_result)
      when "discard" then discard_card(card, turn_result)
      end
    end

    private

    def draw_from_stock(turn_result)
      recycle_discard_if_depleted
      card = deck.draw
      active_player.receive([ card ])
      turn_result.drew_from_stock(card)
      self.phase = "discard"
      nil
    end

    def draw_from_discard(turn_result)
      card = discard.take
      active_player.receive([ card ])
      turn_result.drew_from_discard(card)
      self.phase = "discard"
      nil
    end

    def discard_card(card, turn_result)
      active_player.cards -= [ card ]
      discard.place(card)
      turn_result.discarded(card)
      return declare_winner(turn_result) if active_player.out_of_cards?

      advance_turn
      nil
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
