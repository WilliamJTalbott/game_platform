module CardGame
  class Pile
    include Serializable

    attr_accessor :cards

    def initialize
      @cards = []
    end

    serializes cards: [ Card ]

    def remaining
      cards.size
    end

    def depleted?
      cards.empty?
    end
  end
end
