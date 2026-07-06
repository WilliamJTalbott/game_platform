
module GoFish
  class Deck
    
    attr_accessor :cards

    CARDS_COUNT = 52

    def initialize
      @cards = Card::SUITS.flat_map do |suit|
        Card::RANKS.map do |rank|
          Card.new(rank, suit)
        end
      end
    end

    def draw(player)
      card = cards.pop
      player.receive(card)
      return card
    end

    def deal(player, num)
      cards_array = cards.pop(num)
      player.receive(cards_array)
      return cards_array
    end

    def remaining
      cards.size
    end

    def depleted?
      cards.empty?
    end

    def shuffle
      shuffled = cards.dup
      shuffled.shuffle! while cards == shuffled
      self.cards = shuffled
    end

  end
end
