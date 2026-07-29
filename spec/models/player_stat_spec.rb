require 'rails_helper'

RSpec.describe PlayerStat, type: :model do
  describe "a user's row" do
    let(:user) { create(:user) }
    subject(:stat) { PlayerStat.find_by(user_id: user.id) }

    context "given one won two-hour game" do
      before { create(:finished_game, :go_fish, :user_won, :with_duration, user: user, duration: 2.hours) }

      it "counts the game, the win, the percentage and the duration" do
        expect(stat).to have_attributes(games_played: 1, games_won: 1,
          win_percentage: 100.0, play_seconds: 2.hours.to_i)
      end
    end

    context "given no games at all" do
      it "still has a row, zeroed, without dividing by zero" do
        expect(stat).to have_attributes(games_played: 0, games_won: 0,
          win_percentage: 0.0, play_seconds: 0)
      end
    end

    context "given a game still in progress that already flags them the winner" do
      before do
        game = create(:started_game, :go_fish, :many_participants, :has_participants, users: [ user ])
        game.participants.find_by!(user: user).update!(winner: true)
      end

      it "counts neither the game nor the win" do
        expect(stat).to have_attributes(games_played: 0, games_won: 0, play_seconds: 0)
      end
    end

    context "given a finished game that has since been soft-deleted" do
      before do
        create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ user ])
          .update!(deleted_at: Time.current)
      end

      it "still counts it" do
        expect(stat.games_played).to eq 1
      end
    end

    context "given two finished games" do
      before do
        create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ user ])
        create(:finished_game, :go_fish, :has_participants, :with_duration,
          users: [ user ], duration: 30.minutes)
      end

      it "sums their durations" do
        expect(stat).to have_attributes(games_played: 2, play_seconds: 90.minutes.to_i)
      end
    end
  end

  describe "the model" do
    let(:user) { create(:user) }

    it "resolves from its user" do
      expect(user.player_stat).to eq PlayerStat.find_by(user_id: user.id)
    end

    it "refuses writes" do
      expect { user.player_stat.update!(games_won: 99) }.to raise_error ActiveRecord::ReadOnlyRecord
    end
  end

  describe "#country" do
    it "reports the user's country" do
      user = create(:user, country: "US")

      expect(PlayerStat.find_by(user_id: user.id).country).to eq "US"
    end
  end

  describe ".ransackable_attributes" do
    it "does not allow filtering by user_id" do
      expect(PlayerStat.ransackable_attributes).to_not include("user_id")
    end
  end
end
