require 'rails_helper'

RSpec.describe GameRowPresenter, type: :presenter do
  let(:user) { create(:user) }
  subject(:presenter) { described_class.new(game, user) }

  describe "a game the user has joined" do
    let(:game) { create(:game, :go_fish, :has_user, user: user) }

    it "labels the game type" do
      expect(presenter.type_label).to eq "Go Fish"
    end

    it "renders count over the type's max players" do
      expect(presenter.player_count).to eq "1/#{GoFishGame::MAX_PLAYERS}"
    end

    it "offers the view CTA" do
      expect(presenter.cta).to eq :view
    end

    context "while still waiting to start" do
      it "is not the user's turn" do
        expect(presenter.your_turn?).to be false
      end
    end
  end

  describe "the user's started game" do
    let(:game) { create(:started_game, :go_fish, :users_turn, :many_participants, user: user) }

    it "is the user's turn when the state says so" do
      expect(presenter.your_turn?).to be true
    end
  end

  describe "an open game the user has not joined" do
    let(:game) { create(:game, :crazy_eights) }

    it "offers the join CTA when there is room" do
      expect(presenter.cta).to eq :join
    end

    context "when the table is full" do
      before do
        create_list(:participant, CrazyEightsGame::MAX_PLAYERS, game: game)
        game.reload
      end

      it "reports full and offers no join" do
        expect(presenter.full?).to be true
        expect(presenter.cta).to eq :full
      end
    end
  end
end
