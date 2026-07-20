
RSpec.describe CrazyEights::Discard do
  Card = CrazyEights::Card

  context "#valid_play?" do
    let(:discard) { described_class.new }

    context "card is same rank" do
      let(:card) { Card.new("A", "Spades") }
      let(:active_card) { Card.new("A", "Hearts") }
      before { discard.active_card = active_card }

      it "returns true" do
        expect(discard.valid_play?(card)).to eq true
      end
    end

    context "card is same suit" do
      let(:card) { Card.new("A", "Spades") }
      let(:active_card) { Card.new("10", "Spades") }
      before { discard.active_card = active_card }

      it "returns true" do
        expect(discard.valid_play?(card)).to eq true
      end
    end

    context "card is not same suit or rank" do
      let(:card) { Card.new("A", "Hearts") }
      let(:active_card) { Card.new("10", "Spades") }
      before { discard.active_card = active_card }

      it "returns false" do
        expect(discard.valid_play?(card)).to eq false
      end
    end

    context "card is wild" do
      let(:card) { Card.new("8", "Spades") }
      let(:active_card) { Card.new("10", "Hearts") }
      before { discard.active_card = active_card }

      it "returns true" do
        expect(discard.valid_play?(card)).to eq true
      end
    end
  end
end
