require 'rails_helper'

# SCAFFOLDING — not a real spec. Drives each page to a screenshot so the
# generated neutral ramp (core/theme.css) can be judged in dark mode.
# Delete once the ramp knobs are tuned. See docs/plans/own-the-tokens.md §1b.
RSpec.describe 'Ramp preview', :js, type: :system do
  let(:user) { create(:user, name: "Ada") }

  # Bullet flags a pre-existing counter-cache advisory on the games index
  # (GoFishGame => [:participants]). Unrelated to the ramp; off for the preview.
  around do |example|
    Bullet.enable = false
    example.run
    Bullet.enable = true
  end

  before { pw_page.emulate_media(colorScheme: "dark") }

  def shoot(name)
    screenshot("ramp-#{name}", fullPage: true)
  end

  it 'login' do
    visit new_session_path
    shoot("01-login")
  end

  it 'games index with a tray of games' do
    create(:game, :go_fish, :has_user, user: user, name: "Kitchen Table")
    create(:started_game, :crazy_eights, :users_turn, :many_participants, user: user, name: "Late Night")
    login_user(user)
    visit games_path
    shoot("02-games-index")
  end

  it 'waiting room' do
    game = create(:game, :go_fish, :has_user, user: user, name: "Kitchen Table")
    login_user(user)
    visit game_path(game)
    shoot("03-waiting-room")
  end

  it 'go fish table' do
    game = create(:started_game, :go_fish, :users_turn, :many_participants, user: user)
    login_user(user)
    visit game_path(game)
    shoot("04-go-fish")
  end

  it 'rummy table' do
    game = create(:started_game, :rummy, :users_turn, :many_participants, user: user)
    login_user(user)
    visit game_path(game)
    shoot("05-rummy")
  end

  it 'stats' do
    create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ user ])
    login_user(user)
    visit stats_path
    shoot("06-stats")
  end

  it 'leaderboard' do
    create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ user ])
    login_user(user)
    visit leaderboard_index_path
    shoot("07-leaderboard")
  end

  it 'history' do
    create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ user ])
    login_user(user)
    visit history_index_path
    shoot("08-history")
  end
end
