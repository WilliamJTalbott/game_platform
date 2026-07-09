FactoryBot.define do
  factory :game do
    name { "My Game" }

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
          turn_index_from_user(game, evaluator.user)
        end
      end

      after(:create) do |game|
        game.start
      end

      factory :finished_game do
        trait :user_won do
          after(:build) do |game, evaluator|
            game.participants << build(:participant, :winner, game: game, user: evaluator.user,)
          end
        end

        after(:create) do |game|
          game.finish
        end
      end
    end

  end
end

def turn_index_from_user(game, user)
  state = game.go_fish
  player = state.players.find { |player| player.user_id == user.id }
  state.turn_index = state.players.index(player) 
end