module Rummy
  class Discard < CardGame::Pile
    def place(card)
      cards << card
    end

    def top
      cards.last
    end
  end
end
