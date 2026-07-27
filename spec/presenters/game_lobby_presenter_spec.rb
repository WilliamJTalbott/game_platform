require 'rails_helper'

RSpec.describe GameLobbyPresenter, type: :presenter do
  let(:host_user) { create(:user, name: "Will") }
  let(:guest_user) { create(:user, name: "Ana") }
  subject(:presenter) { described_class.new(game, viewer) }

  describe "a freshly created game" do
    let(:game) { create(:game, :rummy, :has_user, user: host_user, name: "Will's Rummy Game") }
    let(:viewer) { host_user }

    it "exposes the name and type label" do
      expect(presenter.name).to eq "Will's Rummy Game"
      expect(presenter.type_label).to eq "Rummy"
    end

    it "renders the seat count" do
      expect(presenter.player_count).to eq "1/#{RummyGame::MAX_PLAYERS}"
    end

    it "counts the seats still open" do
      expect(presenter.open_seats).to eq RummyGame::MAX_PLAYERS - 1
    end

    it "lists the host as a roster row" do
      row = presenter.players.first
      expect(row.name).to eq "Will"
      expect(row.host?).to be true
    end

    it "identifies the host" do
      expect(presenter.host?).to be true
    end

    it "cannot start yet" do
      expect(presenter.can_start?).to be false
      expect(presenter.start_enabled?).to be false
    end

    it "labels the start action with what the lobby is waiting on" do
      expect(presenter.start_label).to eq "Waiting for players…"
    end

    it "builds an invite url" do
      expect(presenter.invite_url).to eq Rails.application.routes.url_helpers.game_url(game)
    end
  end

  describe "a game with two players, viewed by the host" do
    let(:game) { create(:game, :rummy, :has_user, user: host_user).tap { |g| create(:participant, game: g, user: guest_user) } }
    let(:viewer) { host_user }

    it "marks the viewer's own row" do
      row = presenter.players.find { |player| player.name == "Will" }
      expect(row.you?).to be true
    end

    it "is ready to start" do
      expect(presenter.can_start?).to be true
      expect(presenter.start_enabled?).to be true
    end

    it "labels the start action as the action itself" do
      expect(presenter.start_label).to eq "Start Game"
    end
  end

  describe "a game with two players, viewed by a guest" do
    let(:game) { create(:game, :rummy, :has_user, user: host_user).tap { |g| create(:participant, game: g, user: guest_user) } }
    let(:viewer) { guest_user }

    it "does not identify the viewer as host" do
      expect(presenter.host?).to be false
    end

    it "cannot use the start button" do
      expect(presenter.start_enabled?).to be false
    end

    it "labels the start action as waiting on the host" do
      expect(presenter.start_label).to eq "Waiting for the host…"
    end
  end

  describe "a full lobby" do
    let(:game) { create(:game, :crazy_eights, :has_user, user: host_user) }
    let(:viewer) { host_user }

    before { create_list(:participant, CrazyEightsGame::MAX_PLAYERS - 1, game: game) }

    it "is still startable" do
      expect(presenter.start_label).to eq "Start Game"
      expect(presenter.start_enabled?).to be true
    end

    it "leaves no seats open" do
      expect(presenter.open_seats).to eq 0
    end
  end
end
