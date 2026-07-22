require 'rails_helper'

RSpec.describe CardGame::Card do
  it 'has rank and suit' do
    card = described_class.new('A', 'Clubs')
    expect(card.rank).to eq 'A'
    expect(card.suit).to eq 'Clubs'
  end

  it 'cards of the same rank and suit are equal' do
    card1 = described_class.new('A', 'Clubs')
    card2 = described_class.new('10', 'Clubs')
    card3 = described_class.new('A', 'Clubs')

    expect(card1).to eq card3
    expect(card1).to_not eq card2
  end

  it 'is not equal to a non-card' do
    expect(described_class.new('A', 'Clubs')).to_not eq 'A♣'
  end

  it 'treats equal cards as one in a Set' do
    card1 = described_class.new('A', 'Clubs')
    card2 = described_class.new('A', 'Clubs')

    expect(card1.hash).to eq card2.hash
    expect(Set.new([ card1, card2 ]).size).to eq 1
  end

  it 'rejects an invalid rank' do
    expect do
      described_class.new('15', 'Clubs')
    end.to raise_error described_class::InvalidRank
  end

  it 'rejects an invalid suit' do
    expect do
      described_class.new('A', 'Minecraft')
    end.to raise_error described_class::InvalidSuit
  end

  describe "#to_s" do
    it "renders the rank with the suit's symbol" do
      expect(described_class.new('10', 'Diamonds').to_s).to eq '10♦'
    end
  end

  describe "#from_s" do
    it "parses a card back from its string form" do
      expect(described_class.from_s('10♦')).to eq described_class.new('10', 'Diamonds')
    end
  end
end
