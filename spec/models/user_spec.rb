require 'rails_helper'

RSpec.describe User, type: :model do
  context "When valid email is passed in" do
    let(:user) { build(:user, email_address: "toast@jelly.com") }
    it "is valid" do
      expect(user).to be_valid
    end
  end

  context "When invalid email is passed in" do
    let(:user) { build(:user, email_address: "toast") }
    it "is invalid" do
      expect(user).to be_invalid
    end
  end

  context "When valid password is passed in" do
    let(:user) { build(:user, password: "The0End#Is!Nigh") }
    it "is valid" do
      expect(user).to be_valid
    end
  end

  context "When invalid password is passed in" do
    let(:user) { build(:user, password: "toast") }
    it "is invalid" do
      expect(user).to be_invalid
    end
  end

  describe "stats" do
    let(:user) { create(:user) }

    context "when the user has finished one won game and one lost game" do
      before do
        create(:finished_game, :user_won, :many_participants, user: user).update!(finished_at: Time.current)
        create(:finished_game, :has_user, :many_participants, user: user).update!(finished_at: Time.current)
      end

      it "counts every finished game in games_played" do
        expect(user.games_played).to eq 2
      end

      it "counts only the won game in games_won" do
        expect(user.games_won).to eq 1
      end
    end

    context "when the user has no finished games" do
      it "returns 0 win_percentage, never NaN" do
        expect(user.win_percentage).to eq 0
      end
    end
  end
end
