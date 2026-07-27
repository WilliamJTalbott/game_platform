require 'rails_helper'

RSpec.describe LeaderboardPresenter, type: :presenter do
  def finished_game_for(user, won: false)
    game = create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ user ])
    game.participants.find_by!(user: user).update!(winner: true) if won
    game
  end

  let(:viewer) { create(:user, name: "Viewer") }
  let(:other) { create(:user, name: "Other") }

  subject(:presenter) { described_class.new(sort: sort, current_user: viewer) }

  context "given two users with finished games" do
    let(:sort) { "wins" }
    before do
      finished_game_for(viewer, won: true)
      finished_game_for(other)
    end

    it "assigns rank 1..n in the current sort order" do
      expect(presenter.entries.map(&:rank)).to eq [ 1, 2 ]
    end

    it "marks exactly one entry as you" do
      expect(presenter.entries.count(&:you?)).to eq 1
    end

    it "exposes the four sort buttons" do
      expect(presenter.sort_buttons.map { |button| button[:key] }).to contain_exactly("wins", "games", "win_percent", "time")
    end
  end

  context "given a bogus sort param" do
    let(:sort) { "nonsense" }

    it "normalizes sorted_by? to the default sort" do
      expect(presenter.sorted_by?(Leaderboard::DEFAULT_SORT)).to be true
    end
  end

  context "given nobody has finished a game" do
    let(:sort) { "wins" }

    it "reports empty with the generic message" do
      expect(presenter).to be_empty
      expect(presenter.empty_message).to eq "No games have finished yet — play one and you'll be first on the board."
    end
  end

  context "given the win-percent sort with nobody past the floor" do
    let(:sort) { "win_percent" }
    before { finished_game_for(viewer) }

    it "reports empty with the win-percent-specific message" do
      expect(presenter).to be_empty
      expect(presenter.empty_message).to eq(
        "Win % ranks players with at least 5 finished games. Nobody qualifies yet."
      )
    end
  end
end
