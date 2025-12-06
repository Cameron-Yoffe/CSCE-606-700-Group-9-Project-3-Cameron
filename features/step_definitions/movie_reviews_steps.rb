# Step definitions for writing and managing movie reviews

Given('I have previously reviewed {string} with text {string}') do |movie_title, review_text|
  movie = Movie.find_by(title: movie_title) || Movie.create!(
    title: movie_title,
    tmdb_id: 27205,
    poster_url: 'https://image.tmdb.org/t/p/w500/test.jpg'
  )
  @user ||= User.first || create(:user, email: 'reviewer@example.com', username: 'reviewer', password: 'ValidPass123', password_confirmation: 'ValidPass123')
  @user.ratings.create!(movie: movie, value: 8, review: review_text)
end

When('I write a review with text {string}') do |review_text|
  fill_in 'rating[review]', with: review_text
end

When('I edit my review to {string}') do |review_text|
  fill_in 'rating[review]', with: review_text
end

When('I leave the review text blank') do
  fill_in 'rating[review]', with: ''
end

When('I submit my movie review') do
  if page.has_button?('Save Rating & Review')
    click_button 'Save Rating & Review'
  else
    click_button 'Update Rating & Review'
  end
end

Then('I should see my review text {string}') do |review_text|
  expect(page).to have_content(review_text)
end

Then('I should see my username on the review') do
  display_name = @user&.username || @user&.email || 'testuser'
  expect(page).to have_content(display_name)
end

Then('I should see a review validation message {string}') do |message|
  expect(page).to have_content(message)
end
