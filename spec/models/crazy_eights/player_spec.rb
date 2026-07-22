require 'rails_helper'

RSpec.describe CrazyEights::Player do
  let(:player) { described_class.new("Bob") }

  describe "#remove" do
    it "removes the given card from the hand" do
      card = CardGame::Card.new("A")
      player.cards = [ card, CardGame::Card.new("K") ]

      player.remove(card)

      expect(player.cards).to_not include(card)
    end
  end

  describe "#receive" do
    it "adds the given cards to the hand" do
      cards = [ CardGame::Card.new("A"), CardGame::Card.new("K") ]

      player.receive(cards.dup)

      expect(player.cards).to include(*cards)
    end
  end
end
