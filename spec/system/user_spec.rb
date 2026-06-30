require 'rails_helper'
RSpec.describe 'User', type: :system do
  let(:user) { create(:user) }

  before { visit new_user_path }

  it "shows the login page" do
    expect(page).to have_current_path new_user_path
  end

  

end