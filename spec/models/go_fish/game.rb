require 'rails_helper'

RSpec.describe GoFish::Game do

  let!(:players) { Array.new(5, GoFish::Player.new) }
  let!(:go_fish) { described_class.new(players) }
  let(:player) { players.first }

  describe "#dump" do
    let(:json) { described_class.dump(go_fish) }
    it "transforms it into json" do # Eventually matches struct is a better test
      expect(json).to eq go_fish.as_json
    end
  end

  describe "#load" do
    let(:json) { described_class.dump(go_fish) }
    let(:restored) { described_class.load(json) }
    it "preserves round-trip state" do
      expect(restored.players).to all be_a GoFish::Player
    end
  end
end