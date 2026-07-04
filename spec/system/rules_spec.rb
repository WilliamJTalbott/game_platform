require 'rails_helper'
RSpec.describe 'Rules', type: :system do
  let(:user) { create(:user) }
  
  it 'shows the games index' do
    login_user(user)
    visit rules_path
    expect(page).to have_content 'Go Fish Rules'
  end

end