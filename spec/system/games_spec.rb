require 'rails_helper'
RSpec.describe 'Games', type: :system do
  let(:user) { create(:user) }
  before { login_user(user) }

  context "[ Create ]" do
    let(:name) { "Test Game" }

    it "lets user create a game" do
      click_on "New Game"
      fill_in "Name", with: name

      expect do
        click_on "Create Game"
      end.to change(Game, :count).by 1
    end

    it "lets user create go_fish type" do
      click_on "New Game"
      select "Go Fish", from: "Type"

      expect do
        click_on "Create Game"
      end.to change(Game, :count).by 1

      last_game = Game.last
      expect(last_game).to be_an_instance_of(GoFishGame)
    end

    it "lets user create crazy_eights type" do
      click_on "New Game"
      select "Crazy Eights", from: "Type"

      expect do
        click_on "Create Game"
      end.to change(Game, :count).by 1

      last_game = Game.last
      expect(last_game).to be_an_instance_of(CrazyEightsGame)
    end
  end

  context "[ Join ]" do
    let!(:game) { create(:game) }

    it "lets user join a game" do
      visit games_path

      expect do
        click_on "Join"
      end.to change(game.participants, :count).by 1
    end
  end

  context "[ View ]" do
    context "go_fish game" do
      let!(:game) { create(:game, :go_fish, :has_user, user: user) }

      it "lets user view a game" do
        visit games_path
        click_on "View"

        expect(page).to have_current_path(game_path(game))
        expect(page).to have_content("Books")
      end
    end

    context "crazy_eights game" do
      let!(:game) { create(:game, :crazy_eights, :has_user, user: user) }

      it "lets user view a game" do
        visit games_path
        click_on "View"

        expect(page).to have_current_path(game_path(game))
        expect(page).to have_content("Table")
      end
    end
  end

  context "[ Start ]" do
    context "go_fish game" do
      let!(:game) { create(:game, :go_fish, :has_user, :many_participants, user: user) }
      it "lets user start a game" do
        visit game_path(game)
        click_on "Start Game"
        expect(page).to_not have_content("Waiting for players...")
        expect(page).to have_http_status(:ok)
      end
    end

    context "crazy_eights game" do
      let!(:game) { create(:game, :crazy_eights, :has_user, :many_participants, user: user) }
      it "lets user start a game" do
        visit game_path(game)
        click_on "Start Game"
        expect(page).to_not have_content("Waiting for players...")
        expect(page).to have_http_status(:ok)
      end
    end
  end

  context "[ Turn ]" do
    context "go_fish game" do
      let!(:game) { create(:started_game, :go_fish, :users_turn, :many_participants, user: user) }

      around do |example|
        original = GamePresenter.wait_time
        example.run
        GamePresenter.wait_time = original
      end

      it "automatically takes a turn when the timer expires", :js do
        GamePresenter.wait_time = 0.1

        visit game_path(game)
        expect(page).to have_css(".message", text: "asked")
      end

      it "allows user to take a turn", :js do
        visit game_path(game)
        click_button "Ask for card"
        expect(page).to have_css(".message", text: "asked")
      end

      context "When not users turn" do
        before do
          game.state.turn_index = 1
          game.save
        end
        it "does not allow user to take a turn" do
          visit game_path(game)
          expect(page).to have_button('Ask for card', disabled: true)
        end
      end
    end

    context "crazy_eights game" do
      let!(:game) { create(:started_game, :crazy_eights, :users_turn, :many_participants, user: user) }

      before do
        player = game.player_from_user(user)
        player.cards = [
          CardGame::Card.new("A", "Spades"),
          CardGame::Card.new("3", "Clubs")
        ]
        game.state.discard.active_card = CardGame::Card.new("2", "Spades")
        game.save!
      end

      it "allows user to take a turn", :js do
        visit game_path(game)
        click_button "Play card"
        expect(page).to have_css(".message", text: "played")
      end

      context "When not users turn" do
        before do
          game.state.turn_index = 1
          game.save
        end
        it "does not allow user to take a turn" do
          visit game_path(game)
          expect(page).to have_button('Play card', disabled: true)
        end
      end
    end
  end

  context "[ Books ]" do
    context "go_fish game" do
      let!(:game) { create(:started_game, :go_fish, :users_turn, :many_participants, user: user) }

      before do
        player = game.player_from_user(user)
        opponent = (game.state.players - [ player ]).first
        player.books = [ GoFish::Book.new("3") ]
        opponent.books = [ GoFish::Book.new("7") ]
        game.save!
      end

      it "shows completed books as card art for the player and their opponents" do
        visit game_path(game)

        expect(page).to have_css(".panel--books img[src*='3_spades']")
        expect(page).to have_css(".expanded__books img[src*='7_spades']", visible: :all)
      end
    end
  end

  context "[ Responsive ]" do
    context "go_fish game on a narrow viewport" do
      let!(:game) { create(:started_game, :go_fish, :users_turn, :many_participants, user: user) }

      it "does not let the sidebar crowd out the main content", :js do
        resize_page(375, 700) do
          visit game_path(game)

          sidebar_width = page.evaluate_script("document.querySelector('.sidebar').getBoundingClientRect().width")
          main_width = page.evaluate_script("document.querySelector('.op-page__main').getBoundingClientRect().width")

          expect(main_width).to be > sidebar_width
        end
      end

      it "stacks the board, hand, and feed panels in a single column", :js do
        resize_page(375, 700) do
          visit game_path(game)

          board_bottom = page.evaluate_script("document.querySelector('.panel--board').getBoundingClientRect().bottom")
          hand_top = page.evaluate_script("document.querySelector('.panel--hand').getBoundingClientRect().top")
          feed_top = page.evaluate_script("document.querySelector('.panel--feed').getBoundingClientRect().top")

          expect(hand_top).to be >= board_bottom
          expect(feed_top).to be >= board_bottom
        end
      end

      it "keeps the move form's selects and submit button tappable", :js do
        resize_page(375, 700) do
          visit game_path(game)

          expect(page).to have_select("turn_player_name")
          expect(page).to have_select("turn_rank")
          expect(page).to have_button("Ask for card")
        end
      end

      it "keeps the hand un-clipped so a hovered card can lift past the row", :js do
        resize_page(375, 700) do
          visit game_path(game)

          overflow_x = page.evaluate_script(
            "getComputedStyle(document.querySelector('.panel--hand .panel__body')).overflowX"
          )

          expect(overflow_x).to eq "visible"
        end
      end
    end
  end

  context "[ Card overlap ]" do
    context "go_fish game" do
      let!(:game) { create(:started_game, :go_fish, :users_turn, :many_participants, user: user) }

      it "overlaps hand cards by a consistent ratio of the rendered card width", :js do
        visit game_path(game)

        offset = card_pair_offset(".panel--hand .card-container")

        expect(offset["gap"]).to be_within(2).of(offset["width"] * 0.6)
      end

      it "keeps that ratio consistent on a narrower viewport, instead of a fixed offset", :js do
        resize_page(700, 700) do
          visit game_path(game)

          offset = card_pair_offset(".panel--hand .card-container")

          expect(offset["gap"]).to be_within(2).of(offset["width"] * 0.6)
        end
      end

      it "overlaps the expanded opponent hand by the same ratio", :js do
        visit game_path(game)
        all(".player-dropdown__summary").first.click

        offset = card_pair_offset(".expanded__hand .card-container")

        expect(offset["gap"]).to be_within(2).of(offset["width"] * 0.6)
      end

      it "keeps the card's true aspect ratio even when too many cards to fit overflow the row", :js do
        large_hand_game = create(:started_game, :go_fish, :users_turn, :many_participants,
                                  user: user, users_count: 2)

        visit game_path(large_hand_game)

        dims = card_container_dimensions(".panel--hand .card-container")

        expect(dims["width"] / dims["height"]).to be_within(0.05).of(5.0 / 7.0)
      end

      it "tightens overlap so a large hand fits the row without scrolling", :js do
        large_hand_game = create(:started_game, :go_fish, :users_turn, :many_participants,
                                  user: user, users_count: 2)

        resize_page(375, 700) do
          visit game_path(large_hand_game)

          fit = page.evaluate_script(<<~JS)
            (function() {
              var row = document.querySelector(".panel--hand .panel__body");
              return { fitsWithoutScroll: row.scrollWidth <= row.clientWidth + 1 };
            })()
          JS

          expect(fit["fitsWithoutScroll"]).to be true
        end
      end

      it "tightens the overlap below 40% when the hand is too wide for 40%", :js do
        large_hand_game = create(:started_game, :go_fish, :users_turn, :many_participants,
                                  user: user, users_count: 2)

        resize_page(375, 700) do
          visit game_path(large_hand_game)

          offset = card_pair_offset(".panel--hand .card-container")

          expect(offset["gap"]).to be < offset["width"] * 0.6
        end
      end
    end
  end

  context "When games have been deleted" do
    let!(:game) { create(:deleted_game) }

    it "shows no deleted games" do
      visit games_path
      expect(page).to_not have_content("Join")
    end
  end

  context "[ OFFLINE ]", :chrome do
    let!(:game) { create(:started_game, :go_fish, :users_turn, :many_participants, user: user) }

    after do
      go_online
    end

    it "tells user when they are offline" do
      visit game_path(game)
      expect(page).to have_current_path(game_path(game))
      expect(page).to_not have_content("You are offline")

      go_offline
      expect(page).to have_content("You are offline")
    end

    it "caches the offline page for use when navigation fails" do
      visit game_path(game)

      cached = page.evaluate_async_script(<<~JS)
        var done = arguments[0]
        navigator.serviceWorker.ready
          .then(() => caches.match("/offline"))
          .then(r => done(!!r))
      JS

      expect(cached).to be true
    end
  end
