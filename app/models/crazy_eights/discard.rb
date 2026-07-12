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
      if card.wild?
        self.active_card = suit ? Card.new(card.rank, suit) : Card.new(card.rank)
      else
        self.active_card = card
      end

      self.cards << card
    end

    private

  end
end