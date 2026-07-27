require 'rails_helper'

RSpec.describe "Leaderboard", type: :request do
  let(:user) { create(:user) }

  def finished_game_for(target_user, duration: 1.hour)
    create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ target_user ], duration: duration)
  end

  describe "GET index" do
    context "when unauthenticated" do
      it "redirects to the login page" do
        get leaderboard_index_path
        expect(response).to redirect_to new_session_path
      end
    end

    context "when authenticated" do
      before { sign_in(user) }

      it "renders every qualifying player's name" do
        other = create(:user, name: "Other")
        finished_game_for(user)
        finished_game_for(other)

        get leaderboard_index_path

        expect(response.body).to include(user.name)
        expect(response.body).to include(other.name)
      end

      it "renders rows in time order under sort=time" do
        long_player = create(:user, name: "Long Player")
        short_player = create(:user, name: "Short Player")
        finished_game_for(long_player, duration: 5.hours)
        finished_game_for(short_player, duration: 5.minutes)

        get leaderboard_index_path(sort: "time")

        expect(response.body.index(long_player.name)).to be < response.body.index(short_player.name)
      end

      it "omits a sub-5-game player's name under sort=win_percent" do
        rookie = create(:user, name: "Rookie")
        finished_game_for(rookie)

        get leaderboard_index_path(sort: "win_percent")

        expect(response.body).to_not include(rookie.name)
      end

      it "renders successfully in default order under an unrecognized sort" do
        get leaderboard_index_path(sort: "nonsense")

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
