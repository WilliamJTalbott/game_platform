require 'rails_helper'
RSpec.describe 'Sessions', type: :system do
  let(:user) { create(:user) }
  before { visit root_path }

  it "shows the login page" do
    expect(page).to have_current_path new_session_path
  end

  context "When user logs in" do
    before {login_user(user)}
    it "directs them to the root page" do
      expect(page).to have_current_path root_path
    end
  end

  context "When user clicks 'forgot password' " do
    it "directs them to the password new page" do
      click_on "Forgot password?"
      expect(page).to have_current_path new_password_path
    end
  end 

  context "When user clicks 'forgot password' " do
    it "directs them to the password new page" do
      visit root_path
      click_on "Forgot password?"
      expect(page).to have_current_path new_password_path
    end
  end 

  
end