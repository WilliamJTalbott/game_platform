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

    it "lists the host as a roster row" do
      row = presenter.players.first
      expect(row.name).to eq "Will"
      expect(row.host?).to be true
    end

    it "identifies the host" do
      expect(presenter.host_name).to eq "Will"
      expect(presenter.host?).to be true
    end

    it "cannot start yet" do
      expect(presenter.can_start?).to be false
      expect(presenter.show_start?).to be false
    end

    it "reports the waiting-for-more-players status" do
      expect(presenter.status_line).to eq "Waiting for more players…"
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
      expect(presenter.status_line).to eq "Ready when you are."
    end

    it "shows the start button" do
      expect(presenter.show_start?).to be true
    end
  end

  describe "a game with two players, viewed by a guest" do
    let(:game) { create(:game, :rummy, :has_user, user: host_user).tap { |g| create(:participant, game: g, user: guest_user) } }
    let(:viewer) { guest_user }

    it "does not identify the viewer as host" do
      expect(presenter.host?).to be false
    end

    it "hides the start button" do
      expect(presenter.show_start?).to be false
    end

    it "names the host in the status line" do
      expect(presenter.status_line).to eq "Waiting for Will to start…"
    end
  end

  describe "a full lobby" do
    let(:game) { create(:game, :crazy_eights, :has_user, user: host_user) }
    let(:viewer) { host_user }

    before { create_list(:participant, CrazyEightsGame::MAX_PLAYERS - 1, game: game) }

    it "reports the lobby is full" do
      expect(presenter.status_line).to eq "Lobby is full."
    end
  end
end
