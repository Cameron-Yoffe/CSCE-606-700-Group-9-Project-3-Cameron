When('I visit the root page') do
  visit root_path
end

Then('I should be on the dashboard') do
  expect(current_path).to eq(dashboard_path)
end

Then('I should see a new activity indicator') do
  expect(page).to have_css('[data-activity-feed-target="badge"]', visible: :all)
end

Then('I should see a {string} button') do |button_text|
  expect(page).to have_button(button_text)
end

Given('I have a movie {string} on my watchlist') do |title|
  user = @current_user || @user
  user ||= User.create!(
    email: 'watchlist-user@example.com',
    username: 'watchlist-user',
    password: 'SecurePass123',
    password_confirmation: 'SecurePass123'
  )

  @watchlist_movie = Movie.create!(
    title: title,
    tmdb_id: rand(100_000..999_999),
    poster_url: 'https://image.tmdb.org/t/p/w500/test.jpg'
  )

  Watchlist.create!(user: user, movie: @watchlist_movie, status: 'to_watch')
end

Then('the watchlist should be managed from my favorites library') do
  visit favorites_path
  expect(page).to have_css('#watchlist', text: @watchlist_movie.title)

  visit dashboard_path
  expect(page).not_to have_content('Watchlist')
end
