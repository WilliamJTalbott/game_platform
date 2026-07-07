FactoryBot.define do
  factory :game do
    name { "My Game" }
    game_type { "Go Fish" }

    trait :started do
      started_at { 3.hours.ago }
      many_participants

      after(:build) do |game|
        game.start
      end
    end

    trait :go_fish do
      game_type { "Go Fish" }
    end

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
