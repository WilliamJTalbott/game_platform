module CardGame
  class Game
    include Serializable

    attr_accessor :players, :deck, :turn_index, :results

    serializes :turn_index, deck: CardGame::Deck

    SMALL_HAND = 5
    LARGE_HAND = 7
    MIN_PLAYERS_SMALL_HAND = 4

    def initialize(players)
      @players = players
      @deck = CardGame::Deck.new
      @turn_index = 0
      @results = []
    end

    def active_player = players[turn_index]

    def deal
      deck.shuffle
      players.each { |player| player.receive(deck.deal(hand_amount)) }
    end

    # Contract: returns the winning Player, or nil if the game continues.
    def play_turn(...) = raise NotImplementedError

    def self.dump(obj)
      obj.as_json
    end

    def self.load(hash)
      super&.tap { |game| game.results = [] }
    end

    private

    def hand_amount
      players.size < MIN_PLAYERS_SMALL_HAND ? LARGE_HAND : SMALL_HAND
    end
  end
end
