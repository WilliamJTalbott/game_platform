require 'rails_helper'
RSpec.describe 'Games', type: :system do
  
  context "Navigation" do

    let(:be_on_games_page) { have_content 'Games' }
    let(:user) { create(:user) }

    before { login_user(user) }
    
    it 'shows the games index' do
      visit games_path
      expect(page).to be_on_games_page
    end

    it 'lets user go to game/new' do
      visit games_path
      click_on "New Game"
      expect(page).to have_content "Setup Game"
    end

    context "When a user creates a game" do
      let!(:game) { build(:game) }
      it "adds to Database and reroutes to game/show" do 
        expect do
          setup_game(game.name, game.game_type)
          expect(page).to have_content game.name
        end.to change(Game, :count).by 1
      end
    end

    context "When a game has been created" do
      let!(:game) { create(:game) }
      it "lets other users join" do
        expect do
          visit games_path
          click_on "Join"
          expect(page).to have_current_path(game_path(game))
        end.to change(game.participants, :count).by 1
      end
    end

    context "When a game has been created" do
      let!(:game) { create(:game) }
      it "lets other users join" do
        expect do
          visit games_path
          click_on "Join"
          expect(page).to have_current_path(game_path(game))
        end.to change(game.participants, :count).by 1
      end
    end

    context "When a game has finished" do
      let(:game_name) { "This game" }
      let!(:finished_game) { create(:game, :finished, name: game_name) }
      it "shown in participant history" do
        visit history_index_path
        expect(page).to have_content( game_name )
      end
    end

    context "When game hasn't started" do
      let!(:game) { create(:game, :many_participants) }
      it "shows waiting modal" do
        visit game_path(game)
        expect(page).to have_content( "Waiting for players..." )
      end
    end
  end

  context "Navigation" do

    context "When game hasn't started" do
      let!(:users) { create_list(:user, 5) }
      let!(:game) { create(:game, :many_participants, users: users) }
      let(:user) { users.first }

      before { login_user(user) }

      it "User can click 'start' to start game" do
        visit game_path(game)
        click_on 'Start Game'

        expect(page).not_to have_content( "Waiting for players..." )
        expect(page).to have_http_status(:ok)
        expect(page).to have_current_path(game_path(game))
      end
    end

    context "When game has started" do
      let!(:game) { start_game }
      let!(:user) { logged_in_user(game) }

      it "shows users cards and opponent dropdowns" do
        visit game_path(game)

        within('.hand') do
          expect(page).to have_css('.card-container', count: 5)
        end
        expect(page).to have_css('#opponent-partial', count: 4)
      end
    end
  end

end

def start_game
  users = create_list(:user, 5)
  game = create(:game, :many_participants, users: users)
  game.start
  game.save
  game
end

def logged_in_user(game)
  user = game.participants.first.user
  login_user(user)
  user
end