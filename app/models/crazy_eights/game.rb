module CrazyEights
  class Game
    include Serializable

    attr_accessor :players, :deck, :discard, :turn_index, :results

    def initialize(players)
      @players = players
      @turn_index = 0

      @deck = CardGame::Deck.new
      @discard = Discard.new
      @results = []
    end

    serializes :turn_index, players: [ Player ], deck: CardGame::Deck, discard: Discard

    SMALL_HAND = 5
    LARGE_HAND = 7
    MIN_PLAYERS_SMALL_HAND = 4

    def active_player = players[turn_index]

    def deal
      deck.shuffle
      players.each { |player| player.receive(deck.deal(hand_amount)) }
      discard.place(deck.draw)
    end

    def play_turn(card, suit = nil)
      played_by = active_player
      active_player.remove(card)
      discard.place(card, suit)
      new_turn_result(played_by, card)
      turn_result.suit_changed(suit) if discard.wild?(card)

      if wins?
        turn_result.winner
        return played_by
      end

      switch_turn
    end

    def self.dump(obj)
      obj.as_json
    end

    def self.load(hash)
      super&.tap { |game| game.results = [] }
    end

    def hand_amount
      players.size < MIN_PLAYERS_SMALL_HAND ? LARGE_HAND : SMALL_HAND
    end

    private

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

    def wins?
      active_player.cards.empty?
    end

    def new_turn_result(player, card)
      results.append(TurnResult.new(players, player, card))
    end

    def turn_result = results.last
  end
end
