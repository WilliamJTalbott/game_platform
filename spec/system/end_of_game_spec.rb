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

      it "offers Return to main page, View stats, and New Game" do
        expect(page).to have_link("Return to main page")
        expect(page).to have_link("View stats")
        expect(page).to have_link("New Game")
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

    context "when choosing 'New Game'" do
      it "starts the new-game flow" do
        click_on "New Game"
        expect(page).to have_current_path(new_game_path)
      end
    end

    context "when choosing 'Return to main page' with Turbo enabled", :js do
      it "navigates the whole page, not just the modal's turbo frame" do
        click_on "Return to main page"
        expect(page).to have_current_path(root_path)
      end
    end
  end
end
