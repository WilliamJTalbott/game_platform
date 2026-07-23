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
end
