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

    trait :many_participants do

      transient do
        users { [] }
      end

      after(:build) do |game, evaluator|
        evaluator.users.each do |user|
          game.participants << build(:participant, game: game, user: user)
        end
      end
    end

    trait :started do
      many_participants

      after(:build) do |game|
        game.started_at = 1.hour.ago
      end
    end

    trait :won do
      many_participants

      after(:build) do |game|
        game.participants.first.update(winner: true)
        game.start
        game.end
      end
    end

    trait :lost do
      many_participants

      after(:build) do |game|
        game.participants.second.update(winner: true)
        game.start
        game.end
      end
    end
    
  end
end
