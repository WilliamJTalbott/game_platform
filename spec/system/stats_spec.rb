require 'rails_helper'
RSpec.describe 'Stats', type: :system do
  let(:user) { create(:user) }
    
  it 'shows the games index' do
    login_user(user)
    visit stats_path
    expect(page).to have_content 'Big Numbers'
  end

  context "when user has played" do
    let(:games_lost) { 8 }
    let(:games_won) { 5 }
    
    let!(:users) { create_list(:user, 5) }

    before do
      create(:game, :many_participants, users: users)
      games_lost.times { create(:game, :lost, users: users) }
      games_won.times { create(:game, :won, users: users) }
      login_user(users.first)
    end

    it "shows number of games played" do
      visit stats_path
      expect(page).to have_content( games_lost + games_won )
    end

    it "shows number of games won" do
      visit stats_path
      expect(page).to have_content( games_won )
    end
  end

end