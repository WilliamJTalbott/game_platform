require 'rails_helper'

RSpec.describe "Playing Rummy", type: :system do
  let(:user) { create(:user) }
  let!(:game) { create(:started_game, :rummy, :users_turn, :many_participants, user: user) }

  before { login_user(user) }

  it "draws from the stock, selects a card, and discards it, passing the turn", :js do
    visit game_path(game)

    click_button "Stock"
    expect(page).to have_css(".feed-bubble", text: "drew")

    find(".hand-card:not([disabled])", match: :first).click
    expect(page).to have_css(".playing-card--selected")

    click_button "Discard"
    expect(page).to have_css(".feed-bubble", text: "discarded")

    expect(page).to have_css(".pile[disabled]", match: :first)
  end

  it "melds three selected cards into a shared, public meld", :js do
    nines = [ CardGame::Card.new("9", "Hearts"), CardGame::Card.new("9", "Spades"), CardGame::Card.new("9", "Clubs") ]
    game.state.active_player.cards = nines
    game.state.deck.cards -= nines
    game.save!

    visit game_path(game)
    click_button "Stock"
    expect(page).to have_css(".feed-bubble", text: "drew")

    # Each toggle round-trips through a real turn broadcast, so give the
    # rapid-fire clicks more room than Capybara's 2s default before the next
    # card's Turbo Stream update has landed.
    Capybara.using_wait_time(5) do
      nines.each_with_index do |card, index|
        find("[data-rummy-turn-card-param='#{card.rank}-#{card.suit}']").click
        expect(page).to have_css(".playing-card--selected", count: index + 1)
      end
    end
    click_button "Create meld"

    expect(page).to have_css(".meld .meld__kind", text: "set")
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
