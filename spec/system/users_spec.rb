require 'rails_helper'
RSpec.describe 'User', type: :system do
  let(:user) { create(:user) }

  context "when not logged in" do
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

  context "when user editing their profile" do
    before do
      login_user(user)
      visit edit_user_path(user)
    end

    it "lets them update their name" do
      fill_in 'Name', with: 'Brotato'
      click_on 'Update Profile'

      expect(user.reload.name).to eq 'Brotato'
    end

    it "lets them update their country" do
      select 'United States', from: "Country"
      click_on 'Update Profile'

      expect(user.reload.country).to eq 'US'
    end

    it "updates the states when a country is selected", :js do
      expect(page).to_not have_select("State", with_options: [ "Alabama" ])

      select "United States", from: "Country"

      expect(page).to have_select("State", with_options: [ "Alabama" ])
    end
  end
end
