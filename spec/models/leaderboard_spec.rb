require 'rails_helper'

RSpec.describe Leaderboard, type: :model do
  def row_for(user, params: {})
    Leaderboard.new(params: params).rows.find { |row| row.id == user.id }
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

      it "games_won desc orders by wins descending" do
        names = Leaderboard.new(params: { s: "games_won desc" }).rows.map(&:name)
        expect(names.index("Big Winner")).to be < names.index("Big Loser")
      end

      it "games_played desc orders by games played descending" do
        create(:finished_game, :go_fish, :user_won, :with_duration, user: big_winner, duration: 10.minutes)

        names = Leaderboard.new(params: { s: "games_played desc" }).rows.map(&:name)
        expect(names.index("Big Winner")).to be < names.index("Big Loser")
      end

      it "play_seconds desc orders by summed duration descending" do
        names = Leaderboard.new(params: { s: "play_seconds desc" }).rows.map(&:name)
        expect(names.index("Big Loser")).to be < names.index("Big Winner")
      end

      it "win_percentage desc orders by percentage descending" do
        names = Leaderboard.new(params: { s: "win_percentage desc" }).rows.map(&:name)
        expect(names.index("Big Winner")).to be < names.index("Big Loser")
      end

      it "an unrecognized sort attribute falls back to the default" do
        names = Leaderboard.new(params: { s: "user_id desc" }).rows.map(&:name)
        expect(names.first).to eq "Big Winner"
      end

      it "breaks ties deterministically by games played then name across two calls" do
        first_call = Leaderboard.new(params: { s: "games_won desc" }).rows.map(&:id)
        second_call = Leaderboard.new(params: { s: "games_won desc" }).rows.map(&:id)
        expect(first_call).to eq second_call
      end
    end

    context "given a country filter" do
      let(:us_player) { create(:user, name: "US Player", country: "US") }
      let(:ca_player) { create(:user, name: "CA Player", country: "CA") }

      before do
        create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ us_player ])
        create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ ca_player ])
      end

      it "returns only that country's players" do
        names = Leaderboard.new(params: { country_eq: "US" }).rows.map(&:name)
        expect(names).to contain_exactly("US Player")
      end
    end

    context "given a minimum-games filter" do
      let(:veteran) { create(:user, name: "Veteran") }
      let(:newcomer) { create(:user, name: "Newcomer") }

      before do
        2.times { create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ veteran ]) }
        create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ newcomer ])
      end

      it "excludes a player below the threshold" do
        names = Leaderboard.new(params: { games_played_gteq: 2 }).rows.map(&:name)
        expect(names).to contain_exactly("Veteran")
      end
    end

    context "given a partial name in a different case" do
      let(:player) { create(:user, name: "Alexandria") }

      before { create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ player ]) }

      it "matches the player" do
        names = Leaderboard.new(params: { name_i_cont: "EXAND" }).rows.map(&:name)
        expect(names).to include("Alexandria")
      end
    end

    context "given a filter that would surface a never-played user" do
      let(:never_played) { create(:user, name: "Never Played") }

      it "still excludes them" do
        names = Leaderboard.new(params: { games_played_gteq: 0 }).rows.map(&:name)
        expect(names).to_not include("Never Played")
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
  end
end
