require 'rails_helper'

RSpec.describe "End of game", type: :system do
  let(:user) { create(:user) }

  describe "the modal on a finished game" do
    let(:game) { create(:finished_game, :go_fish, :user_won, :many_participants, user: user) }
    before do
      game.update!(finished_at: Time.current)
      login_user(user)
      visit game_path(game)
    end

    context "when the winner views it" do
      it "greets them with a win message" do
        expect(page).to have_text("You win")
      end

      it "offers Return to main page, View stats, and Create a new game" do
        expect(page).to have_link("Return to main page")
        expect(page).to have_link("View stats")
        expect(page).to have_link("Create a new game")
      end
    end

    context "when choosing 'Return to main page'" do
      it "returns to the main page" do
        click_on "Return to main page"
        expect(page).to have_current_path(root_path)
      end
    end

    context "when choosing 'View stats'" do
      it "opens the stats page" do
        click_on "View stats"
        expect(page).to have_current_path(stats_path)
      end
    end

    context "when choosing 'Create a new game'" do
      it "starts the new-game flow" do
        click_on "Create a new game"
        expect(page).to have_current_path(new_game_path)
      end
    end
  end

  describe "a live win by an opponent" do
    context "when another player makes the winning move", :js do
      it "shows the modal to the waiting player without a refresh" do
        skip "pending live end-of-game broadcast"
      end
    end
  end
end
