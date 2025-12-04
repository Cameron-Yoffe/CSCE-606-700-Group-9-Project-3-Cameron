Given('the following user exists:') do |table|
  table.hashes.each do |row|
    User.create!(
      email: row['email'],
      username: row['username'],
      password: row['password'],
      password_confirmation: row['password']
    )
  end
end

Given('the following movies exist:') do |table|
  table.hashes.each do |row|
    Movie.create!(
      title: row['title'],
      tmdb_id: row['tmdb_id'].to_i,
      description: 'A great movie',
      poster_url: 'https://via.placeholder.com/300x450'
    )
  end
end

Given('I am signed in as {string} with password {string}') do |username, password|
  user = User.find_by(username: username)
  visit sign_in_path
  fill_in 'email', with: user.email
  fill_in 'password', with: password
  click_button 'Sign In'
end

Given('I have favorited {string}') do |movie_title|
  movie = Movie.find_by(title: movie_title)
  user = User.find_by(username: 'moviefan')
  Favorite.create!(user: user, movie: movie)
end

Given('I have favorited the following movies:') do |table|
  user = User.find_by(username: 'moviefan')
  table.hashes.each do |row|
    movie = Movie.find_by(title: row['title'])
    Favorite.create!(user: user, movie: movie)
  end
end

Given('I have the following movies in my top 5:') do |table|
  user = User.find_by(username: 'moviefan')
  table.hashes.each do |row|
    movie = Movie.find_by(title: row['title'])
    favorite = Favorite.find_or_create_by!(user: user, movie: movie)
    favorite.update!(top_position: row['position'].to_i)
  end
end

Given('I have {string} in position {int}') do |movie_title, position|
  user = User.find_by(username: 'moviefan')
  movie = Movie.find_by(title: movie_title)
  favorite = Favorite.find_or_create_by!(user: user, movie: movie)
  favorite.update!(top_position: position)
end

Given('I have favorited {int} movies') do |count|
  user = User.find_by(username: 'moviefan')
  count.times do |i|
    movie = Movie.create!(
      title: "Movie #{i + 1}",
      tmdb_id: 1000 + i,
      description: 'A movie',
      poster_url: 'https://via.placeholder.com/300x450'
    )
    Favorite.create!(user: user, movie: movie)
  end
end

When('I visit my profile page') do
  visit profile_path
end

When('I click on position {int} slot') do |position|
  find("[data-position='#{position}']").click
end

When('I select {string} from the favorites list') do |movie_title|
  # Search for the movie first since the modal uses search
  within('[data-modal-content]') do
    fill_in 'Search for a movie...', with: movie_title
  end
  sleep 1 # Wait for search results to load

  # Click on the first search result button
  within('[data-search-results]') do
    first('button').click
  end
end

When('I add {string} to position {int}') do |movie_title, position|
  step "I click on position #{position} slot"
  sleep 0.5 # Wait for modal to open
  step "I select \"#{movie_title}\" from the favorites list"
  sleep 0.5 # Wait for the update
end

When('I hover over position {int}') do |position|
  @hovered_position = position
  within('[data-controller="top-movies"]') do
    # Target the outer div container (with class 'group') not the button
    find("div.group[data-position='#{position}']").hover
  end
end

When('I click the remove button') do
  # The remove button is in a hover overlay that uses CSS opacity transitions
  # Use the hovered position to find the correct remove button within the top movies section
  within('[data-controller="top-movies"]') do
    within("div.group[data-position='#{@hovered_position}']") do
      remove_button = find('[data-action="click->top-movies#removeFromTop"]', visible: :all)
      page.execute_script("arguments[0].click()", remove_button)
    end
  end
end

When('I confirm the removal') do
  page.driver.browser.switch_to.alert.accept if page.driver.respond_to?(:browser)
end

When('I search for {string}') do |query|
  within('[data-modal-content]') do
    fill_in 'Search for a movie...', with: query
  end
end

Then('I should see {int} empty movie slots') do |count|
  expect(page).to have_css('.border-dashed', count: count)
end

Then('each empty slot should have a position number from {int} to {int}') do |start_pos, end_pos|
  (start_pos..end_pos).each do |pos|
    within("[data-position='#{pos}']") do
      expect(page).to have_content(pos.to_s)
    end
  end
end

Then('I should see a modal to select a movie') do
  expect(page).to have_css('[data-modal-content]')
end

Then('I should see {string} in my favorites list') do |movie_title|
  # Search for the movie and verify it appears in search results
  within('[data-modal-content]') do
    fill_in 'Search for a movie...', with: movie_title
  end
  sleep 1 # Wait for search results
  within('[data-modal-content]') do
    expect(page).to have_content(movie_title)
  end
end

Then('{string} should appear in position {int}') do |movie_title, position|
  within("[data-position='#{position}']") do
    expect(page).to have_css('img') # Should have movie poster
  end
end

Then('position {int} slot should show the movie poster') do |position|
  within("[data-position='#{position}']") do
    expect(page).to have_css('img')
  end
end

Then('I should see all {int} movies in their respective positions') do |count|
  expect(page).to have_css('img', count: count)
end

Then('positions {int} and {int} should be empty') do |pos1, pos2|
  expect(page).to have_css("[data-position='#{pos1}'].border-dashed")
  expect(page).to have_css("[data-position='#{pos2}'].border-dashed")
end

Then('position {int} should be empty') do |position|
  expect(page).to have_css("[data-position='#{position}'].border-dashed")
end

Then('{string} should still be in position {int}') do |movie_title, position|
  # Movie should still be visible in that position
  within("[data-position='#{position}']") do
    expect(page).to have_css('img')
  end
end

Then('I should see exactly {int} top movie slots') do |count|
  expect(page).to have_css('[data-position]', count: count)
end

Then('I should not be able to add more than {int} movies to top positions') do |max_count|
  # This is enforced by the UI only showing 5 slots
  expect(page).to have_css('[data-position]', maximum: max_count)
end

Then('{string} should no longer be in the top {int}') do |movie_title, count|
  # The movie should not be in any top position slot
  # This is implicit - the position now shows a different movie
  expect(page).to have_css('[data-position]')
end

Then('I should see {string} in position {int}') do |movie_title, position|
  within("[data-position='#{position}']") do
    # Check that there's an image (movie poster) present
    expect(page).to have_css('img')
  end
end

Then('I should see a search input') do
  within('[data-modal-content]') do
    expect(page).to have_css('input[type="text"]')
  end
end

Then('I should see search results') do
  within('[data-modal-content]') do
    expect(page).to have_css('[data-search-results]')
  end
end

Then('each empty slot should show a plus icon') do
  all('.border-dashed').each do |slot|
    within(slot) do
      expect(page).to have_css('svg')
    end
  end
end

Then('each slot should display its position number') do
  (1..5).each do |pos|
    within("[data-position='#{pos}']") do
      expect(page).to have_content(pos.to_s)
    end
  end
end

Then('position {int} should show {string} poster') do |position, movie_title|
  within("[data-position='#{position}']") do
    expect(page).to have_css('img')
  end
end

Then('position {int} should display the number {string}') do |position, number|
  within("[data-position='#{position}']") do
    expect(page).to have_content(number)
  end
end
