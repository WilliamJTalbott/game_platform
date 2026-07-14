require "rails_helper"

RSpec.describe GoFishForm do
  let(:active_player) { GoFish::Player.new(nil, "Active Player") }
  let(:opponent) { GoFish::Player.new(nil, "Opponent") }
  let(:game) { GoFish::Game.new([active_player, opponent]) }
  let(:player_name) { opponent.name }
  let(:rank) { "A" }
  let(:form) { described_class.new(game:, player_name:, rank:) }

  before do
    active_player.cards << GoFish::Card.new("A")
  end

  it "is valid when asking an opponent for a rank in the active player's hand" do
    expect(form).to be_valid
  end

  context "when the player name is blank" do
    let(:player_name) { "" }

    it "requires a player name" do
      expect(form).not_to be_valid
      expect(form.errors[:player_name]).to include("can't be blank")
    end
  end

  context "when the selected player is not in the game" do
    let(:player_name) { "Unknown Player" }

    it "adds an error to player name" do
      expect(form).not_to be_valid
      expect(form.errors[:player_name]).to include("is not a player in this game")
    end
  end

  context "when the active player selects themselves" do
    let(:player_name) { active_player.name }

    it "adds an error to player name" do
      expect(form).not_to be_valid
      expect(form.errors[:player_name]).to include("cannot be yourself")
    end
  end

  context "when the rank is blank" do
    let(:rank) { "" }

    it "requires a rank" do
      expect(form).not_to be_valid
      expect(form.errors[:rank]).to include("can't be blank")
    end
  end

  context "when the rank is invalid" do
    let(:rank) { "invalid" }

    before { active_player.cards.clear }

    it "adds an error to rank" do
      expect(form).not_to be_valid
      expect(form.errors[:rank]).to include("is not valid")
    end
  end

  context "when the rank is not in the active player's hand" do
    before { active_player.cards.clear }

    it "adds an error to rank" do
      expect(form).not_to be_valid
      expect(form.errors[:rank]).to include("must be a rank in your hand")
    end
  end
end
