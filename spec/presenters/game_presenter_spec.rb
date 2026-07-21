require 'rails_helper'

RSpec.describe GamePresenter do
  let(:winner) { create(:user) }
  let(:game) { create(:finished_game, :go_fish, :user_won, :many_participants, user: winner) }
  let(:loser) { (game.users.to_a - [ winner ]).first }
  before { game.update!(finished_at: Time.current) }

  describe "the outcome from a viewer's perspective" do
    it "reports a finished game as finished" do
      expect(game.presenter(winner)).to be_finished
    end

    it "frames the outcome as a win for the winner" do
      expect(game.presenter(winner)).to be_won
    end

    it "does not frame the outcome as a win for a non-winner" do
      expect(game.presenter(loser)).to_not be_won
    end

    it "names the actual winner regardless of viewer" do
      expect(game.presenter(loser).winner).to eq winner
    end
  end

  describe "the scoreboard" do
    subject(:presenter) { game.presenter(winner) }

    it "lists every player" do
      expect(presenter.scoreboard.map(&:name)).to match_array(game.state.players.map(&:name))
    end

    it "exposes a score for each player" do
      expect(presenter.scoreboard).to all(respond_to(:score))
    end

    it "marks the winning player" do
      expect(presenter.scoreboard.select(&:winner?).map(&:name)).to eq [ winner.name ]
    end

    it "marks the viewer's own row as you" do
      expect(presenter.scoreboard.select(&:you?).map(&:name)).to eq [ winner.name ]
    end

    it "ranks the winner first even when tied on score" do
      winner_player = game.state.players.find { |player| player.user_id == winner.id }
      other_player = (game.state.players - [ winner_player ]).first
      winner_player.books = [ "3" ]
      other_player.books = [ "3" ]

      expect(presenter.scoreboard.find { |entry| entry.rank == 1 }.name).to eq winner.name
    end
  end
end
