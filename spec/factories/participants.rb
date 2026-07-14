FactoryBot.define do
  factory :participant do
    association :user
    association :game

    trait :winner do
      winner { true }
    end
  end
end
