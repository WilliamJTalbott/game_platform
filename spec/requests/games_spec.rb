require 'rails_helper'

RSpec.describe "Games", type: :request do
  let(:user) { create(:user) }
  before { sign_in(user) }

  describe "POST create" do
    context "with a registered game type" do
      it "creates a Go Fish game" do
        post games_path, params: { game: { name: "My Game", type: "GoFishGame" } }
        expect(Game.last).to be_a GoFishGame
      end

      it "creates a Crazy Eights game" do
        post games_path, params: { game: { name: "My Game", type: "CrazyEightsGame" } }
        expect(Game.last).to be_a CrazyEightsGame
      end
    end

    context "with an unregistered game type" do
      it "does not create a game" do
        expect do
          post games_path, params: { game: { name: "My Game", type: "DeleteAllUsers" } }
        end.to_not change { Game.count }
      end

      it "renders the new form again" do
        post games_path, params: { game: { name: "My Game", type: "DeleteAllUsers" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET the lobby" do
    let(:open_games) { Nokogiri::HTML(response.body).at_css("#games").text }

    before do
      create(:game, :has_user, user: user, name: "Joined Game")
      create(:game, name: "Open Game")
      create(:deleted_game, name: "Deleted Game")
      create(:started_game, :many_participants, name: "Started Game")
      get games_path
    end

    it "greets the signed-in user" do
      expect(response.body).to include("Welcome back, #{user.name}")
    end

    it "lists only waiting games the user has not joined as open" do
      expect(open_games).to include("Open Game")
      expect(open_games).to_not include("Joined Game", "Deleted Game", "Started Game")
    end
  end

  describe "the Your turn badge" do
    context "when it is the viewer's turn in their started game" do
      before do
        create(:started_game, :go_fish, :users_turn, :many_participants, user: user)
        get games_path
      end

      it "renders the badge" do
        expect(response.body).to include("Your turn")
      end

      it "marks the row as the live one" do
        expect(response.body).to include("game-card--your-turn")
      end
    end

    context "when the viewer's game has not started" do
      before do
        create(:game, :go_fish, :has_user, user: user)
        get games_path
      end

      it "leaves the row unmarked" do
        expect(response.body).to_not include("game-card--your-turn")
      end
    end
  end

  describe "row ownership" do
    context "when the viewer has both a live game and an idle one" do
      before do
        create(:started_game, :go_fish, :users_turn, :many_participants, user: user)
        create(:game, :crazy_eights, :has_user, user: user)
        get games_path
      end

      it "marks both rows as theirs, not only the live one" do
        expect(response.body.scan("game-card--mine").size).to eq 2
      end
    end

    context "when the game belongs to someone else" do
      before do
        create(:game, :go_fish)
        get games_path
      end

      it "leaves the row unmarked" do
        expect(response.body).to_not include("game-card--mine")
      end
    end
  end

  describe "POST join a full game" do
    let(:game) { create(:game, :crazy_eights) }
    before { create_list(:participant, CrazyEightsGame::MAX_PLAYERS, game: game) }

    it "does not add the user" do
      expect do
        post game_participants_path(game)
      end.to_not change { game.participants.count }
    end
  end

  describe "POST start" do
    context "when the current user is not the host" do
      let(:game) { create(:game, :go_fish, :many_participants) }

      it "redirects without starting the game" do
        post start_game_path(game)
        expect(game.reload.started_at).to be_nil
        expect(response).to redirect_to game_path(game)
      end
    end

    context "when the host starts with fewer than 2 players" do
      let(:game) { create(:game, :go_fish, :has_user, user: user) }

      it "redirects with an alert instead of crashing" do
        post start_game_path(game)
        expect(game.reload.started_at).to be_nil
        expect(response).to redirect_to game_path(game)
      end
    end

    context "when the host starts with 2+ players" do
      let(:game) { create(:game, :go_fish, :has_user, :many_participants, user: user) }

      it "starts the game" do
        post start_game_path(game)
        expect(game.reload.started_at).to be_present
      end
    end
  end

  describe "GET a game's show page" do
    context "when the game is finished" do
      let(:game) { create(:finished_game, :go_fish, :user_won, :many_participants, user: user) }
      before { game.update!(finished_at: Time.current) }

      it "renders the end-of-game modal with its next-step actions" do
        get game_path(game)

        expect(response.body).to include("Return to main page")
          .and include("View stats")
          .and include("New Game")
      end

      it "greets the winning viewer with a win message" do
        get game_path(game)
        expect(response.body).to include("You win")
      end
    end

    context "when the game is still in progress" do
      let(:game) { create(:started_game, :go_fish, :users_turn, :many_participants, user: user) }

      it "does not render the end-of-game modal" do
        get game_path(game)
        expect(response.body).to_not include("Return to main page")
      end
    end

    context "when the viewer is not yet a participant" do
      context "and the game has room" do
        let(:game) { create(:game, :go_fish) }

        it "joins the viewer as a participant" do
          expect { get game_path(game) }.to change { game.participants.count }.by(1)
          expect(game.users.reload).to include(user)
        end

        it "renders the waiting room" do
          get game_path(game)
          expect(response.body).to include(game.name)
        end
      end

      context "and the game is full" do
        let(:game) { create(:game, :crazy_eights) }
        before { create_list(:participant, CrazyEightsGame::MAX_PLAYERS, game: game) }

        it "does not add the viewer" do
          expect { get game_path(game) }.to_not change { game.participants.count }
        end

        it "redirects to the root path" do
          get game_path(game)
          expect(response).to redirect_to root_path
        end
      end

      context "and the game has already started" do
        let(:game) { create(:started_game, :go_fish, :many_participants) }

        it "does not add the viewer" do
          expect { get game_path(game) }.to_not change { game.participants.count }
        end

        it "redirects to the root path" do
          get game_path(game)
          expect(response).to redirect_to root_path
        end
      end
    end
  end
end
