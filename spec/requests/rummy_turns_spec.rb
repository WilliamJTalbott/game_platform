require 'rails_helper'

RSpec.describe "Rummy turns", type: :request do
  let(:active_user) { create(:user) }
  let(:waiting_user) { create(:user) }
  let(:game) do
    create(:started_game, :rummy, :users_turn, :has_participants, user: active_user, users: [ waiting_user ])
  end

  context "when the active player draws then discards" do
    before { sign_in(active_user) }

    it "draws from the stock and moves to the meld phase" do
      post game_turns_path(game), params: { turn: { action: "draw_stock" } }

      expect(response).to have_http_status(:no_content)
      expect(game.reload.state.phase).to eq "meld"
    end

    it "discards the selected card and advances the turn back to the draw phase" do
      post game_turns_path(game), params: { turn: { action: "draw_stock" } }
      card = game.reload.state.active_player.cards.first

      post game_turns_path(game), params: { turn: { action: "toggle_select", card: "#{card.rank}-#{card.suit}" } }
      post game_turns_path(game), params: { turn: { action: "discard" } }

      expect(response).to have_http_status(:no_content)
      expect(game.reload.state.phase).to eq "draw"
    end
  end

  context "when the active player melds a valid set" do
    before do
      sign_in(active_user)
      game.state.active_player.cards =
        [ CardGame::Card.new("9", "Hearts"), CardGame::Card.new("9", "Spades"), CardGame::Card.new("9", "Clubs") ] +
        game.state.active_player.cards
      game.save!
    end

    it "creates a shared meld and stays in the meld phase" do
      post game_turns_path(game), params: { turn: { action: "draw_stock" } }
      %w[Hearts Spades Clubs].each do |suit|
        post game_turns_path(game), params: { turn: { action: "toggle_select", card: "9-#{suit}" } }
      end
      post game_turns_path(game), params: { turn: { action: "meld" } }

      expect(response).to have_http_status(:no_content)
      expect(game.reload.state.melds.size).to eq 1
      expect(game.state.phase).to eq "meld"
    end
  end

  context "when the active player lays a card off onto an opponent's meld" do
    let(:existing_meld) do
      Rummy::Meld.new(
        kind: "run", owner: waiting_user.id,
        cards: [ CardGame::Card.new("4", "Hearts"), CardGame::Card.new("5", "Hearts"), CardGame::Card.new("6", "Hearts") ]
      )
    end

    before do
      sign_in(active_user)
      game.state.melds = [ existing_meld ]
      game.state.active_player.cards << CardGame::Card.new("7", "Hearts")
      game.save!
    end

    it "extends the meld and stays in the meld phase" do
      post game_turns_path(game), params: { turn: { action: "draw_stock" } }
      post game_turns_path(game), params: { turn: { action: "toggle_select", card: "7-Hearts" } }
      post game_turns_path(game), params: { turn: { action: "lay_off", meld_index: "0" } }

      expect(response).to have_http_status(:no_content)
      expect(game.reload.state.melds.first.cards).to include(CardGame::Card.new("7", "Hearts"))
      expect(game.state.phase).to eq "meld"
    end
  end

  context "when it is not the active player's turn" do
    before { sign_in(waiting_user) }

    it "rejects the turn" do
      post game_turns_path(game), params: { turn: { action: "draw_stock" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  context "when drawing from an empty discard pile" do
    before do
      sign_in(active_user)
      game.state.discard.cards = []
      game.save!
    end

    it "rejects the draw" do
      post game_turns_path(game), params: { turn: { action: "draw_discard" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  context "when discarding before drawing" do
    before { sign_in(active_user) }

    it "rejects the discard" do
      post game_turns_path(game), params: { turn: { action: "discard" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
