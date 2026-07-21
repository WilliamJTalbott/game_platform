module GoFish
  class Player < CardGame::Player
    attr_accessor :books

    def initialize(id = nil, name = "unset")
      super
      @books = []
    end

    serializes books: [ Book ]

    def remove_cards(cards)
      self.cards -= Array(cards)
    end

    def unique_cards
      cards.uniq { |card| card.rank } || []
    end

    def book_count
      books.count
    end

    def highest_book
      books.max
    end

    def take(rank)
      matches = cards_of_rank(rank)
      remove_cards(matches)
      matches
    end

    def cards_of_rank(rank)
      cards.select { |card| card.rank == rank }
    end

    private

    def process_card(card)
      self.cards = cards + [ card ]
      make_book(card.rank) if completed_book?(card.rank)
    end

    def completed_book?(rank)
      cards_of_rank(rank).size == Book::SIZE
    end

    def make_book(rank)
      books.append(Book.new(rank))
      self.cards = cards.reject { |card| card.rank == rank }
    end
  end
end
