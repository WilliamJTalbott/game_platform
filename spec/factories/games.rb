FactoryBot.define do
  factory :game do
    name { "My Game" }
    game_type { "Go Fish" }

    trait :secret_hitler do
      game_type { "Secret Hitler" }
    end

    trait :finished do
      started
      finished_at { 1.hour.ago }
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

    trait :many_participants do

      transient do
        users_count { 4 }
      end

      participants do
        Array.new(users_count) { association(:participant) }
      end

    end

    trait :started do
      has_participants

      after(:build) do |game|
        game.started_at = 1.hour.ago
      end
    end

    trait :won do
      has_participants

      after(:build) do |game|
        game.participants.first.update(winner: true)
        game.start
        game.end
      end
    end

    trait :lost do
      has_participants

      after(:build) do |game|
        game.participants.second.update(winner: true)
        game.start
        game.end
      end
    end

    trait :has_user do
      transient do
        user { nil }
      end

      after(:build) do |game, evaluator|
        game.participants << build(:participant, game: game, user: evaluator.user)
      end
    end
    
  end
end
