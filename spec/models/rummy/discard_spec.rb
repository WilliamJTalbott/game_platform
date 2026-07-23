require 'rails_helper'

RSpec.describe Rummy::Discard do
  let(:discard) { described_class.new }

  describe "#place" do
    it "puts the card on top" do
      discard.place(CardGame::Card.new("7", "Clubs"))
      discard.place(CardGame::Card.new("9", "Hearts"))

      expect(discard.top).to eq CardGame::Card.new("9", "Hearts")
    end
  end

  describe "#top" do
    context "when nothing has been placed" do
      it "is nil" do
        expect(discard.top).to be_nil
      end
    end
  end

  describe "#take" do
    it "removes and returns the top card" do
      discard.place(CardGame::Card.new("7", "Clubs"))
      discard.place(CardGame::Card.new("9", "Hearts"))

      expect(discard.take).to eq CardGame::Card.new("9", "Hearts")
      expect(discard.top).to eq CardGame::Card.new("7", "Clubs")
    end
  end

  describe "#recycle" do
    it "keeps the top card and returns the rest for reshuffling" do
      discard.place(CardGame::Card.new("7", "Clubs"))
      discard.place(CardGame::Card.new("8", "Clubs"))
      discard.place(CardGame::Card.new("9", "Hearts"))

      recyclable = discard.recycle

      expect(recyclable).to eq [ CardGame::Card.new("7", "Clubs"), CardGame::Card.new("8", "Clubs") ]
      expect(discard.cards).to eq [ CardGame::Card.new("9", "Hearts") ]
    end
  end
end
