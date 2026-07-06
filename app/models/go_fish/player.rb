module GoFish
  class Player
    attr_accessor :cards

    def initialize
      @cards = []
    end

    def self.load(hash)
      self.new
    end

    def as_json
      {}
    end

    def receive(cards)
      Array(cards).each { |card| process_card(card) }
    end

    private

    def process_card(card)
      self.cards = cards + [card]
      make_book(card.rank) if completed_book?(card.rank)
    end

    def remove_cards(cards)
      self.cards = cards - cards
    end

    def completed_book?(rank)
      get_rank(rank).size == Book::SIZE
    end

    def get_rank(rank)
      cards.each.select{|card| rank == card.rank }
    end

    def make_book(rank)
      books.append(Book.new(rank))
      self.cards = cards.reject { |card| card.rank == rank }
    end

  end
end