module GoFish
  class Book
    attr_reader :rank
    SIZE = 4

    def initialize(rank)
      @rank = rank
    end

    def ==(other)
      rank == other.rank
    end

    def <=>(other)
      Card::RANKS.index(rank) <=> Card::RANKS.index(other.rank)
    end

  end
end
