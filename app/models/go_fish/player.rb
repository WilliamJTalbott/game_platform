module GoFish
  class Player
    attr_accessor :user_id, :cards, :books, :name

    def initialize(id = nil, name = "unset")
      @name = name
      @user_id = id
      @cards = []
      @books = []
    end

    def book_count
      self.books.size
    end

    def self.load(hash)
      player = new(hash["user_id"])

      player.cards = hash.fetch("cards", []).map { |card| Card.load(card) }
      player.books = hash.fetch("books", []).map { |book| Book.load(book) }

      player
    end

    def as_json
      {
        "user_id" => user_id,
        "cards" => cards.map(&:as_json),
        "books" => books.map(&:as_json)
      }
    end

    def receive(cards)
      Array(cards).each { |card| process_card(card) }
    end

    private

    def process_card(card)
      self.cards = cards + [card]
      make_book(card.rank) if completed_book?(card.rank)
    end

    def completed_book?(rank)
      get_rank(rank).size == Book::SIZE
    end

    def get_rank(rank)
      cards.select { |card| card.rank == rank }
    end

    def make_book(rank)
      books.append(Book.new(rank))
      self.cards = cards.reject { |card| card.rank == rank }
    end
  end
end