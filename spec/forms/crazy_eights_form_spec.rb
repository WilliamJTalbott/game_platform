require "rails_helper"

RSpec.describe CrazyEightsForm do
  let(:players) { Array.new(2) { CrazyEights::Player.new } }
  let(:game) { CrazyEights::Game.new(players) }
  let(:active_player) { game.active_player }
  let(:card) { CardGame::Card.new("A", "Spades") }
  let(:form) { described_class.new(game:, card: card.to_s, suit:) }
  let(:suit) { nil }

  before do
    active_player.cards << card
    game.discard.active_card = CardGame::Card.new("2", "Spades")
  end

  it "is valid when the card can be played" do
    expect(form).to be_valid
  end

  context "when the card cannot be legally played" do
    before { game.discard.active_card = CardGame::Card.new("2", "Hearts") }

    it "adds an error to card" do
      expect(form).not_to be_valid
      expect(form.errors[:card]).to include("cannot be legally played")
    end
  end

  context "when the active player does not have the card" do
    before { active_player.cards.clear }

    it "adds an error to card" do
      expect(form).not_to be_valid
      expect(form.errors[:card]).to include("is not in the player's hand")
    end
  end

  context "when a wild card is played without a suit" do
    let(:card) { CardGame::Card.new("8", "Spades") }

    it "adds an error to suit" do
      expect(form).not_to be_valid
      expect(form.errors[:suit]).to include("must be selected when playing an eight")
    end
  end

  context "when a wild card is played with a valid suit" do
    let(:card) { CardGame::Card.new("8", "Spades") }
    let(:suit) { "Clubs" }

    it "is valid" do
      expect(form).to be_valid
    end
  end

  context "when a wild card is played with an invalid suit" do
    let(:card) { CardGame::Card.new("8", "Spades") }
    let(:suit) { "invalid" }

    it "adds an error to suit" do
      expect(form).not_to be_valid
      expect(form.errors[:suit]).to include("must be selected when playing an eight")
    end
  end
end
