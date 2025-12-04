# Step definitions for movie search feature

Given('I am a logged in user') do
  @user = User.find_or_initialize_by(email: 'testuser@example.com')
  @user.username ||= 'testuser'
  @user.password = 'ValidPass123'
  @user.password_confirmation = 'ValidPass123'
  @user.save!
  visit sign_in_path
  fill_in 'Email', with: @user.email
  fill_in 'Password', with: 'ValidPass123'
  click_button 'Sign In'
end

When('I visit the movie search page') do
  visit movies_path
end

When('I search for movie {string}') do |query|
  fill_in 'query', with: query
  click_button 'Search'
end

Then('I should see a search input field') do
  expect(page).to have_field('query')
end

Then('I should see search results for {string}') do |query|
  expect(page).to have_content("Top results for \"#{query}\"")
end

Then('I should see movie titles in the results') do
  expect(page).to have_css('article h2')
end

Then('I should see {string} links') do |link_text|
  expect(page).to have_link(link_text)
end

When('I click on {string} for the first result') do |link_text|
  first('article').click_link(link_text)
end

Then('I should be on a movie detail page') do
  expect(current_path).to match(%r{/movies/\d+})
end

Then('I should see movie information') do
  # Movie detail page should have movie content
  expect(page).to have_css('main')
end

Then('each result should display the movie title') do
  all('article').each do |article|
    expect(article).to have_css('h2')
  end
end

Then('each result should display the release year') do
  all('article').each do |article|
    expect(article).to have_content(/Released:/)
  end
end
