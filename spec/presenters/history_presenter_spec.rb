require 'rails_helper'

RSpec.describe HistoryPresenter, type: :presenter do
  let(:winner) { create(:user) }
  let(:game) { create(:finished_game, :go_fish, :user_won, :many_participants, user: winner) }
  let(:presenter) { described_class.new(game) }
  before { game.update!(finished_at: Time.current) }

  it "returns the game's name" do
    expect(presenter.name).to eq game.name
  end

  it "returns the game's duration" do
    expect(presenter.duration).to eq game.duration
  end

  it "returns the winning participant's name" do
    expect(presenter.winner).to eq winner.name
  end
end
