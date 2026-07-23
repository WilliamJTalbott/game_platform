require 'rails_helper'

RSpec.describe GamesDashboardPresenter, type: :presenter do
  let(:user) { create(:user) }
  subject(:presenter) { described_class.new(user) }

  describe "#stats_line" do
    it "reads from the user's own tallies" do
      expect(presenter.stats_line)
        .to eq "#{user.games_played} played · #{user.games_won} won · #{user.win_percentage}% win rate"
    end
  end

  describe "#your_games" do
    let!(:mine) { create(:game, :has_user, user: user, name: "Mine") }
    before do
      create(:game, :has_user, user: user, name: "Done").update!(finished_at: Time.current)
      create(:deleted_game, :has_user, user: user, name: "Gone")
    end

    it "includes only my unfinished, undeleted games" do
      expect(presenter.your_games.map(&:title)).to eq [ "Mine" ]
    end
  end

  describe "#open_games" do
    let!(:open) { create(:game, name: "Open") }
    before do
      create(:game, :has_user, user: user, name: "Mine")
      create(:started_game, :many_participants, name: "Started")
    end

    it "surfaces the waiting game the user has not joined" do
      expect(presenter.open_games.map(&:title)).to include("Open")
    end

    it "excludes the user's own and already-started games" do
      expect(presenter.open_games.map(&:title)).to_not include("Mine", "Started")
    end
  end
end
