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

  it "flags hand cards the player has toggled as selected" do
    selected_card = game.state.active_player.cards.first
    game.state.active_player.selected = [ selected_card ]

    hand_card = presenter.hand_cards.find { |view| view.card == selected_card }
    expect(hand_card.selected).to be true
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

  describe "#selected_count" do
    it "counts the active player's selected cards" do
      game.state.active_player.selected = game.state.active_player.cards.first(2)
      expect(presenter.selected_count).to eq 2
    end
  end

  describe "#can_meld?" do
    it "is false during the draw phase" do
      expect(presenter.can_meld?).to be false
    end

    it "is true once a valid set or run is selected during the meld phase" do
      game.state.phase = "meld"
      game.state.active_player.selected = [
        CardGame::Card.new("9", "Hearts"), CardGame::Card.new("9", "Spades"), CardGame::Card.new("9", "Clubs")
      ]

      expect(presenter.can_meld?).to be true
    end

    it "is false when the selection isn't a valid meld" do
      game.state.phase = "meld"
      game.state.active_player.selected = [ CardGame::Card.new("9", "Hearts") ]

      expect(presenter.can_meld?).to be false
    end
  end

  describe "#can_discard?" do
    it "is false during the draw phase" do
      expect(presenter.can_discard?).to be false
    end

    it "is true once exactly one card is selected during the meld phase" do
      game.state.phase = "meld"
      game.state.active_player.selected = [ game.state.active_player.cards.first ]

      expect(presenter.can_discard?).to be true
    end

    it "is false when nothing is selected" do
      game.state.phase = "meld"
      expect(presenter.can_discard?).to be false
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
      expect(meld_view).to have_attributes(kind: "set", owner: game.state.players.last.name, cards: opponent_meld.cards)
    end

    it "labels the viewer's own meld \"you\"" do
      own_meld = Rummy::Meld.build(
        cards: [ CardGame::Card.new("4", "Hearts"), CardGame::Card.new("5", "Hearts"), CardGame::Card.new("6", "Hearts") ],
        owner: active_user.id
      )
      game.state.melds = [ own_meld ]

      expect(presenter.melds.first.owner).to eq "you"
    end

    describe "lay-off targeting" do
      let(:run) do
        Rummy::Meld.build(
          cards: [ CardGame::Card.new("4", "Hearts"), CardGame::Card.new("5", "Hearts"), CardGame::Card.new("6", "Hearts") ],
          owner: waiting_user.id
        )
      end

      before do
        game.state.melds = [ run ]
        game.state.phase = "meld"
      end

      it "is not a lay-off candidate and not faded when nothing is selected" do
        meld_view = presenter.melds.first
        expect(meld_view.can_lay_off).to be false
        expect(meld_view.faded).to be false
      end

      it "can be laid off onto when the selection legally extends it" do
        game.state.active_player.selected = [ CardGame::Card.new("7", "Hearts") ]

        meld_view = presenter.melds.first
        expect(meld_view.can_lay_off).to be true
        expect(meld_view.faded).to be false
      end

      it "is faded when the selection doesn't legally extend it" do
        game.state.active_player.selected = [ CardGame::Card.new("2", "Diamonds") ]

        meld_view = presenter.melds.first
        expect(meld_view.can_lay_off).to be false
        expect(meld_view.faded).to be true
      end
    end
  end
end
