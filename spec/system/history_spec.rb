require 'rails_helper'
RSpec.describe 'History', type: :system do
  let(:user) { create(:user) }
  
  it 'shows the history page' do
    login_user(user)
    visit history_index_path
    expect(page).to have_content 'Game Name'
  end

end