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

      post game_turns_path(game), params: { turn: { action: "discard", cards: [ "#{card.rank}-#{card.suit}" ] } }

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
      post game_turns_path(game), params: { turn: { action: "meld", cards: %w[9-Hearts 9-Spades 9-Clubs] } }

      expect(response).to have_http_status(:no_content)
      expect(game.reload.state.melds.size).to eq 1
      expect(game.state.phase).to eq "meld"
    end
  end

  context "when the active player selects cards that don't form a meld" do
    before do
      sign_in(active_user)
      game.state.active_player.cards =
        [ CardGame::Card.new("9", "Hearts"), CardGame::Card.new("2", "Spades"), CardGame::Card.new("7", "Clubs") ] +
        game.state.active_player.cards
      game.save!
    end

    it "rejects the meld" do
      post game_turns_path(game), params: { turn: { action: "draw_stock" } }
      post game_turns_path(game), params: { turn: { action: "meld", cards: %w[9-Hearts 2-Spades 7-Clubs] } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(game.reload.state.melds).to be_empty
    end

    it "flashes the reason the meld was rejected" do
      post game_turns_path(game), params: { turn: { action: "draw_stock" } }
      post game_turns_path(game), params: { turn: { action: "meld", cards: %w[9-Hearts 2-Spades 7-Clubs] } }

      expect(response.body).to include("Select 3 or more cards that form a run or set")
    end
  end

  context "when the active player lays a card off onto an opponent's meld" do
    let(:existing_meld) do
      Rummy::Meld.new(
        kind: "run", owner: waiting_user.id,
        cards: [ CardGame::Card.new("4", "Hearts"), CardGame::Card.new("5", "Hearts"), CardGame::Card.new("6", "Hearts") ]
      )
    end
    # A player must have laid down a meld of their own before laying off.
    let(:own_meld) do
      Rummy::Meld.new(
        kind: "set", owner: active_user.id,
        cards: [ CardGame::Card.new("9", "Hearts"), CardGame::Card.new("9", "Spades"), CardGame::Card.new("9", "Clubs") ]
      )
    end

    before do
      sign_in(active_user)
      game.state.melds = [ existing_meld, own_meld ]
      game.state.active_player.cards << CardGame::Card.new("7", "Hearts")
      game.save!
    end

    it "extends the meld and stays in the meld phase" do
      post game_turns_path(game), params: { turn: { action: "draw_stock" } }
      post game_turns_path(game), params: { turn: { action: "lay_off", cards: [ "7-Hearts" ], meld_index: "0" } }

      expect(response).to have_http_status(:no_content)
      expect(game.reload.state.melds.first.cards).to include(CardGame::Card.new("7", "Hearts"))
      expect(game.state.phase).to eq "meld"
    end
  end

  context "when the active player lays off before laying down a meld of their own" do
    let(:opponent_meld) do
      Rummy::Meld.new(
        kind: "run", owner: waiting_user.id,
        cards: [ CardGame::Card.new("4", "Hearts"), CardGame::Card.new("5", "Hearts"), CardGame::Card.new("6", "Hearts") ]
      )
    end

    before do
      sign_in(active_user)
      game.state.melds = [ opponent_meld ]
      game.state.active_player.cards << CardGame::Card.new("7", "Hearts")
      game.save!
    end

    it "flashes the reason the lay off was rejected" do
      post game_turns_path(game), params: { turn: { action: "draw_stock" } }
      post game_turns_path(game), params: { turn: { action: "lay_off", cards: [ "7-Hearts" ], meld_index: "0" } }

      expect(response.body).to include("Lay down a meld of your own before laying off")
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
