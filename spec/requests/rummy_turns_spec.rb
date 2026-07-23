require 'rails_helper'

RSpec.describe "Rummy turns", type: :request do
  let(:active_user) { create(:user) }
  let(:waiting_user) { create(:user) }
  let(:game) do
    create(:started_game, :rummy, :users_turn, :has_participants, user: active_user, users: [ waiting_user ])
  end

  context "when the active player draws then discards" do
    before { sign_in(active_user) }

    it "draws from the stock and moves to the discard phase" do
      post game_turns_path(game), params: { turn: { action: "draw_stock" } }

      expect(response).to have_http_status(:no_content)
      expect(game.reload.state.phase).to eq "discard"
    end

    it "discards and advances the turn back to the draw phase" do
      post game_turns_path(game), params: { turn: { action: "draw_stock" } }
      card = game.reload.state.active_player.cards.first

      post game_turns_path(game), params: { turn: { action: "discard", card: "#{card.rank}-#{card.suit}" } }

      expect(response).to have_http_status(:no_content)
      expect(game.reload.state.phase).to eq "draw"
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
      card = game.state.active_player.cards.first

      post game_turns_path(game), params: { turn: { action: "discard", card: "#{card.rank}-#{card.suit}" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
