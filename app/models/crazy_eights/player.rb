module CrazyEights
  class Player
    include Messageable

    attr_accessor :user_id, :cards, :name, :messages

    def initialize(id = nil, name = "unset")
      @name = name
      @user_id = id
      @cards = []
      @messages = []
    end

    def out_of_cards?
      cards.empty?
    end

    def remove(card)
      cards.delete(card)
    end

    def receive(cards)
      Array(cards).each { |card| process_card(card) }
    end

    def self.load(hash)
      player = new(hash["user_id"], hash["name"])

      player.cards = hash.fetch("cards", []).map { |card| CardGame::Card.load(card) }
      player.messages = hash.fetch("messages", []).map { |message| CardGame::Message.load(message) }

      player
    end

    def as_json
      {
        "user_id" => user_id,
        "name" => name,
        "cards" => cards.map(&:as_json),
        "messages" => messages.map(&:as_json)
      }
    end
    private

    def process_card(card)
      self.cards = cards + [ card ]
    end
  end
end
