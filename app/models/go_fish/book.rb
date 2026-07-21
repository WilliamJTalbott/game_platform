module GoFish
  class Book
    include Serializable

    attr_reader :rank

    def initialize(rank)
      @rank = rank
    end

    serializes :rank

    SIZE = 4

    def ==(other)
      rank == other.rank
    end

    def <=>(other)
      CardGame::Card::RANKS.index(rank) <=> CardGame::Card::RANKS.index(other.rank)
    end
  end
end
