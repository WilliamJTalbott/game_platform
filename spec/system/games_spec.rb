require 'rails_helper'
RSpec.describe 'Games', type: :system do
  let(:be_on_games_page) { have_content 'All Games' }
  let(:user) { create(:user) }
  
  it 'shows the games index' do
    login_user(user)
    expect(page).to be_on_games_page
  end

end