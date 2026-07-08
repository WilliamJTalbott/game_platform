require 'rails_helper'

RSpec.describe Game, type: :model do

  it "valid game" do
    game = build(:game)
    expect(game).to be_valid
  end

  it "invalid game_type" do
    expect do
      build(:game, game_type: "The game of Toast")
    end.to raise_error(ArgumentError)
  end

  

  context "#status" do
    let(:game) { create(:game) }
    it "returns 'waiting' if game hasn't started" do
      expect(game.status).to eq 'waiting'
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

end
