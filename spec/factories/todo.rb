# frozen_string_literal: true

FactoryBot.define do
  factory :todo do
    sequence(:name) { |n| "Todo #{n}" }
    sequence(:notes) { |n| "Notes #{n}" }
    created_at { 1.week.ago }
    updated_at { 5.days.ago }

    trait :available do
      deferred_until { 1.day.ago }
      deferred_at { 2.days.ago }
    end

    trait :tomorrow do
      deferred_until { 1.day.from_now }
    end

    trait :future do
      deferred_until { 2.days.from_now }
    end

    trait :completed do
      completed_at { 1.day.ago }
    end

    trait :deleted do
      deleted_at { 1.day.ago }
    end
  end
end
