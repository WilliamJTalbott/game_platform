require 'rails_helper'
RSpec.describe 'Stats', type: :system do
  let(:user) { create(:user) }
  
  it 'shows the games index' do
    login_user(user)
    visit stats_path
    expect(page).to have_content 'Big Numbers'
  end

end