require 'rails_helper'

RSpec.describe "Participant", type: :model do
  let!(:user) { create(:user) }
  let!(:game) { create(:game) }

  context "When it is possible for user to join game" do
    let!(:participant) { create(:participant, game: game, user: user) }
    it "is valid" do
      expect(participant).to be_valid
    end
  end

  context "When participant is already in game" do
    let!(:participant) { create(:participant, game: game, user: user) }
    let!(:participant2) { build(:participant, game: game, user: user) }
    it "is invalid" do
      expect(participant2).to be_invalid
    end
  end

  context "When game is active" do
    let (:started_game) { create(:started_game, :many_participants, :has_user, user: user) }

    it "is invalid" do
      participant = build(:participant, game: started_game, user: user)
      expect(participant).not_to be_valid
    end
  end
end
