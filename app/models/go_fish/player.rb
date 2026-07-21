module GoFish
  class Player
    include Serializable
    include Messageable

    attr_accessor :user_id, :cards, :books, :name, :messages

    def initialize(id = nil, name = "unset")
      @name = name
      @user_id = id
      @cards = []
      @books = []
      @messages = []
    end

    serializes :user_id, :name, cards: [ CardGame::Card ], books: [ Book ], messages: [ CardGame::Message ]

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

    def out_of_cards?
      player.empty?
    end

    def receive(cards)
      Array(cards).each { |card| process_card(card) }
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
