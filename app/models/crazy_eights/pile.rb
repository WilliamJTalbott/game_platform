module CrazyEights
  class Pile
    attr_accessor :cards

    CARDS_COUNT = 52

    def initialize
      @cards = []
    end

    def as_json
      {
        "cards" => cards.map(&:as_json)
      }
    end

    def self.load(hash)
      deck = new
      deck.cards = hash.fetch("cards", []).map { |card| Card.load(card) }
      deck
    end

    def remaining
      cards.size
    end

    def depleted?
      cards.empty?
    end
  end
end