end

def card_pair_offset(selector)
  previous = nil

  Timeout.timeout(Capybara.default_max_wait_time) do
    loop do
      current = measure_card_pair(selector)
      return current if current == previous

      previous = current
      sleep 0.05
    end
  end
end

def measure_card_pair(selector)
  page.evaluate_script(<<~JS)
    (function() {
      var cards = document.querySelectorAll(#{selector.to_json});
      var first = cards[0].getBoundingClientRect();
      var second = cards[1].getBoundingClientRect();
      return { width: first.width, gap: second.left - first.left };
    })()
  JS
end

def card_container_dimensions(selector)
  previous = nil

  Timeout.timeout(Capybara.default_max_wait_time) do
    loop do
      current = measure_card_container(selector)
      return current if current == previous

      previous = current
      sleep 0.05
    end
  end
end

def measure_card_container(selector)
  page.evaluate_script(<<~JS)
    (function() {
      var rect = document.querySelector(#{selector.to_json}).getBoundingClientRect();
      return { width: rect.width, height: rect.height };
    })()
  JS
end

def go_offline
  page.driver.browser.network_conditions = { offline: true, latency: 0, throughput: 0 }
end

def go_online
  page.driver.browser.network_conditions = { offline: false, latency: 0, throughput: 1_000_000 }
end
