require 'rails_helper'
RSpec.describe 'Games', type: :system do
  let(:be_on_games_page) { have_content 'All Games' }
  let(:be_on_rules_page) { have_content 'Rules' }
  let(:be_on_stats_page) { have_content 'Stats' }
  let(:be_on_history_page) { have_content 'History' }
  
  it 'shows the games index' do
    visit games_path
    expect(page).to be_on_games_page
  end

  it 'shows the games index' do
    visit pages_path
    expect(page).to be_on_rules_page
  end

  it 'shows the games index' do
    visit pages_path
    expect(page).to be_on_stats_page
  end

  it 'shows the games index' do
    visit games_history_path
    expect(page).to be_on_history_page
  end

end