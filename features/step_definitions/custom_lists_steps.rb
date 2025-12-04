Given('I have a custom list named {string} with movie {string}') do |list_name, movie_title|
  @user ||= User.first || create(:user, email: 'customlist@example.com', username: 'customlistuser', password: 'ValidPass123', password_confirmation: 'ValidPass123')
  movie = Movie.find_or_create_by!(title: movie_title) do |m|
    m.tmdb_id = rand(100_000..999_999)
    m.poster_url = 'https://image.tmdb.org/t/p/w500/test.jpg'
  end

  list = @user.lists.create!(name: list_name, description: "Test list")
  list.list_items.create!(movie: movie)
end

When('I open the new list modal') do
  find('#new-list-toggle').click
end

When('I fill out the new list form with name {string} and description {string}') do |name, description|
  within('#new-list-modal') do
    fill_in 'Name', with: name
    fill_in 'Description', with: description
  end
end

When('I submit the new list form') do
  within('#new-list-modal') do
    click_button 'Create list'
  end
end

When('I switch to the {string} list tab') do |list_name|
  find("[data-tab-target^='list-']", text: list_name).click
end

When('I delete the current custom list') do
  click_button 'Delete list'
end

Then('I should see a tab for list {string}') do |list_name|
  expect(page).to have_selector('[data-tab-target]', text: list_name)
end
