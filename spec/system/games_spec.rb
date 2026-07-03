require 'rails_helper'
RSpec.describe 'Games', type: :system do
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
      end.to change(game.players, :count).by 1
    end
  end

  context "When a game has been created" do
    let!(:game) { create(:game) }
    it "lets other users join" do
      expect do
        visit games_path
        click_on "Join"
        expect(page).to have_current_path(game_path(game))
      end.to change(game.players, :count).by 1
    end
  end

  context "When a game has finished" do
    let(:game_name) { "This game" }
    let!(:finished_game) { create(:game, :go_fish, :finished, name: game_name) }

    it "shown in participant history" do
      visit history_index_path
      expect(page).to have_content( game_name )
    end

  end
end