module CrazyEights
  class Game < CardGame::Game
    attr_accessor :discard

    def initialize(players)
      super
      @discard = Discard.new
    end

    serializes players: [ Player ], discard: Discard

    def deal
      super
      discard.place(deck.draw)
    end

    def play_turn(card, suit = nil)
      played_by = active_player
      active_player.remove(card)
      discard.place(card, suit)
      new_turn_result(played_by, card)
      turn_result.suit_changed(suit) if discard.wild?(card)
      return declare_winner(played_by) if game_over?

      switch_turn
    end

    private

    def declare_winner(played_by)
      turn_result.winner
      played_by
    end

    def switch_turn
      self.turn_index = (turn_index + 1) % players.size
      dig_for_card unless found_playable_card
    end

    def dig_for_card
      loop do
        replenish_deck if deck.depleted?
        card = deck.draw
        active_player.receive(card)
        return if discard.valid_play?(card)
      end
    end

    def replenish_deck
      deck.cards = discard.recycle
      deck.shuffle
    end

    def found_playable_card
      active_player.cards.each do |card|
        return true if discard.valid_play?(card)
      end
      false
    end

    def game_over?
      active_player.cards.empty?
    end

    def new_turn_result(player, card)
      results.append(TurnResult.new(players, player, card))
    end

    def turn_result = results.last
  end
end
