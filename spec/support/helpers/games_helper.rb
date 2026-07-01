module GamesHelper
  def setup_game(name, type)
    visit new_game_path
    fill_in "Name", with: name
    select "Go Fish", from: "Type"
    click_button 'Create Game'
  end
end