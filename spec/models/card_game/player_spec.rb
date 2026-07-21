require 'rails_helper'

RSpec.describe CardGame::Player do
  let(:player) { described_class.new(1, "Bob") }

  describe "#initialize" do
    it "sets the player's name" do
      expect(player.name).to eq "Bob"
    end

    it "starts with no cards and no messages" do
      expect(player.cards).to be_empty
      expect(player.messages).to be_empty
    end
  end

  describe "#out_of_cards?" do
    it "is true when the player has no cards" do
      expect(player.out_of_cards?).to eq true
    end

    it "is false when the player holds cards" do
      player.cards = [ CardGame::Card.new("A") ]
      expect(player.out_of_cards?).to eq false
    end
  end
end
