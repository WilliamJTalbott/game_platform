require 'rails_helper'

RSpec.describe 'Lobby screenshot', type: :system do
  let(:user) { create(:user, name: "William") }
  let(:other) { create(:user, name: "Alex") }

  before do
    create(:started_game, :users_turn, :has_participants, name: "Friday Night Go Fish", user: user, users: [other])
    create(:started_game, :has_user, :has_participants, :crazy_eights, name: "Eights With Mom", user: user, users: [other])
    create(:game, :has_user, :rummy, name: "Rummy Practice", user: user)
    create(:game, :rummy, :has_participants, name: "Rummy Night", users: [other])
    create(:game, :crazy_eights, :many_participants, name: "Eights Tournament", users_count: 4)
    login_user(user)
  end

  it "captures the lobby in dark mode", :js do
    pw_page.emulate_media(colorScheme: "dark")
    visit games_path
    expect(page).to have_css(".game-card")
    pw_page.set_viewport_size(width: 1440, height: 900)
    screenshot("lobby-desktop")
    pw_page.set_viewport_size(width: 390, height: 844)
    screenshot("lobby-mobile", fullPage: true)
  end
end
