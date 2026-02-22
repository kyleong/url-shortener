FactoryBot.define do
  factory :visit do
    association :url

    visited_at { Time.current }
    ip_address { Faker::Internet.ip_v4_address }
    user_agent { Faker::Internet.user_agent }
    referer { Faker::Internet.url }
    city { Faker::Address.city }
    country { Faker::Address.country }
    country_code { Faker::Address.country_code }
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }

    trait :no_location do
      city { nil }
      country { nil }
      country_code { nil }
      latitude { nil }
      longitude { nil }
    end

    trait :no_referer do
      referer { nil }
    end

    trait :ipv6 do
      ip_address { Faker::Internet.ip_v6_address }
    end
  end
end
