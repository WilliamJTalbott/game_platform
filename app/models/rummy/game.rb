module Rummy
  class Game < CardGame::Game
    attr_accessor :discard, :melds

    HAND_SIZE = 10

    serializes :melds, players: [ Player ], discard: Discard

    def initialize(players)
      super
      @discard = Discard.new
      @melds = []
    end

    def deal
      deck.shuffle
      players.each { |player| player.receive(deck.deal(HAND_SIZE)) }
      discard.place(deck.draw)
    end
  end
end
