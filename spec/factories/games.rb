FactoryBot.define do
  factory :game do
    name { "My Game" }
    type { "GoFishGame" }

    initialize_with { type.present? ? type.constantize.new(attributes) : Game.new(attributes) }

    transient do
      user { nil }
    end

    trait :go_fish do
      type { "GoFishGame" }
    end

    trait :crazy_eights do
      type { "CrazyEightsGame" }
    end

    trait :rummy do
      type { "RummyGame" }
    end

    trait :has_user do
      after(:build) do |game, evaluator|
        game.participants << build(:participant, :host, game: game, user: evaluator.user)
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

    factory :deleted_game do
      deleted_at { Time.current }
    end

    factory :old_game do
      created_at { 3.days.ago }
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
  state = game.state
  player = state.players.find { |player| player.user_id == user.id }
  state.turn_index = state.players.index(player)
  game.save!
end
