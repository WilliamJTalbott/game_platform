require 'rails_helper'

RSpec.describe "Playing Rummy", type: :system do
  let(:user) { create(:user) }
  let!(:game) { create(:started_game, :rummy, :users_turn, :many_participants, user: user) }

  before { login_user(user) }

  def hand_card_input(key)
    find(:xpath, "//input[@value='#{key}']", visible: :all)
  end

  def click_hand_card(key)
    find(:xpath, "//input[@value='#{key}']/parent::label").click
  end

  it "selects and deselects a hand card locally, with no server round-trip", :js do
    visit game_path(game)
    click_button "Stock"
    expect(page).to have_css(".feed-bubble", text: "drew")

    card = game.reload.state.active_player.cards.first
    key = "#{card.rank}-#{card.suit}"

    click_hand_card(key)
    expect(hand_card_input(key)).to be_checked

    click_hand_card(key)
    expect(hand_card_input(key)).not_to be_checked
  end

  it "draws from the stock, selects a card, and discards it, passing the turn", :js do
    visit game_path(game)

    click_button "Stock"
    expect(page).to have_css(".feed-bubble", text: "drew")

    card = game.reload.state.active_player.cards.first
    click_hand_card("#{card.rank}-#{card.suit}")

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

    nines.each { |card| click_hand_card("#{card.rank}-#{card.suit}") }
    click_button "Create meld"

    expect(page).to have_css(".meld .meld__kind", text: "set")
  end

  it "lays a selected card off onto an opponent's existing meld", :js do
    opponent = game.state.players.find { |player| player.user_id != user.id }
    existing_meld = Rummy::Meld.new(
      kind: "run", owner: opponent.user_id,
      cards: [ CardGame::Card.new("4", "Hearts"), CardGame::Card.new("5", "Hearts"), CardGame::Card.new("6", "Hearts") ]
    )
    layoff_card = CardGame::Card.new("7", "Hearts")
    (existing_meld.cards + [ layoff_card ]).each do |card|
      game.state.deck.cards.delete(card)
      game.state.discard.cards.delete(card)
      game.state.players.each { |player| player.cards.delete(card) }
    end
    game.state.melds = [ existing_meld ]
    game.state.active_player.cards << layoff_card
    game.save!

    visit game_path(game)
    click_button "Stock"
    expect(page).to have_css(".feed-bubble", text: "drew")

    click_hand_card("7-Hearts")
    find(".meld", text: "run").click

    expect(page).to have_css(".meld .card-container", count: 4)
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
