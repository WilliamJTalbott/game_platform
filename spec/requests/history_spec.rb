require 'rails_helper'

RSpec.describe "History", type: :request do
  let(:user) { create(:user) }
  before { sign_in(user) }

  it "shows only the current user's finished games" do
    game = create(:finished_game, :go_fish, :many_participants, :has_participants, users: [ user ])
    game.update!(finished_at: Time.current)

    get history_index_path

    expect(response.body).to include game.name
  end

  it "does not show another user's finished game" do
    other_game = create(:finished_game, :go_fish, :many_participants).tap { |game| game.update!(finished_at: Time.current) }

    get history_index_path

    expect(response.body).to_not include other_game.name
  end

  it "does not show a game that hasn't finished yet" do
    in_progress_game = create(:started_game, :go_fish, :many_participants, :has_participants, users: [ user ])

    get history_index_path

    expect(response.body).to_not include in_progress_game.name
  end

  it "shows the correct winner name for each game" do
    game = create(:finished_game, :go_fish, :many_participants, :user_won, user: user)
    game.update!(finished_at: Time.current)

    get history_index_path

    expect(response.body).to include user.name
  end

  it "still shows a finished game that has since been soft-deleted" do
    game = create(:finished_game, :go_fish, :many_participants, :has_participants, users: [ user ])
    game.update!(finished_at: Time.current, deleted_at: Time.current)

    get history_index_path

    expect(response.body).to include game.name
  end
end
