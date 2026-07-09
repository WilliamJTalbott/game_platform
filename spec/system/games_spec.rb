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
    let!(:game) { create(:game, :has_user, user: user) }
    
    it "lets user join a game" do
      visit games_path

      click_on "View"
      expect(page).to have_current_path(game_path(game))
    end

  end

  context "[ Start ]" do
    let!(:game) { create(:game, :has_user, :many_participants, user: user) }

    it "lets user start a game" do
      visit game_path(game)
      click_on "Start Game"
      expect(page).to_not have_content( "Waiting for players..." )
      expect(page).to have_http_status(:ok)
    end
  end

  context "[ Turn ]" do
    let!(:game) { create(:started_game, :users_turn, :many_participants, user: user) }

    it "allows user to take a turn" do
      visit game_path(game)
      expect(game.is_user_turn?(user)).to be true
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

  context "[ End ]" do
    let!(:game) { create(:finished_game, :user_won, :many_participants, user: user) }
    
    it "does stuff" do
      visit game_path(game)
      expect(page).to have_content("#{user.email_address} wins!")
    end
  end

end