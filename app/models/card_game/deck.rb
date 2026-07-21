module CardGame
  class Deck < Pile
    def initialize
      super
      self.cards = populate
    end

    def shuffle
      return if cards.size <= 1

      shuffled = cards.dup
      shuffled.shuffle! while cards == shuffled
      self.cards = shuffled
    end

    def draw
      cards.pop
    end

    def deal(num)
      cards.pop(num)
    end

    private

    def populate
      Card::SUITS.flat_map do |suit|
        Card::RANKS.map { |rank| Card.new(rank, suit) }
      end
    end
  end
end
