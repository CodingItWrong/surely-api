# frozen_string_literal: true

FactoryBot.define do
  factory :todo do
    sequence(:name) { |n| "Todo #{n}" }
  end
end
