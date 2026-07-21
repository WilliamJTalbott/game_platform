module CrazyEights
  class Player
    include Serializable
    include Messageable

    attr_accessor :user_id, :cards, :name, :messages

    def initialize(id = nil, name = "unset")
      @name = name
      @user_id = id
      @cards = []
      @messages = []
    end

    serializes :user_id, :name, cards: [ CardGame::Card ], messages: [ CardGame::Message ]

    def out_of_cards?
      cards.empty?
    end

    def remove(card)
      cards.delete(card)
    end

    def receive(cards)
      Array(cards).each { |card| process_card(card) }
    end

    private

    def process_card(card)
      self.cards = cards + [ card ]
    end
  end
end
