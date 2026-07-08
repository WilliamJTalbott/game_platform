module GoFish
  class Player
    attr_accessor :user_id, :cards, :books, :name, :messages

    def initialize(id = nil, name = "unset")
      @name = name
      @user_id = id
      @cards = []
      @books = []
      @messages = []
    end

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
      matches = get_rank(rank)
      remove_cards(matches)
      matches
    end

    def get_rank(rank)
      player.each.select{|card| rank == card.rank }
    end

    def out_of_cards?
      player.empty?
    end

    def add_normal_message(text)
      messages << Message.new(:normal, text)
    end

    def add_action_message(text)
      messages << Message.new(:action, text)
    end

    def add_alert_message(text)
      messages << Message.new(:alert, text)
    end


    def self.load(hash)
      player = new(hash["user_id"], hash["name"])

      player.cards = hash.fetch("cards", []).map { |card| Card.load(card) }
      player.books = hash.fetch("books", []).map { |book| Book.load(book) }
      player.messages = hash.fetch("messages", []).map { |message| Message.load(message) }

      player
    end

    def as_json
      {
        "user_id" => user_id,
        "name" => name,
        "cards" => cards.map(&:as_json),
        "books" => books.map(&:as_json),
        "messages" => messages.map(&:as_json)
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