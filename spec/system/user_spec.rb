require 'rails_helper'
RSpec.describe 'User', type: :system do
  let(:user) { create(:user) }

  before { visit new_user_path }

  it "shows the Sign Up page" do
    expect(page).to have_current_path new_user_path
  end

  context "When user signs up" do
    it "adds to Database and reroutes to root" do
      expect(page).to have_current_path root_path
      expect do
        sign_up("test@example.com", "134@test")
      end.to change(User, :count).by 1
    end
  end

  # expect "When a user clicks Log in" do
  #   it "shows the Sign Up page" do
  #     expect(page).to have_current_path new_user_path
  #   end
  # end


end