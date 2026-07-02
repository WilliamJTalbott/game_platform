module GamesHelper
  def setup_game(name = "Game Name", type = "Go Fish")
    visit new_game_path
    fill_in "Name", with: name
    select type, from: "Type"
    click_button 'Create Game'
  end
end