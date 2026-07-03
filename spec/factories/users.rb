FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "person#{n}@example.com" }
    password { "password" }
  end
end
