module CrazyEights
  class Game
    attr_accessor :players, :deck, :discard, :turn_index, :results

    def initialize(players)
      @players = players
      @turn_index = 0

      @deck = Deck.new
      @discard = Discard.new
      @results = []
    end

    class InvalidCardPlayed < StandardError; end
    class InvalidSuitSelected < StandardError; end

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
      validate(card, suit)

      active_player.remove(card)
      discard.place(card, suit)

      return active_player if wins?
      switch_turn
    end

    def self.load(json)
      return if json.blank?
      from_json(json)
    end

    def self.dump(obj)
      return obj.as_json
    end

    def as_json
      {
        "players" => players.map(&:as_json),
        "deck" => deck.as_json,
        "turn_index" => turn_index,
      }
    end

    def self.from_json(hash)
      players = hash["players"].map { |player_hash| Player.load(player_hash) }

      game = self.new(players)
      game.deck = Deck.load(hash["deck"])
      game.turn_index = hash["turn_index"]
      game
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
        card = deck.draw
        active_player.receive(card)
        return if discard.valid_play?(card)
      end
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

    def validate(card, suit)
      if card.rank == Card::WILD
        raise InvalidSuitSelected, "rank needs to be valid" unless Card::SUITS.include?(suit)
      else
        raise InvalidCardPlayed, "card cannot be legally played" unless discard.valid_play?(card)
      end
    end

  end
end