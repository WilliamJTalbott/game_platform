require 'rails_helper'

RSpec.describe "Leaderboard", type: :request do
  let(:user) { create(:user) }

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
        create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ user ])
        create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ other ])

        get leaderboard_index_path

        expect(response.body).to include(user.name)
        expect(response.body).to include(other.name)
      end

      it "renders rows in time order under q[s]=play_seconds desc" do
        long_player = create(:user, name: "Long Player")
        short_player = create(:user, name: "Short Player")
        create(:finished_game, :go_fish, :has_participants, :with_duration,
          users: [ long_player ], duration: 5.hours)
        create(:finished_game, :go_fish, :has_participants, :with_duration,
          users: [ short_player ], duration: 5.minutes)

        get leaderboard_index_path(q: { s: "play_seconds desc" })

        expect(response.body.index(long_player.name)).to be < response.body.index(short_player.name)
      end

      it "omits a sub-5-game player's name when the win-percent floor is set" do
        rookie = create(:user, name: "Rookie")
        create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ rookie ])

        get leaderboard_index_path(q: { s: "win_percentage desc", games_played_gteq: 5 })

        expect(response.body).to_not include(rookie.name)
      end

      it "renders successfully in default order under an unrecognized sort" do
        get leaderboard_index_path(q: { s: "nonsense" })

        expect(response).to have_http_status(:ok)
      end

      it "filters to a country with q[country_eq]" do
        us_player = create(:user, name: "US Player", country: "US")
        ca_player = create(:user, name: "CA Player", country: "CA")
        create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ us_player ])
        create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ ca_player ])

        get leaderboard_index_path(q: { country_eq: "US" })

        expect(response.body).to include(us_player.name)
        expect(response.body).to_not include(ca_player.name)
      end

      it "filters to a minimum games count with q[games_played_gteq]" do
        veteran = create(:user, name: "Veteran")
        newcomer = create(:user, name: "Newcomer")
        2.times { create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ veteran ]) }
        create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ newcomer ])

        get leaderboard_index_path(q: { games_played_gteq: 2 })

        expect(response.body).to include(veteran.name)
        expect(response.body).to_not include(newcomer.name)
      end

      it "filters by a case-insensitive partial name with q[name_i_cont]" do
        player = create(:user, name: "Alexandria")
        create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ player ])

        get leaderboard_index_path(q: { name_i_cont: "exand" })

        expect(response.body).to include(player.name)
      end

      it "ignores an attempt to filter by q[user_id_eq]" do
        create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ user ])

        get leaderboard_index_path(q: { user_id_eq: user.id })

        expect(response.body).to include(user.name)
      end

      it "round-trips the primary sort through the hidden q[s] field" do
        get leaderboard_index_path(q: { s: "play_seconds desc" })

        expect(Capybara.string(response.body))
          .to have_css("input#q_s[value='play_seconds desc']", visible: :all)
      end

      it "ignores an attempt to sort by q[s]=user_id desc" do
        get leaderboard_index_path(q: { s: "user_id desc" })

        expect(response).to have_http_status(:ok)
      end
    end

    context "when authenticated with a hand-edited query string" do
      before do
        sign_in(user)
        create(:finished_game, :go_fish, :has_participants, :with_duration, users: [ user ])
      end

      malformed_queries = {
        "a scalar q" => "?q=foo",
        "an array q" => "?q[]=foo",
        "a hash q[s]" => "?q[s][evil]=1",
        "a scalar q[g]" => "?q[g]=nonsense",
        "a null byte in a filter" => "?q[name_i_cont]=a%00b",
        "an array page" => "?page[]=1",
        "a page whose offset overflows bigint" => "?page=999999999999999999999"
      }

      malformed_queries.each do |description, query_string|
        it "renders rather than raising given #{description}" do
          get "#{leaderboard_index_path}#{query_string}"

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
