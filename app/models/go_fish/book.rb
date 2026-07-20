module GoFish
  class Book
    attr_reader :rank

    def initialize(rank)
      @rank = rank
    end

    SIZE = 4

    def as_json = { "rank" => rank }
    def self.load(hash) = new(hash["rank"])

    def ==(other)
      rank == other.rank
    end

    def <=>(other)
      Card::RANKS.index(rank) <=> Card::RANKS.index(other.rank)
    end
  end
end
