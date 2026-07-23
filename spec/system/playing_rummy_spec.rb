require 'rails_helper'

RSpec.describe "Playing Rummy", type: :system do
  let(:user) { create(:user) }
  let!(:game) { create(:started_game, :rummy, :users_turn, :many_participants, user: user) }

  before { login_user(user) }

  it "draws from the stock, then discards, passing the turn", :js do
    visit game_path(game)

    click_button "Stock"
    expect(page).to have_css(".feed-bubble", text: "drew")

    find(".hand-card:not([disabled])", match: :first).click
    expect(page).to have_css(".feed-bubble", text: "discarded")

    expect(page).to have_css(".pile[disabled]", match: :first)
  end

  context "when it is not the user's turn" do
    before do
      game.state.turn_index = 1
      game.save!
    end

    it "does not allow the user to draw" do
      visit game_path(game)
      expect(page).to have_css(".pile[disabled]", match: :first)
    end
  end
end
