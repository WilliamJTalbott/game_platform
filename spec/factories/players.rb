FactoryBot.define do
  factory :player do
    association :user
    association :game
  end
end
