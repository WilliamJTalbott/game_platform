require 'rails_helper'

RSpec.describe GoFishGamePresenter do
  let(:winner) { create(:user) }
  let(:game) { create(:finished_game, :go_fish, :user_won, :many_participants, user: winner) }
  before { game.update!(finished_at: Time.current) }

  subject(:presenter) { game.presenter(winner) }

  it "labels the score column as Books" do
    expect(presenter.score_label).to eq "Books"
  end

  it "exposes the current player's books" do
    winner_player = game.state.players.find { |player| player.user_id == winner.id }
    winner_player.books = [ GoFish::Book.new("3"), GoFish::Book.new("7") ]

    expect(presenter.books).to eq winner_player.books
  end

  context "with players holding a different number of books" do
    before do
      winner_player = game.state.players.find { |player| player.user_id == winner.id }
      runner_up, third = (game.state.players - [ winner_player ]).first(2)
      winner_player.books = [ "3", "4", "5" ]
      runner_up.books = [ "3", "4" ]
      third.books = [ "3" ]
    end

    it "ranks players with the most books first" do
      ranked_scores = presenter.scoreboard.sort_by(&:rank).map(&:score)
      expect(ranked_scores).to eq ranked_scores.sort.reverse
    end
  end
end
