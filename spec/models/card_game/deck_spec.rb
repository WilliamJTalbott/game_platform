require 'rails_helper'

RSpec.describe CardGame::Deck do
  let(:deck) { described_class.new }

  it "builds 52 unique cards" do
    expect(deck.cards.uniq(&:to_s).size).to eq 52
  end

  describe "#shuffle" do
    it "reorders the cards" do
      unshuffled = described_class.new
      deck.shuffle
      expect(deck.cards).to_not eq unshuffled.cards
    end

    it "does not hang when there is only one card to reorder" do
      deck.cards = [ CardGame::Card.new("A", "Spades") ]
      expect { deck.shuffle }.to_not raise_error
    end
  end

  describe "#draw" do
    it "returns and removes the top card" do
      top_card = deck.cards.last
      expect(deck.draw).to eq top_card
      expect(deck.remaining).to eq 51
    end
  end

  describe "#deal" do
    it "returns and removes the given number of cards" do
      dealt = deck.deal(7)
      expect(dealt.size).to eq 7
      expect(deck.remaining).to eq 45
    end
  end
end
