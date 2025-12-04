# Step definitions for movie library feature

Given('I have {string} in my library') do |movie_title|
  # Create a movie and add to user's watchlist
  movie = Movie.create!(
    title: movie_title,
    tmdb_id: 27205, # Inception's TMDB ID
    poster_url: 'https://image.tmdb.org/t/p/w500/test.jpg'
  )
  @user.watchlists.create!(movie: movie)
end

Then('I should see an {string} button for the movie') do |button_text|
  within('article', match: :first) do
    expect(page).to have_button(button_text)
  end
end

Then('I should see a {string} button for the movie') do |button_text|
  within('article', match: :first) do
    expect(page).to have_button(button_text)
  end
end

When('I click the {string} button for the first movie') do |button_text|
  within('article', match: :first) do
    click_button button_text
  end
end

Then('the button should change to {string}') do |button_text|
  within('article', match: :first) do
    expect(page).to have_button(button_text)
  end
end

When('I visit my library page') do
  visit favorites_path
end

Then('I should see {string} in my library') do |movie_title|
  expect(page).to have_content(movie_title)
end

When('I visit the dashboard') do
  visit dashboard_path
end

Then('I should see a {string} link') do |link_text|
  expect(page).to have_link(link_text)
end

When('I click on the {string} link') do |link_text|
  click_link link_text
end

Then('I should be on the library page') do
  expect(current_path).to eq(favorites_path)
end
