FactoryBot.define do
  factory :post do
    sequence(:title) { |n| "Post title #{n}" }
    body { "Some body text for this post." }
    status { "pending" }
  end
end
