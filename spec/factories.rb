FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    username { Faker::Internet.unique.username(specifier: 5..20) }
    password { "SecurePass123" }
    password_confirmation { "SecurePass123" }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    bio { Faker::Lorem.sentence }

    # Skip password validation for tests that want to set it manually
    trait :with_invalid_password do
      password { "weak" }
      password_confirmation { "weak" }
    end
  end

  factory :movie do
    title { Faker::Movie.title }
    description { Faker::Lorem.paragraph }
    tmdb_id { Faker::Number.unique.number(digits: 6) }
    poster_url { Faker::Internet.url }
    vote_average { Faker::Number.decimal(l_digits: 1, r_digits: 1) }
    vote_count { Faker::Number.number(digits: 5) }
    release_date { Faker::Date.between(from: 20.years.ago, to: Date.today) }
    runtime { Faker::Number.between(from: 90, to: 180) }
    director { Faker::Name.name }
  end

  factory :tag do
    name { Faker::Lorem.unique.word }
    category { Tag::MAIN_CATEGORIES.sample }
  end

  factory :watchlist do
    user { association :user }
    movie { association :movie }
    status { "to_watch" }
  end

  factory :rating do
    user { association :user }
    movie { association :movie }
    value { Faker::Number.between(from: 1, to: 10) }
    review { Faker::Lorem.paragraph }
  end

  factory :favorite do
    user { association :user }
    movie { association :movie }
  end

  factory :diary_entry do
    user { association :user }
    movie { association :movie }
    content { Faker::Lorem.paragraph(sentence_count: 5) }
    watched_date { Faker::Date.between(from: 1.year.ago, to: Date.today) }
    mood { [ 'happy', 'sad', 'excited', 'thoughtful', 'entertained' ].sample }
    rating { Faker::Number.between(from: 0, to: 10) }
  end
end
