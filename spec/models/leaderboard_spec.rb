require 'rails_helper'

RSpec.describe Leaderboard, type: :model do
  def row_for(user, sort: Leaderboard::DEFAULT_SORT)
    Leaderboard.new(sort: sort).rows.find { |row| row.id == user.id }
  end

  describe "#rows" do
    context "given a user with one won finished game" do
      let(:user) { create(:user) }
      before { create(:finished_game, :go_fish, :user_won, :with_duration, user: user, duration: 2.hours) }

      it "reports games_played" do
        expect(row_for(user).games_played).to eq 1
      end

      it "reports games_won" do
        expect(row_for(user).games_won).to eq 1
      end

      it "reports win_percentage" do
        expect(row_for(user).win_percentage.to_f).to eq 100.0
      end

      it "reports play_seconds summed from the game's duration" do
        expect(row_for(user).play_seconds).to eq 2.hours.to_i
      end
    end

    context "given a user with no finished game" do
      let(:user) { create(:user) }

      it "excludes them" do
        expect(row_for(user)).to be_nil
      end
    end

    context "given a user whose only game is still in progress" do
      let(:user) { create(:user) }
      before { create(:started_game, :go_fish, :many_participants, :has_participants, users: [ user ]) }

      it "excludes them" do
        expect(row_for(user)).to be_nil
      end
    end

    context "given a user whose only finished game has since been soft-deleted" do
      let(:user) { create(:user) }
      before do
        create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ user ])
          .update!(deleted_at: Time.current)
      end

      it "still counts them" do
        expect(row_for(user).games_played).to eq 1
      end
    end

    context "given a user with two finished games" do
      let(:user) { create(:user) }
      before do
        create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ user ])
        create(:finished_game, :go_fish, :has_participants, :with_duration,
          users: [ user ], duration: 30.minutes)
      end

      it "sums their durations" do
        expect(row_for(user).play_seconds).to eq 90.minutes.to_i
      end
    end

    context "sorting" do
      let(:big_winner) { create(:user, name: "Big Winner") }
      let(:big_loser) { create(:user, name: "Big Loser") }

      before do
        5.times do
          create(:finished_game, :go_fish, :user_won, :with_duration, user: big_winner, duration: 10.minutes)
          create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ big_loser ])
        end
      end

      it "sort=wins orders by wins descending" do
        names = Leaderboard.new(sort: "wins").rows.map(&:name)
        expect(names.index("Big Winner")).to be < names.index("Big Loser")
      end

      it "sort=games orders by games played descending" do
        names = Leaderboard.new(sort: "games").rows.map(&:name)
        expect(names.index("Big Winner")).to be < names.index("Big Loser")
      end

      it "sort=time orders by summed duration descending" do
        names = Leaderboard.new(sort: "time").rows.map(&:name)
        expect(names.index("Big Loser")).to be < names.index("Big Winner")
      end

      it "sort=win_percent orders by percentage descending" do
        names = Leaderboard.new(sort: "win_percent").rows.map(&:name)
        expect(names.index("Big Winner")).to be < names.index("Big Loser")
      end

      it "an unrecognized sort value falls back to the default without raising" do
        expect { Leaderboard.new(sort: "nonsense").rows.to_a }.to_not raise_error
      end

      it "breaks ties deterministically by games played then name across two calls" do
        first_call = Leaderboard.new(sort: "wins").rows.map(&:id)
        second_call = Leaderboard.new(sort: "wins").rows.map(&:id)
        expect(first_call).to eq second_call
      end
    end

    context "given more qualifying players than fit on one page" do
      before do
        create_list(:user, Leaderboard::PER_PAGE + 2).each do |player|
          create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ player ])
        end
      end

      it "returns only a page's worth" do
        expect(Leaderboard.new.rows.size).to eq Leaderboard::PER_PAGE
      end

      it "counts every qualifying player, not just the page" do
        expect(Leaderboard.new.rows.total_count).to eq PlayerStat.where(games_played: 1..).count
      end

      it "returns a slice that does not overlap the first page" do
        expect(Leaderboard.new(page: 2).rows.map(&:id) & Leaderboard.new.rows.map(&:id)).to be_empty
      end

      it "returns nothing past the last page" do
        expect(Leaderboard.new(page: 99).rows).to be_empty
      end
    end

    context "the win percentage floor" do
      let(:seasoned) { create(:user, name: "Seasoned") }
      let(:rookie) { create(:user, name: "Rookie") }

      before do
        5.times { create(:finished_game, :go_fish, :user_won, :with_duration, user: seasoned) }
        4.times { create(:finished_game, :go_fish, :user_won, :with_duration, user: rookie) }
      end

      it "includes a user with exactly 5 finished games under sort=win_percent" do
        expect(row_for(seasoned, sort: "win_percent")).to_not be_nil
      end

      it "excludes a user with fewer than 5 finished games under sort=win_percent" do
        expect(row_for(rookie, sort: "win_percent")).to be_nil
      end

      it "still includes the under-floor user under sort=wins" do
        expect(row_for(rookie, sort: "wins")).to_not be_nil
      end
    end
  end
end
