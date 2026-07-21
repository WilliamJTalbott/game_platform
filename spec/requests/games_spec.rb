require 'rails_helper'

RSpec.describe "Games", type: :request do
  let(:user) { create(:user) }
  before { sign_in(user) }

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
  end
end
