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

  it "lets user create go_fish type" do
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
        expect(page).to_not have_content( "Waiting for players..." )
        expect(page).to have_http_status(:ok)
      end
    end

    context "crazy_eights game" do
      let!(:game) { create(:game, :crazy_eights, :has_user, :many_participants, user: user) }
      it "lets user start a game" do
        visit game_path(game)
        click_on "Start Game"
        expect(page).to_not have_content( "Waiting for players..." )
        expect(page).to have_http_status(:ok)
      end
    end

  end

  context "[ Turn ]" do

    context "go_fish game" do
      let!(:game) { create(:started_game, :go_fish, :users_turn, :many_participants, user: user) }
      let(:wait_time) { 0.1 }

      it "automatically takes a turn when the timer expires", :js do
        GamePresenter.wait_time = wait_time

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
          CrazyEights::Card.new("A", "Spades"),
          CrazyEights::Card.new("3", "Clubs")
        ]
        game.state.discard.active_card = CrazyEights::Card.new("2", "Spades")
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

  context "[ End ]" do
    let!(:game) { create(:finished_game, :user_won, :many_participants, user: user) }
    
    it "does stuff" do
      visit game_path(game)
      expect(page).to have_content("#{user.name} wins!")
    end
  end

  context "When games have been deleted" do
    let!(:game) { create(:deleted_game) }

    it "shows no deleted games" do
      visit games_path
      expect(page).to_not have_content("Join")
    end
  end

end
