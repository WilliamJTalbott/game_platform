require 'rails_helper'
RSpec.describe 'Session', type: :system do
  let(:user) { create(:user) }
  before { visit root_path }

  it "shows the login page" do
    expect(page).to have_current_path new_session_path
  end

  context "When user logs in" do
    before { sign_in_as(user) }
    it "directs them to the root page" do
      visit root_path
      expect(page).to have_current_path root_path
    end
  end

  context "When user clicks 'forgot password' " do
    it "directs them to the password_new page" do
      click_on "Forgot password?"
      expect(page).to have_current_path new_password_path
    end
  end 

  context "When user clicks 'Sign up' " do
    it "directs them to the user_new page" do
      click_on "Sign up"
      expect(page).to have_current_path new_user_path
    end
  end 

  context "When logged in and clicks logout" do
    before {login_user(user)}
    it "sends them to the login page" do
      click_on "Logout"
      expect(page).to have_current_path new_session_path
    end
  end

  
end