require "rails_helper"

RSpec.describe RummyForm do
  let(:hand_card) { CardGame::Card.new("A", "Spades") }
  let(:active_player) { Rummy::Player.new(nil, "Active Player") }
  let(:opponent) { Rummy::Player.new(nil, "Opponent") }
  let(:game) { Rummy::Game.new([ active_player, opponent ]) }
  let(:action) { "draw_stock" }
  let(:cards) { [] }
  let(:meld_index) { nil }
  let(:form) { described_class.new(game:, action:, cards:, meld_index:) }

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

  context "when drawing during the meld phase" do
    before { game.phase = "meld" }

    it "rejects the draw" do
      expect(form).not_to be_valid
      expect(form.errors[:action]).to include("is not allowed during the meld phase")
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

  context "when melding during the draw phase" do
    let(:action) { "meld" }

    it "rejects it" do
      expect(form).not_to be_valid
      expect(form.errors[:action]).to include("is not allowed during the draw phase")
    end
  end

  context "when melding a valid selection during the meld phase" do
    let(:action) { "meld" }
    let(:set_cards) do
      [ CardGame::Card.new("9", "Hearts"), CardGame::Card.new("9", "Spades"), CardGame::Card.new("9", "Clubs") ]
    end
    let(:cards) { [ "9-Hearts", "9-Spades", "9-Clubs" ] }

    before do
      game.phase = "meld"
      active_player.cards += set_cards
    end

    it "is valid" do
      expect(form).to be_valid
    end
  end

  context "when melding an invalid selection" do
    let(:action) { "meld" }
    let(:cards) { [ "A-Spades" ] }

    before { game.phase = "meld" }

    it "adds an error to base" do
      expect(form).not_to be_valid
      expect(form.errors[:base]).to include("select 3 or more cards that form a run or set")
    end
  end

  context "when laying off during the draw phase" do
    let(:action) { "lay_off" }

    it "rejects it" do
      expect(form).not_to be_valid
      expect(form.errors[:action]).to include("is not allowed during the draw phase")
    end
  end

  context "when laying off a legal card during the meld phase" do
    let(:action) { "lay_off" }
    let(:meld_index) { "0" }
    let(:cards) { [ "7-Hearts" ] }
    let(:existing_meld) do
      Rummy::Meld.new(
        kind: "run", owner: opponent.user_id,
        cards: [ CardGame::Card.new("4", "Hearts"), CardGame::Card.new("5", "Hearts"), CardGame::Card.new("6", "Hearts") ]
      )
    end

    before do
      game.phase = "meld"
      game.melds = [ existing_meld ]
      active_player.cards << CardGame::Card.new("7", "Hearts")
    end

    it "is valid" do
      expect(form).to be_valid
    end
  end

  context "when laying off without selecting a card" do
    let(:action) { "lay_off" }
    let(:meld_index) { "0" }

    before do
      game.phase = "meld"
      game.melds = [
        Rummy::Meld.new(
          kind: "run", owner: opponent.user_id,
          cards: [ CardGame::Card.new("4", "Hearts"), CardGame::Card.new("5", "Hearts"), CardGame::Card.new("6", "Hearts") ]
        )
      ]
    end

    it "adds an error to base" do
      expect(form).not_to be_valid
      expect(form.errors[:base]).to include("select cards that extend that meld legally")
    end
  end

  context "when laying off onto a meld the selection doesn't fit" do
    let(:action) { "lay_off" }
    let(:meld_index) { "0" }
    let(:cards) { [ "A-Spades" ] }

    before do
      game.phase = "meld"
      game.melds = [
        Rummy::Meld.new(
          kind: "run", owner: opponent.user_id,
          cards: [ CardGame::Card.new("4", "Hearts"), CardGame::Card.new("5", "Hearts"), CardGame::Card.new("6", "Hearts") ]
        )
      ]
    end

    it "adds an error to base" do
      expect(form).not_to be_valid
      expect(form.errors[:base]).to include("select cards that extend that meld legally")
    end
  end

  context "when laying off with no meld index" do
    let(:action) { "lay_off" }
    let(:cards) { [ "A-Spades" ] }

    before { game.phase = "meld" }

    it "adds an error to meld_index" do
      expect(form).not_to be_valid
      expect(form.errors[:meld_index]).to include("must reference an existing meld")
    end
  end

  context "when discarding during the draw phase" do
    let(:action) { "discard" }

    it "rejects the discard" do
      expect(form).not_to be_valid
      expect(form.errors[:action]).to include("is not allowed during the draw phase")
    end
  end

  context "when discarding with exactly one card selected during the meld phase" do
    let(:action) { "discard" }
    let(:cards) { [ "A-Spades" ] }

    before { game.phase = "meld" }

    it "is valid" do
      expect(form).to be_valid
    end
  end

  context "when discarding with nothing selected" do
    let(:action) { "discard" }

    before { game.phase = "meld" }

    it "adds an error to base" do
      expect(form).not_to be_valid
      expect(form.errors[:base]).to include("select exactly one card to discard")
    end
  end

  context "when discarding with more than one card selected" do
    let(:action) { "discard" }
    let(:cards) { [ "A-Spades", "2-Hearts" ] }

    before do
      game.phase = "meld"
      active_player.cards << CardGame::Card.new("2", "Hearts")
    end

    it "adds an error to base" do
      expect(form).not_to be_valid
      expect(form.errors[:base]).to include("select exactly one card to discard")
    end
  end
end
