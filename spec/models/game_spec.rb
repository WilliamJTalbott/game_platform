require 'rails_helper'

RSpec.describe Game, type: :model do
  let(:game) { create(:game, :many_participants) }

  context "#status" do
    let(:game) { create(:game) }
    it "returns 'waiting' if game hasn't started" do
      expect(game.status).to eq 'waiting'
    end

    it "returns 'started' if game has started" do
      game.start
      expect(game.status).to eq 'started'
    end

    it "returns 'finished' if game has ended" do
      game.start
      game.finish
      expect(game.status).to eq 'finished'
    end
  end

  context "#start" do
    before { game.start }

    it "starts game" do
      expect(game.started_at).to_not be_nil
    end
    it "deals cards to players" do
      player = game.go_fish.players.first
      expect(player.cards).to_not be_empty
    end
  end

  context "#can_start?" do
    let(:empty_game) { create(:game) }

    it "returns true with 2+ participants" do
      expect(game.can_start?).to be true
    end

    it "returns false with no participants" do
      expect(empty_game.can_start?).to be false
    end
  end

  context "#action" do
    before do
      game.start
      game.go_fish.players.last.name = "Toast"
      game.go_fish.players.last.cards = []
    end

    it "it runs a turn" do
      expect { game.play_turn("Toast", "A") }.to change { game.go_fish.deck.cards.size }
    end

  end

  context "#player_from_user" do
    let(:user) { create(:user) }

    before do
      game.start
      game.go_fish.players.last.user_id = user.id
    end

    it "gets proper player" do
      player = game.player_from_user(user)

      expect(player).to be_a(GoFish::Player)
      expect(player.user_id).to eq user.id
    end
  end

  context "#opponents" do
    let(:user) { create(:user) }

    before do
      game.start
      game.go_fish.players.last.user_id = user.id
    end

    it "gets proper player" do
      player = game.player_from_user(user)
      opponents = game.opponents(user)

      expect(opponents).to_not be_empty
      expect(opponents).not_to include(player)
    end
  end

end
