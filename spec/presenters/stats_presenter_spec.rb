require 'rails_helper'

RSpec.describe StatsPresenter do
  subject(:presenter) { StatsPresenter.new(user: user) }

  let(:user) { create(:user) }

  context "given a user who has won one of two finished games" do
    before do
      finished_game_for(user, won: true)
      finished_game_for(user)
    end

    it "reports the counts and a formatted percentage" do
      expect(presenter).to have_attributes(games_played: 2, games_won: 1, win_percentage: "50.0%")
    end
  end

  context "given a user with no games at all" do
    it "reports zeros rather than failing on a missing row" do
      expect(presenter).to have_attributes(games_played: 0, games_won: 0, win_percentage: "0.0%")
    end
  end
end
