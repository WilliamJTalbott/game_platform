module CardGame
  class Card
    include Serializable

    attr_reader :rank, :suit, :value

    RANKS = %w[ 2 3 4 5 6 7 8 9 10 J Q K A ]
    SUITS = %w[ Hearts Spades Clubs Diamonds ]

    SUIT_SYMBOLS = {
      "Hearts" => "♥",
      "Spades" => "♠",
      "Clubs" => "♣",
      "Diamonds" => "♦"
    }

    class InvalidRank < StandardError; end
    class InvalidSuit < StandardError; end

    def initialize(rank, suit = "Spades")
      raise InvalidRank unless RANKS.include?(rank)
      raise InvalidSuit unless SUITS.include?(suit)

      @rank = rank
      @suit = suit
    end

    serializes :rank, :suit

    def ==(other)
      rank == other.rank && suit == other.suit
    end

    def to_s
      "#{rank}#{suit_symbol}"
    end

    def self.from_s(str)
      new(str[0...-1], SUIT_SYMBOLS.key(str[-1]))
    end

    private

    def suit_symbol
      SUIT_SYMBOLS[suit]
    end
  end
end
