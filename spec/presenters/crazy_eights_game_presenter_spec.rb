require 'rails_helper'

RSpec.describe CrazyEightsGamePresenter do
  let(:winner) { create(:user) }
  let(:game) { create(:finished_game, :crazy_eights, :user_won, :many_participants, user: winner) }
  before { game.update!(finished_at: Time.current) }

  subject(:presenter) { game.presenter(winner) }

  it "labels the score column as Cards left" do
    expect(presenter.score_label).to eq "Cards left"
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
end
