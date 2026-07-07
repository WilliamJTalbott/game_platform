module GoFish
  class Game

    attr_accessor :players, :deck, :turn_index

    def initialize(players)
      @players = players
      @deck = Deck.new
      @turn_index = 0
    end

    SMALL_HAND = 5
    LARGE_HAND = 7
    MIN_PLAYERS_SMALL_HAND = 4

    def start
      deck.shuffle
      deal
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
        "players" => players.map(&:as_json)
      }
    end

    def self.from_json(json)
      players = json["players"].map { |player_hash| Player.load(player_hash) }
      self.new(players)
    end

    private

    def hand_amount
      players.size < MIN_PLAYERS_SMALL_HAND ? LARGE_HAND : SMALL_HAND
    end

    def deal
      players.each { |player| deck.deal(player, hand_amount) }
    end

  end
end