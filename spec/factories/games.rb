FactoryBot.define do
  factory :game do
    name { "My Game" }
    game_type { "Go Fish" }

    trait :started do
      started_at { 1.hour.ago }
    end

    trait :go_fish do
      game_type { "Go Fish" }
    end

    trait :secret_hitler do
      game_type { "Secret Hitler" }
    end

    trait :finished do
      started
      finished_at { 3.hours.ago }
    end

    factory :waiting, traits: [:few_players]
    factory :waiting_full, traits: [:many_players]
    factory :in_progress, traits: [:started]
  end
end
