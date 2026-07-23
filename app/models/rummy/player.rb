module Rummy
  class Player < CardGame::Player
    attr_accessor :selected

    def initialize(...)
      super
      @selected = []
    end

    serializes selected: [ CardGame::Card ]

    private

    def process_card(card)
      self.cards = cards + [ card ]
    end
  end
end
