require 'rails_helper'

RSpec.describe RummyGame, type: :model do
  it "labels itself for the new-game form" do
    expect(RummyGame.label).to eq "Rummy"
  end

  describe "#start" do
    let(:game) { create(:game, :rummy, :has_participants, users: create_list(:user, 2)) }

    it "deals a hand to every participant" do
      game.start

      expect(game.state.players).to all have_attributes(cards: have_attributes(size: 10))
    end

    it "flips one card onto the discard" do
      game.start

      expect(game.state.discard.top).to be_a CardGame::Card
    end
  end
end
