require 'rails_helper'
RSpec.describe 'Sessions', type: :system do
  let(:be_on_login_page) { have_current_path new_session_path }
  let(:be_on_game_page) { have_current_path games_path }
  let!(:user) {create(:user)}

  before {log_in(user)}

  it "shows the login page" do
    expect(page).to be_on_login_page
  end

  it "allows user to login" do
    have_current_path('/user')
    expect(page).to be_on_game_page
  end
  
end

def log_in(user)
  visit new_session_path
  fill_in :email_address, with: user.email_address
  fill_in :password, with: user.password_digest
  click_button 'Sign in'
end