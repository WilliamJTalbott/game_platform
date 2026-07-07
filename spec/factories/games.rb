FactoryBot.define do
  factory :game do
    name { "My Game" }
    game_type { "Go Fish" }

    transient do
      user { nil }
    end

    trait :has_user do
      after(:build) do |game, evaluator|
        game.participants << build(:participant, game: game, user: evaluator.user)
      end
    end

    trait :many_participants do
      transient do
        users_count { 4 }
      end

      participants do
        Array.new(users_count) { association(:participant) }
      end
    end

    trait :has_participants do
      transient do
        users { [] }
      end

      after(:build) do |game, evaluator|
        evaluator.users.each do |user|
          game.participants << build(:participant, game: game, user: user)
        end
      end
    end

    factory :started_game do
      trait :users_turn do
        has_user

        after(:create) do |game, evaluator|
          turn_index_from_user(game.go_fish, evaluator.user)
        end
      end

      after(:create) do |game|
        game.start
      end
    end

  end
end

def turn_index_from_user(game, user)
  player = game.players.find { |player| player.user_id == user.id }
  game.turn_index = game.players.index(player) 
end


  # get user's player, 
  # get index of that player, 
  # set turn index on game to that index

# let!(:game) { create(:started_game, :users_turn, user: user) }


    # trait :won do
    #   has_participants

    #   after(:build) do |game|
    #     game.participants.first.update(winner: true)
    #     game.start
    #     game.end
    #   end
    # end

    # trait :lost do
    #   has_participants

    #   after(:build) do |game|
    #     game.participants.second.update(winner: true)
    #     game.start
    #     game.end
    #   end
    # end