require 'rails_helper'
RSpec.describe 'Leaderboard', type: :system, js: true do
  let(:user) { create(:user, name: "Games Player") }
  let(:winner) { create(:user, name: "Wins Player") }

  before do
    3.times { create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ user ]) }
    game = create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ winner ])
    game.participants.find_by!(user: winner).update!(winner: true)
  end

  it 'reorders the board when a sort button is clicked' do
    login_user(user)
    visit leaderboard_index_path

    expect(page.text.index("Wins Player")).to be < page.text.index("Games Player")

    click_button "Games Played"

    expect(page).to have_css("tbody tr:first-child", text: "Games Player")
    expect(page.text.index("Games Player")).to be < page.text.index("Wins Player")
  end

  it 'narrows the board when a partial name is typed into the search field' do
    login_user(user)
    visit leaderboard_index_path

    expect(page).to have_content("Wins Player")

    fill_in "Search players", with: "Games"

    expect(page).to have_no_content("Wins Player")
    expect(page).to have_content("Games Player")
  end
end
