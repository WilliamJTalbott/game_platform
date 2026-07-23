require 'rails_helper'

RSpec.describe Rummy::Meld do
  describe ".valid?" do
    it "is true for three or more cards of the same rank in different suits" do
      cards = [ CardGame::Card.new("9", "Hearts"), CardGame::Card.new("9", "Spades"), CardGame::Card.new("9", "Clubs") ]
      expect(described_class.valid?(cards)).to be true
    end

    it "is false for duplicate suits within a same-rank group" do
      cards = [ CardGame::Card.new("9", "Hearts"), CardGame::Card.new("9", "Hearts"), CardGame::Card.new("9", "Clubs") ]
      expect(described_class.valid?(cards)).to be false
    end

    it "is true for three or more consecutive same-suit ranks" do
      cards = [ CardGame::Card.new("4", "Hearts"), CardGame::Card.new("5", "Hearts"), CardGame::Card.new("6", "Hearts") ]
      expect(described_class.valid?(cards)).to be true
    end

    it "treats the ace as low, not high" do
      low = [ CardGame::Card.new("A", "Hearts"), CardGame::Card.new("2", "Hearts"), CardGame::Card.new("3", "Hearts") ]
      high = [ CardGame::Card.new("Q", "Hearts"), CardGame::Card.new("K", "Hearts"), CardGame::Card.new("A", "Hearts") ]

      expect(described_class.valid?(low)).to be true
      expect(described_class.valid?(high)).to be false
    end

    it "is false for non-consecutive same-suit ranks" do
      cards = [ CardGame::Card.new("4", "Hearts"), CardGame::Card.new("5", "Hearts"), CardGame::Card.new("7", "Hearts") ]
      expect(described_class.valid?(cards)).to be false
    end

    it "is false for mixed-suit, mixed-rank groups" do
      cards = [ CardGame::Card.new("4", "Hearts"), CardGame::Card.new("5", "Spades"), CardGame::Card.new("6", "Clubs") ]
      expect(described_class.valid?(cards)).to be false
    end

    it "is false for fewer than three cards" do
      cards = [ CardGame::Card.new("9", "Hearts"), CardGame::Card.new("9", "Spades") ]
      expect(described_class.valid?(cards)).to be false
    end
  end

  describe ".build" do
    let(:cards) { [ CardGame::Card.new("9", "Hearts"), CardGame::Card.new("9", "Spades"), CardGame::Card.new("9", "Clubs") ] }

    it "returns a meld with the detected kind, owner, and cards" do
      meld = described_class.build(cards: cards, owner: 42)

      expect(meld).to have_attributes(kind: "set", owner: 42, cards: cards)
    end

    it "returns nil for an invalid selection" do
      invalid_cards = [ CardGame::Card.new("9", "Hearts"), CardGame::Card.new("2", "Spades") ]
      expect(described_class.build(cards: invalid_cards, owner: 42)).to be_nil
    end
  end

  describe "serialization round-trip" do
    it "preserves kind, owner, and cards" do
      meld = described_class.new(kind: "run", owner: 7, cards: [ CardGame::Card.new("4", "Hearts") ])
      restored = described_class.load(meld.as_json)

      expect(restored).to have_attributes(kind: "run", owner: 7)
      expect(restored.cards).to eq [ CardGame::Card.new("4", "Hearts") ]
    end
  end
end
