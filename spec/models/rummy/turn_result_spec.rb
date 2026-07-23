require 'rails_helper'

RSpec.describe Rummy::TurnResult do
  let(:actor) { Rummy::Player.new(1, "Alice") }
  let(:onlooker) { Rummy::Player.new(2, "Bob") }
  let(:turn_result) { described_class.new([ actor, onlooker ], actor) }

  describe "#drew_from_stock" do
    it "tells the actor which card, and onlookers only that a draw happened" do
      turn_result.drew_from_stock(CardGame::Card.new("7", "Clubs"))

      expect(actor.messages.last.text).to eq "You drew 7♣ from the stock."
      expect(onlooker.messages.last.text).to eq "Alice drew from the stock."
    end
  end

  describe "#drew_from_discard" do
    it "tells everyone which card, since the discard pile is public" do
      turn_result.drew_from_discard(CardGame::Card.new("7", "Clubs"))

      expect(actor.messages.last.text).to eq "You drew 7♣ from the discard."
      expect(onlooker.messages.last.text).to eq "Alice drew 7♣ from the discard."
    end
  end

  describe "#discarded" do
    it "tells everyone which card was discarded" do
      turn_result.discarded(CardGame::Card.new("7", "Clubs"))

      expect(actor.messages.last.text).to eq "You discarded 7♣."
      expect(onlooker.messages.last.text).to eq "Alice discarded 7♣."
    end
  end

  describe "#winner" do
    it "announces the winner to everyone" do
      turn_result.winner

      expect(actor.messages.last.text).to eq "You emptied your hand and won!"
      expect(onlooker.messages.last.text).to eq "Alice emptied their hand and won!"
    end
  end
end
