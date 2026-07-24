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

  it "exposes the active player's hand as hand cards" do
    expect(presenter.hand_cards.map(&:card)).to match_array(game.state.active_player.cards)
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

  describe "#melds" do
    it "resolves the owning player's name, labeling the viewer's own melds \"you\"" do
      opponent_meld = Rummy::Meld.build(
        cards: [ CardGame::Card.new("9", "Hearts"), CardGame::Card.new("9", "Spades"), CardGame::Card.new("9", "Clubs") ],
        owner: game.state.players.last.user_id
      )
      game.state.melds = [ opponent_meld ]
      meld_view = presenter.melds.first

      expect(meld_view).to have_attributes(label: "Set · 9", owner: game.state.players.last.name, cards: opponent_meld.cards)
    end

    it "labels a run with its shared suit glyph" do
      run = [ CardGame::Card.new("4", "Diamonds"), CardGame::Card.new("5", "Diamonds"), CardGame::Card.new("6", "Diamonds") ]
      game.state.melds = [ Rummy::Meld.build(cards: run, owner: game.state.players.last.user_id) ]

      expect(presenter.melds.first.label).to eq "Run · ♦"
    end

    it "labels the viewer's own meld \"you\"" do
      own_meld = Rummy::Meld.build(
        cards: [ CardGame::Card.new("4", "Hearts"), CardGame::Card.new("5", "Hearts"), CardGame::Card.new("6", "Hearts") ],
        owner: active_user.id
      )
      game.state.melds = [ own_meld ]

      expect(presenter.melds.first.owner).to eq "you"
    end
  end
end
