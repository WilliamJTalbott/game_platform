module CrazyEights
  class Discard < Pile
    attr_accessor :active_card

    def initialize
      super
      @active_card = nil
    end

    def valid_play?(card)
      return true if card.wild?
      card.rank == active_card.rank || card.suit == active_card.suit
    end

    def place(card, suit = nil)
      if card.wild? && suit
        self.active_card = Card.new(card.rank, suit)
      else
        self.active_card = card
      end

      self.cards << card
    end

    def as_json
      super.merge("active_card" => active_card&.as_json)
    end

    def self.load(hash)
      discard = super
      discard.active_card = Card.load(hash["active_card"]) if hash["active_card"]
      discard
    end

    def recycle
      top_card = cards.last
      recyclable_cards = cards[0...-1]
      self.cards = [ top_card ]
      recyclable_cards
    end

    private
  end
end
