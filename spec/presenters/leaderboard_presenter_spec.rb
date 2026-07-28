require 'rails_helper'

RSpec.describe LeaderboardPresenter, type: :presenter do
  let(:viewer) { create(:user, name: "Viewer") }
  let(:other) { create(:user, name: "Other") }

  subject(:presenter) { described_class.new(sort: sort, page: page, current_user: viewer) }

  let(:page) { nil }

  context "given two users with finished games" do
    let(:sort) { "wins" }
    before do
      create(:finished_game, :go_fish, :user_won, :with_duration, user: viewer)
      create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ other ])
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

  context "given the second page of a board that overflows one page" do
    let(:sort) { "wins" }
    let(:page) { 2 }
    before do
      create_list(:user, Leaderboard::PER_PAGE + 2).each do |player|
        create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ player ])
      end
    end

    it "continues the ranks from the previous page rather than restarting at 1" do
      expect(presenter.entries.first.rank).to eq Leaderboard::PER_PAGE + 1
    end

    it "is not empty" do
      expect(presenter).to_not be_empty
    end
  end

  context "given a page past the end of the board" do
    let(:sort) { "wins" }
    let(:page) { 99 }
    before { create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ viewer ]) }

    it "reports the board as non-empty even though the page has no rows" do
      expect(presenter.entries).to be_empty
      expect(presenter).to_not be_empty
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
    before { create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ viewer ]) }

    it "reports empty with the win-percent-specific message" do
      expect(presenter).to be_empty
      expect(presenter.empty_message).to eq(
        "Win % ranks players with at least 5 finished games. Nobody qualifies yet."
      )
    end
  end
end
