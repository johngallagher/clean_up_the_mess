FactoryBot.define do
  factory :user do
    name { "Joe Bloggs" }
    email { "joe@example.org" }
    password { "password" }

    trait :activated do
      activated { true }
      activated_at { Time.zone.now }
    end
  end
end
