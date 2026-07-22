module CrazyEights
  class Player < CardGame::Player
    def remove(card)
      cards.delete(card)
    end

    private

    def process_card(card)
      self.cards = cards + [ card ]
    end
  end
end
