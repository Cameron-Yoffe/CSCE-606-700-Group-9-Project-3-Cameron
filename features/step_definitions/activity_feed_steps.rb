# frozen_string_literal: true

# Use parameterized step for all users logging movies
Given("{word} has logged a movie {string} in their diary") do |username, movie_title|
  user = @other_users[username]
  movie = Movie.create!(
    title: movie_title,
    tmdb_id: rand(100000..999999),
    poster_url: "https://example.com/poster.jpg"
  )
  DiaryEntry.create!(
    user: user,
    movie: movie,
    watched_date: Date.today,
    content: "Great movie!"
  )
end

Given("{word} has rated {string} with {int} out of {int}") do |username, movie_title, rating, _max|
  user = @other_users[username]
  movie = Movie.create!(
    title: movie_title,
    tmdb_id: rand(100000..999999),
    poster_url: "https://example.com/poster.jpg"
  )
  Rating.create!(
    user: user,
    movie: movie,
    value: rating
  )
end

Given("{word} has rated {string} with a review") do |username, movie_title|
  user = @other_users[username]
  movie = Movie.create!(
    title: movie_title,
    tmdb_id: rand(100000..999999),
    poster_url: "https://example.com/poster.jpg"
  )
  @user_ratings ||= {}
  @user_ratings[username] = Rating.create!(
    user: user,
    movie: movie,
    value: 8,
    review: "This was an amazing film with stunning visuals!"
  )
end

Given("{word} has reacted to {word}'s review with an emoji") do |reactor_name, reviewer_name|
  reactor = @other_users[reactor_name]
  rating = @user_ratings[reviewer_name]
  ReviewReaction.create!(
    user: reactor,
    rating: rating,
    emoji: "👍"
  )
end

Given("Alice is following {word}") do |username|
  user = @other_users[username]
  @current_user.follow(user)
end

Given("Alice unfollows {word}") do |username|
  user = @other_users[username]
  follow = Follow.find_by(follower: @current_user, followed: user)
  follow&.destroy
end

When("I visit my dashboard") do
  visit dashboard_path
end

Then("I should see {string} in the activity feed") do |text|
  within("#activity-feed-list", wait: 5) do
    expect(page).to have_content(text)
  end
end

Then("I should not see {string} in the activity feed") do |text|
  if page.has_css?("#activity-feed-list")
    within("#activity-feed-list") do
      expect(page).not_to have_content(text)
    end
  end
end

Then("I should see a refresh button in the activity feed") do
  expect(page).to have_button("Refresh")
end

Then("I should see {string} on the page") do |text|
  expect(page).to have_content(text)
end
