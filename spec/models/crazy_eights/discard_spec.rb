require 'rails_helper'

RSpec.describe CrazyEights::Discard do
  let(:discard) { described_class.new }

  context "#wild?" do
    it "returns true for an eight" do
      expect(discard.wild?(CardGame::Card.new("8", "Spades"))).to eq true
    end

    it "returns false for a non-eight" do
      expect(discard.wild?(CardGame::Card.new("A", "Spades"))).to eq false
    end
  end

  context "#valid_play?" do
    context "card is same rank" do
      let(:card) { CardGame::Card.new("A", "Spades") }
      let(:active_card) { CardGame::Card.new("A", "Hearts") }
      before { discard.active_card = active_card }

      it "returns true" do
        expect(discard.valid_play?(card)).to eq true
      end
    end

    context "card is same suit" do
      let(:card) { CardGame::Card.new("A", "Spades") }
      let(:active_card) { CardGame::Card.new("10", "Spades") }
      before { discard.active_card = active_card }

      it "returns true" do
        expect(discard.valid_play?(card)).to eq true
      end
    end

    context "card is not same suit or rank" do
      let(:card) { CardGame::Card.new("A", "Hearts") }
      let(:active_card) { CardGame::Card.new("10", "Spades") }
      before { discard.active_card = active_card }

      it "returns false" do
        expect(discard.valid_play?(card)).to eq false
      end
    end

    context "card is wild" do
      let(:card) { CardGame::Card.new("8", "Spades") }
      let(:active_card) { CardGame::Card.new("10", "Hearts") }
      before { discard.active_card = active_card }

      it "returns true" do
        expect(discard.valid_play?(card)).to eq true
      end
    end
  end
end
