require 'rails_helper'

RSpec.describe Rummy::Player do
  let(:player) { described_class.new("Bob") }

  describe "#receive" do
    it "appends the cards to the hand" do
      cards = [ CardGame::Card.new("A", "Hearts"), CardGame::Card.new("K", "Clubs") ]
      player.receive(cards.dup)
      expect(player.cards).to include(*cards)
    end
  end
end
