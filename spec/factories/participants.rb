FactoryBot.define do
  factory :participant do
    association :user
    association :game
  end
end
