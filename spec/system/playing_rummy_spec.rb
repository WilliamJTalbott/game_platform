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

  def draw_from_stock!
    visit game_path(game)
    click_button "Stock"
    expect(page).to have_css(".feed-bubble", text: "drew")
  end

  def drawn_card_key
    card = game.reload.state.active_player.cards.first
    "#{card.rank}-#{card.suit}"
  end

  def remove_cards_from_play(*cards)
    cards.each do |card|
      game.state.deck.cards.delete(card)
      game.state.discard.cards.delete(card)
      game.state.players.each { |player| player.cards.delete(card) }
    end
  end

  it "selects and deselects a hand card locally, with no server round-trip", :js do
    draw_from_stock!
    key = drawn_card_key

    click_hand_card(key)
    expect(hand_card_input(key)).to be_checked

    click_hand_card(key)
    expect(hand_card_input(key)).not_to be_checked
  end

  it "draws from the stock, selects a card, and discards it, passing the turn", :js do
    draw_from_stock!
    click_hand_card(drawn_card_key)

    find(".pile", text: "Discard").click
    expect(page).to have_css(".feed-bubble", text: "discarded")
    expect(page).to have_css(".pile[disabled]", match: :first)
  end

  it "only enables the discard pile once exactly one card is selected", :js do
    draw_from_stock!
    expect(page).to have_css(".pile[disabled]", text: "Discard")

    click_hand_card(drawn_card_key)
    expect(page).to have_no_css(".pile[disabled]", text: "Discard")
  end

  it "highlights both Meld and Discard once exactly one card is selected, since either is legal", :js do
    draw_from_stock!
    expect(page).to have_css(".phase-stepper__step--active", text: "Meld")
    expect(page).to have_no_css(".phase-stepper__step--active", text: "Discard")

    click_hand_card(drawn_card_key)
    expect(page).to have_css(".phase-stepper__step--active", text: "Meld")
    expect(page).to have_css(".phase-stepper__step--active", text: "Discard")
  end

  context "with a meldable set in hand" do
    let(:nines) { [ CardGame::Card.new("9", "Hearts"), CardGame::Card.new("9", "Spades"), CardGame::Card.new("9", "Clubs") ] }

    before do
      game.state.active_player.cards = nines
      game.state.deck.cards -= nines
      game.save!
    end

    it "melds three selected cards into a shared, public meld", :js do
      draw_from_stock!
      nines.each { |card| click_hand_card("#{card.rank}-#{card.suit}") }
      find(".meld--new").click

      expect(page).to have_css(".meld .meld__label", text: "Set · 9")
    end

    it "only reveals the meld placeholder once three or more cards are selected", :js do
      draw_from_stock!
      expect(page).to have_no_css(".meld--new")

      nines.first(2).each { |card| click_hand_card("#{card.rank}-#{card.suit}") }
      expect(page).to have_no_css(".meld--new")

      click_hand_card("#{nines.third.rank}-#{nines.third.suit}")
      expect(page).to have_css(".meld--new")

      click_hand_card("#{nines.third.rank}-#{nines.third.suit}")
      expect(page).to have_no_css(".meld--new")
    end
  end

  context "with a card that extends an opponent's meld" do
    let(:opponent) { game.state.players.find { |player| player.user_id != user.id } }
    let(:existing_meld) do
      Rummy::Meld.new(
        kind: "run", owner: opponent.user_id,
        cards: [ CardGame::Card.new("4", "Hearts"), CardGame::Card.new("5", "Hearts"), CardGame::Card.new("6", "Hearts") ]
      )
    end
    let(:layoff_card) { CardGame::Card.new("7", "Hearts") }
    # A player must own a meld before laying off onto anyone else's.
    let(:own_meld) do
      Rummy::Meld.new(
        kind: "set", owner: user.id,
        cards: [ CardGame::Card.new("9", "Hearts"), CardGame::Card.new("9", "Spades"), CardGame::Card.new("9", "Clubs") ]
      )
    end

    before do
      remove_cards_from_play(*existing_meld.cards, *own_meld.cards, layoff_card)
      game.state.melds = [ existing_meld, own_meld ]
      game.state.active_player.cards << layoff_card
      game.save!
    end

    it "lays a selected card off onto an opponent's existing meld", :js do
      draw_from_stock!
      click_hand_card("7-Hearts")
      find(".meld", text: "Run").click

      expect(find(".meld", text: "Run")).to have_css(".meld__card", count: 4)
    end

    it "only enables an existing meld once at least one card is selected", :js do
      draw_from_stock!
      expect(page).to have_css(".meld[disabled]", text: "Run")

      click_hand_card("7-Hearts")
      expect(page).to have_no_css(".meld[disabled]", text: "Run")
    end
  end

  context "with only the winning meld left in hand" do
    let(:four) { CardGame::Card.new("4", "Hearts") }
    let(:five) { CardGame::Card.new("5", "Hearts") }
    let(:six) { CardGame::Card.new("6", "Hearts") }

    before do
      remove_cards_from_play(four, five, six)
      game.state.active_player.cards = [ four, five ]
      game.state.deck.cards << six
      game.save!
    end

    it "goes out by melding the last cards in hand, ending the game", :js do
      draw_from_stock!
      [ four, five, six ].each { |card| click_hand_card("#{card.rank}-#{card.suit}") }
      find(".meld--new").click

      expect(page).to have_css(".end-of-game-modal", text: "You win")
    end
  end

  context "after drawing a card from the discard pile" do
    let(:drawn) { CardGame::Card.new("K", "Diamonds") }

    before do
      remove_cards_from_play(drawn)
      game.state.discard.cards = [ drawn ]
      game.save!
    end

    it "marks the drawn card locked and keeps it from being discarded", :js do
      visit game_path(game)
      find(".pile", text: "Discard").click
      expect(page).to have_css(".feed-bubble", text: "drew")

      expect(page).to have_css(".hand-card--locked .hand-card__lock")
      screenshot("rummy-locked-card", fullPage: true)

      click_hand_card("K-Diamonds")
      expect(page).to have_css(".pile[disabled]", text: "Discard")
    end
  end

  context "when the selected cards don't form a run or a set" do
    let(:mismatched) do
      [ CardGame::Card.new("9", "Hearts"), CardGame::Card.new("2", "Spades"), CardGame::Card.new("7", "Clubs") ]
    end

    before do
      remove_cards_from_play(*mismatched)
      game.state.active_player.cards = mismatched + game.state.active_player.cards
      game.save!
    end

    it "drops a flash naming the reason instead of failing silently", :js do
      page.driver.with_playwright_page { |p| p.emulate_media(colorScheme: "dark") }
      draw_from_stock!
      mismatched.each { |card| click_hand_card("#{card.rank}-#{card.suit}") }
      find(".meld--new").click

      expect(page).to have_css(".popup.show", text: "Select 3 or more cards that form a run or set")
      screenshot("rummy-invalid-meld-flash", fullPage: true)

      # Slides back out on its own — `visible: true` so this asserts the notice
      # really is hidden, not merely that the selector stopped matching.
      expect(page).to have_no_css(".popup", visible: true, wait: 6)
    end
  end

  it "keeps meld-phase state after reloading the page mid-turn", :js do
    draw_from_stock!
    key = drawn_card_key

    visit game_path(game)

    expect(hand_card_input(key)).to be_present
    expect(page).to have_css(".pile[disabled]", match: :first)
  end

  context "with an unsorted hand" do
    let(:unsorted) do
      [ CardGame::Card.new("K", "Hearts"), CardGame::Card.new("2", "Clubs"), CardGame::Card.new("A", "Spades") ]
    end

    before do
      remove_cards_from_play(*unsorted)
      game.state.active_player.cards = unsorted
      game.save!
    end

    def hand_card_keys
      page.all(".hand-card__input", visible: :all).map { |input| input[:value] }
    end

    it "sorts the hand ace-low by rank", :js do
      page.driver.with_playwright_page { |p| p.emulate_media(colorScheme: "dark") }
      visit game_path(game)
      click_button "By rank"

      expect(hand_card_keys).to eq %w[A-Spades 2-Clubs K-Hearts]
      screenshot("rummy-hand-sorted-by-rank", fullPage: true)
    end

    it "sorts the hand by suit, ace-high within suit", :js do
      visit game_path(game)
      click_button "By suit"

      expect(hand_card_keys).to eq %w[K-Hearts A-Spades 2-Clubs]
    end

    it "keeps the chosen sort across a fresh page load", :js do
      visit game_path(game)
      click_button "By rank"

      visit game_path(game)
      expect(hand_card_keys).to eq %w[A-Spades 2-Clubs K-Hearts]
    end
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
