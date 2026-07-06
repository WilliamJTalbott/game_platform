FactoryBot.define do
  factory :game do
    name { "My Game" }
    game_type { "Go Fish" }

    trait :started do
      started_at { 3.hours.ago }
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

    trait :many_players do

      transient do
        users { [] } 
      end

      after(:build) do |game, evaluator|
        evaluator.users.each do |user|
          game.players << build(:player, game: game, user: user)
        end
      end
    end

    trait :won do
      many_players

      after(:build) do |game|
        game.players.first.update(winner: true)
        game.start
        game.end
      end
    end

    trait :lost do
      many_players

      after(:build) do |game|
        game.players.second.update(winner: true)
        game.start
        game.end
      end
    end

    factory :waiting, traits: [:few_players]
    factory :waiting_full, traits: [:many_players]
    factory :in_progress, traits: [:started]
  end
end
