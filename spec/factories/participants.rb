FactoryBot.define do
  factory :participant do
    association :user
    association :game

    trait :winner do
      winner { true }
    end

    trait :host do
      host { true }
    end
  end
end
