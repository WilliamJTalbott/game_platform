require 'rails_helper'

RSpec.describe RummyGamePresenter do
  let(:active_user) { create(:user) }
  let(:waiting_user) { create(:user) }
  let(:game) { create(:started_game, :rummy, :has_participants, users: [ active_user, waiting_user ]) }

  subject(:presenter) { game.presenter(active_user) }

  it "labels the score column as Cards left" do
    expect(presenter.score_label).to eq "Cards left"
  end

  it "flags the active player as having the turn" do
    active_player = game.presenter(waiting_user).players_in_turn_order.first
    expect(active_player.turn).to be true
  end

  it "flags the presenter's own user as you" do
    you = game.presenter(waiting_user).players_in_turn_order.last
    expect(you.you).to be true
  end

  it "exposes the discard pile's top card" do
    expect(presenter.discard_top).to eq game.state.discard.top
  end

  it "exposes the active player's hand as unselected hand cards" do
    expect(presenter.hand_cards.map(&:card)).to match_array(game.state.active_player.cards)
    expect(presenter.hand_cards).to all have_attributes(selected: false)
  end

  it "exposes the current phase" do
    expect(presenter.phase).to eq "draw"
  end

  describe "#can_draw?" do
    it "is true for the active player during the draw phase" do
      expect(presenter.can_draw?).to be true
    end

    it "is false for the waiting player" do
      expect(game.presenter(waiting_user).can_draw?).to be false
    end
  end

  describe "#can_discard?" do
    it "is false during the draw phase" do
      expect(presenter.can_discard?).to be false
    end

    it "is true for the active player once in the discard phase" do
      game.state.phase = "discard"
      expect(presenter.can_discard?).to be true
    end
  end
end
