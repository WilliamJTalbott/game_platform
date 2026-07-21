require 'rails_helper'

RSpec.describe CrazyEightsGamePresenter do
  let(:winner) { create(:user) }

  describe "the end-of-game view of a finished game" do
    let(:game) { create(:finished_game, :crazy_eights, :user_won, :many_participants, user: winner) }
    let(:loser) { (game.users.to_a - [ winner ]).first }
    before { game.update!(finished_at: Time.current) }

    context "when viewed by the winner" do
      subject(:presenter) { game.presenter(winner) }

      it "reports the game finished" do
        expect(presenter).to be_finished
      end

      it "frames the outcome as a win" do
        expect(presenter).to be_won
      end
    end

    context "when viewed by a non-winner" do
      subject(:presenter) { game.presenter(loser) }

      it "does not frame the outcome as a win" do
        expect(presenter).to_not be_won
      end

      it "names the actual winner" do
        expect(presenter.winner).to eq winner
      end
    end

    context "when building the scoreboard" do
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

      it "labels the score column as Cards left" do
        expect(presenter.score_label).to eq "Cards left"
      end

      it "marks the viewer's own row as you" do
        expect(presenter.scoreboard.select(&:you?).map(&:name)).to eq [ winner.name ]
      end

      it "ranks players with the fewest cards first" do
        winner_player = game.state.players.find { |player| player.user_id == winner.id }
        runner_up, third = (game.state.players - [ winner_player ]).first(2)
        winner_player.cards = []
        runner_up.cards = [ "3" ]
        third.cards = [ "3", "4" ]

        ranked_scores = presenter.scoreboard.sort_by(&:rank).map(&:score)
        expect(ranked_scores).to eq ranked_scores.sort
      end

      it "ranks the winner first even when tied on cards with another player" do
        winner_player = game.state.players.find { |player| player.user_id == winner.id }
        other_player = (game.state.players - [ winner_player ]).first
        winner_player.cards = [ "3" ]
        other_player.cards = [ "3" ]

        expect(presenter.scoreboard.find { |entry| entry.rank == 1 }.name).to eq winner.name
      end
    end
  end

  describe "the view of an in-progress game" do
    let(:game) { create(:started_game, :crazy_eights, :has_user, :many_participants, user: winner) }

    context "when the game is not finished" do
      subject(:presenter) { game.presenter(winner) }

      it "reports the game is not finished" do
        expect(presenter).to_not be_finished
      end
    end
  end
end
