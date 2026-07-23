require "rails_helper"

RSpec.describe RummyForm do
  let(:hand_card) { CardGame::Card.new("A", "Spades") }
  let(:active_player) { Rummy::Player.new(nil, "Active Player") }
  let(:opponent) { Rummy::Player.new(nil, "Opponent") }
  let(:game) { Rummy::Game.new([ active_player, opponent ]) }
  let(:action) { "draw_stock" }
  let(:card) { nil }
  let(:form) { described_class.new(game:, action:, card:) }

  before { active_player.cards << hand_card }

  it "is valid drawing from the stock during the draw phase" do
    expect(form).to be_valid
  end

  context "when the action is blank" do
    let(:action) { "" }

    it "requires an action" do
      expect(form).not_to be_valid
      expect(form.errors[:action]).to include("is not included in the list")
    end
  end

  context "when the action is not one of the known turn actions" do
    let(:action) { "shuffle" }

    it "rejects it" do
      expect(form).not_to be_valid
      expect(form.errors[:action]).to include("is not included in the list")
    end
  end

  context "when drawing during the discard phase" do
    before { game.phase = "discard" }

    it "rejects the draw" do
      expect(form).not_to be_valid
      expect(form.errors[:action]).to include("is not allowed during the discard phase")
    end
  end

  context "when drawing from an empty discard pile" do
    let(:action) { "draw_discard" }

    it "rejects the draw" do
      expect(form).not_to be_valid
      expect(form.errors[:base]).to include("there is no card on the discard pile to draw")
    end
  end

  context "when drawing from a non-empty discard pile" do
    let(:action) { "draw_discard" }

    before { game.discard.place(CardGame::Card.new("9", "Hearts")) }

    it "is valid" do
      expect(form).to be_valid
    end
  end

  context "when discarding during the draw phase" do
    let(:action) { "discard" }
    let(:card) { "A-Spades" }

    it "rejects the discard" do
      expect(form).not_to be_valid
      expect(form.errors[:action]).to include("is not allowed during the draw phase")
    end
  end

  context "when discarding a card in hand during the discard phase" do
    let(:action) { "discard" }
    let(:card) { "A-Spades" }

    before { game.phase = "discard" }

    it "is valid" do
      expect(form).to be_valid
    end
  end

  context "when discarding a card not in hand" do
    let(:action) { "discard" }
    let(:card) { "K-Hearts" }

    before { game.phase = "discard" }

    it "adds an error to card" do
      expect(form).not_to be_valid
      expect(form.errors[:card]).to include("must be a card in your hand")
    end
  end
end
