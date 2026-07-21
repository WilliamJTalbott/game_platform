require 'rails_helper'

RSpec.describe CardGame::Pile do
  let(:pile) { described_class.new }

  describe "#remaining" do
    it "counts the cards in the pile" do
      pile.cards = [ CardGame::Card.new("A", "Spades") ]
      expect(pile.remaining).to eq 1
    end
  end

  describe "#depleted?" do
    it "is true when the pile has no cards" do
      expect(pile.depleted?).to eq true
    end

    it "is false when the pile has cards" do
      pile.cards = [ CardGame::Card.new("A", "Spades") ]
      expect(pile.depleted?).to eq false
    end
  end
end
