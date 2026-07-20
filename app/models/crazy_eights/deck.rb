module CrazyEights
  class Deck < Pile
    def initialize
      @cards = populate
    end

    def draw
      cards.pop
    end

    def deal(num)
      cards.pop(num)
    end

    def shuffle
      self.cards = cards.shuffle
    end

    private

    def populate
      self.cards = Card::SUITS.flat_map do |suit|
        Card::RANKS.map do |rank|
          Card.new(rank, suit)
        end
      end
    end
  end
end
