require 'rails_helper'

RSpec.describe RummyGame, type: :model do
  it "labels itself for the new-game form" do
    expect(RummyGame.label).to eq "Rummy"
  end

  it "permits only its own turn params" do
    expect(RummyGame.permitted_turn_params).to match_array([ :action, :card ])
  end

  describe "#start" do
    let(:game) { create(:game, :rummy, :has_participants, users: create_list(:user, 2)) }

    it "deals a hand to every participant" do
      game.start

      expect(game.state.players).to all have_attributes(cards: have_attributes(size: 10))
    end

    it "flips one card onto the discard" do
      game.start

      expect(game.state.discard.top).to be_a CardGame::Card
    end
  end

  describe "#play_turn" do
    let(:game) { create(:started_game, :rummy, :has_participants, users: create_list(:user, 2)) }

    it "resolves a discard's card key to the active player's actual card" do
      target_card = game.state.active_player.cards.first
      game.state.phase = "discard"

      game.play_turn(action: "discard", card: "#{target_card.rank}-#{target_card.suit}")

      expect(game.state.discard.top).to eq target_card
    end
  end

  it_behaves_like "a platform game",
    factory: :rummy,
    legal_turn: ->(game) { { action: "draw_stock" } },
    winning_turn: ->(game, winner) do
      state = game.state
      champion = state.players.find { |player| player.user_id == winner.id }
      last_card = champion.cards.first
      champion.cards = [ last_card ]
      state.turn_index = state.players.index(champion)
      state.phase = "discard"
      { action: "discard", card: "#{last_card.rank}-#{last_card.suit}" }
    end
end
