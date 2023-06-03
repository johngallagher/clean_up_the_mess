FactoryBot.define do
  factory :user do
    name { "Joe Bloggs" }
    email { "joe@example.org" }
    password { "password" }
  end
end
