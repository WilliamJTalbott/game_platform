require 'rails_helper'

RSpec.describe Player, type: :model do
  let!(:user) { create(:user) }
  let!(:game) { create(:game) }

  context "When it is possible for user to join game" do
    let!(:player) { create(:player, game: game, user: user) }
    it "is valid" do
      expect(player).to be_valid
    end

  end
  
  context "When player is already in game" do
    let!(:player) { create(:player, game: game, user: user) }
    let!(:player2) { build(:player, game: game, user: user) }
    it "is invalid" do
      expect(player2).to be_invalid
    end
  end

  context "When game is active" do
    before { game.start }

    it "is invalid" do
      player = build(:player, game: game, user: user)
      expect(player).not_to be_valid
    end
  end

end
