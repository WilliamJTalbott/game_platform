require 'rails_helper'

RSpec.describe "Turns", type: :request do
  let(:user) { create(:user) }
  before { sign_in(user) }

  describe "game-specific param permitting" do
    context "for a Go Fish game" do
      let(:game) { create(:started_game, :go_fish, :users_turn, :many_participants, user: user) }

      it "drops a foreign param belonging to another game, rather than raising" do
        opponent = (game.state.players - [ game.state.active_player ]).first
        rank = game.state.active_player.cards.first.rank

        post game_turns_path(game), params: {
          turn: { player_name: opponent.name, rank: rank, card: "A of Spades" }
        }

        expect(response).to have_http_status(:no_content)
      end
    end

    context "for a Crazy Eights game" do
      let(:game) { create(:started_game, :crazy_eights, :users_turn, :many_participants, user: user) }

      it "drops a foreign param belonging to another game, rather than raising" do
        playable = CardGame::Card.new("3", game.state.discard.active_card.suit)
        game.state.active_player.cards.unshift(playable)
        game.save!

        post game_turns_path(game), params: {
          turn: { card: playable.to_s, player_name: "anyone" }
        }

        expect(response).to have_http_status(:no_content)
      end
    end
  end

  describe "POST a turn to a finished Crazy Eights game" do
    let(:game) { create(:finished_game, :crazy_eights, :users_turn, :many_participants, user: user) }
    before { game.update!(finished_at: Time.current) }

    context "when a turn is submitted" do
      it "rejects the turn" do
        post game_turns_path(game), params: { turn: { card: "A of Spades" } }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not mutate the game state" do
        expect do
          post game_turns_path(game), params: { turn: { card: "A of Spades" } }
        end.to_not change { game.reload.state.as_json }
      end

      it "responds with the end-of-game modal instead of a raw JSON error" do
        post game_turns_path(game), params: { turn: { card: "A of Spades" } }
        expect(response.body).to include("Return to main page")
      end
    end
  end

  describe "POST a turn to a finished Go Fish game" do
    let(:game) { create(:finished_game, :go_fish, :users_turn, :many_participants, user: user) }
    before { game.update!(finished_at: Time.current) }

    context "when a further turn is submitted" do
      it "rejects the turn" do
        post game_turns_path(game), params: { turn: { player_name: "anyone", rank: "A" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
