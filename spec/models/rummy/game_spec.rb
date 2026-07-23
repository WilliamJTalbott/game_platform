require 'rails_helper'

RSpec.describe Rummy::Game do
  let(:players) { Array.new(2) { Rummy::Player.new } }
  let!(:game) { described_class.new(players) }

  describe "#deal" do
    it "deals a ten-card hand to each player" do
      game.deal
      expect(game.players).to all have_attributes(cards: have_attributes(size: 10))
    end

    it "flips one card from the deck onto the discard" do
      game.deal
      expect(game.discard.top).to be_a CardGame::Card
    end

    it "removes the dealt and flipped cards from the deck" do
      game.deal
      expect(game.deck.remaining).to eq 52 - (10 * players.size) - 1
    end
  end

  describe "#as_json" do
    it "transforms it into json" do
      game.deal
      json = game.as_json
      expect(json["players"].count).to eq players.size
      expect(json["discard"]["cards"].size).to eq 1
    end
  end

  describe "#load" do
    it "preserves round-trip state" do
      game.deal
      restored = described_class.load(game.as_json)

      expect(restored.players).to all be_a Rummy::Player
      expect(restored.discard).to be_a Rummy::Discard
      expect(restored.discard.top).to eq game.discard.top
    end
  end
end
