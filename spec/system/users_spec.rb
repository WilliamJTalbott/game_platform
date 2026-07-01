require 'rails_helper'
RSpec.describe 'User', type: :system do
  let(:user) { create(:user) }

  before { visit new_user_path }
  it "shows the Sign Up page" do
    expect(page).to have_current_path new_user_path
  end

  context "When a user clicks Log in" do
    it "shows the Login page" do
      click_on 'Log in'
      expect(page).to have_current_path new_session_path
    end
  end

  context "When user signs up" do
    it "adds to Database and reroutes to root" do
      expect do
        sign_up("test@example.com", "134@Toast")
        expect(page).to have_current_path root_path
      end.to change(User, :count).by 1
    end
  end

  context "When user submits invalid inputs" do
    it "displays flash message" do
      sign_up("test@example.com", "2")
      expect(page).to have_content("is too short (minimum is 8 characters)")
    end
  end

end