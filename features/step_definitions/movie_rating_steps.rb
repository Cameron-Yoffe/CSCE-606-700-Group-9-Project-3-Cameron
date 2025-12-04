# Step definitions for movie rating feature

When('I visit the movie page for {string}') do |movie_title|
  # First search for the movie, then visit its page
  visit movies_path
  fill_in 'query', with: movie_title
  click_button 'Search'
  first('a', text: 'View details').click
end

Then('I should see star rating buttons') do
  expect(page).to have_css('.star-btn-container')
end

When('I set a rating of {int} out of {int}') do |rating, max|
  # Set the rating value by filling the hidden field
  find('.rating-value-input', visible: false).set(rating)
end

Given('I have rated {string} with {int} out of {int}') do |movie_title, rating, max|
  # Create the movie and rating in database
  movie = Movie.find_by(title: movie_title) || Movie.create!(
    title: movie_title,
    tmdb_id: 27205,
    poster_url: 'https://image.tmdb.org/t/p/w500/test.jpg'
  )
  @user.ratings.create!(movie: movie, value: rating)
end

Then('I should see my previous rating displayed') do
  expect(page).to have_css('.star-display')
end

When('I fill in the review with {string}') do |review_text|
  fill_in 'rating[review]', with: review_text
end

Given('I am not logged in') do
  # Make sure we're logged out by deleting the session
  Capybara.reset_sessions!
end
