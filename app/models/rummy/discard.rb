module Rummy
  class Discard < CardGame::Pile
    def place(card)
      cards << card
    end

    def top
      cards.last
    end

    def take
      cards.pop
    end

    def recycle
      top_card = cards.last
      recyclable_cards = cards[0...-1]
      self.cards = [ top_card ]
      recyclable_cards
    end
  end
end
