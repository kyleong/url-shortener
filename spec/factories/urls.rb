FactoryBot.define do
  factory :url do
    sequence(:target_url) { |n| "https://example#{n}.com/some/path" }
    sequence(:short_code) { |n| "abc#{n.to_s.rjust(3, '0')}" }
    title { "Example Page Title" }
    is_active { true }
    session_id { SecureRandom.hex(16) }
    fetch_status_code { 200 }
    fetched_at { 1.hour.ago }

    trait :inactive do
      is_active { false }
    end

    trait :unfetched do
      fetch_status_code { nil }
      fetched_at { nil }
      title { nil }
    end

    trait :not_found do
      fetch_status_code { 404 }
    end
  end
end
