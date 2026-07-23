module Rummy
  class Player < CardGame::Player
    private

    def process_card(card)
      self.cards = cards + [ card ]
    end
  end
end
