require 'rails_helper'

RSpec.describe Game, type: :model do
  let(:game) { create(:game, :many_participants) }

  context "#status" do
    let(:unstarted_game) { create(:game) }
    it "returns 'waiting' if game hasn't started" do
      expect(unstarted_game.status).to eq 'waiting'
    end

    it "returns 'started' if game has started" do
      game.start
      expect(game.status).to eq 'started'
    end

    it "returns 'finished' if game has ended" do
      game.start
      game.finish
      expect(game.status).to eq 'finished'
    end
  end

  context "#can_start?" do
    let(:empty_game) { create(:game) }

    it "returns true with 2+ participants" do
      expect(game.can_start?).to be true
    end

    it "returns false with no participants" do
      expect(empty_game.can_start?).to be false
    end
  end

  context ".playable" do
    it "returns every registered game subclass" do
      expect(Game.playable).to match_array([ GoFishGame, CrazyEightsGame ])
    end
  end

  context ".from_type" do
    it "resolves a registered type name to its class" do
      expect(Game.from_type("GoFishGame")).to eq GoFishGame
    end

    it "returns nil for an unregistered type name" do
      expect(Game.from_type("NotAGame")).to be_nil
    end
  end
end
