# Step definitions for diary entry feature

Given('a movie {string} exists in the database') do |title|
  @movie = Movie.create!(
    title: title,
    tmdb_id: 27205,
    poster_url: 'https://image.tmdb.org/t/p/w500/test.jpg'
  )
end

When('I visit the new diary entry page for {string}') do |movie_title|
  movie = Movie.find_by(title: movie_title) || @movie
  visit new_diary_entry_path(movie_id: movie.id)
end

Then('I should see a date field defaulting to today') do
  date_field = find('input[type="date"]')
  expect(date_field.value).to eq(Date.today.to_s)
end

Then('I should see a notes field') do
  expect(page).to have_field('diary_entry[content]')
end

Then('I should see a tags field') do
  expect(page).to have_field('diary_entry[mood]')
end

When('I fill in the viewing date with {string}') do |date|
  fill_in 'diary_entry[watched_date]', with: date
end

When('I fill in notes with {string}') do |notes|
  fill_in 'diary_entry[content]', with: notes
end

When('I fill in tags with {string}') do |tags|
  fill_in 'diary_entry[mood]', with: tags
end

When('I submit the diary entry form') do
  click_button 'Save Diary Entry'
end

Then('I should be on the diary page') do
  expect(current_path).to eq(diary_entries_path)
end

Given('I have a diary entry for {string} watched on {string}') do |movie_title, date|
  movie = Movie.find_by(title: movie_title) || Movie.create!(
    title: movie_title,
    tmdb_id: 27205,
    poster_url: 'https://image.tmdb.org/t/p/w500/test.jpg'
  )
  @user.diary_entries.create!(
    movie: movie,
    watched_date: Date.parse(date),
    content: 'Great movie!'
  )
end

Given('I have the following diary entries:') do |table|
  table.hashes.each do |row|
    movie = Movie.find_by(title: row['movie']) || Movie.create!(
      title: row['movie'],
      tmdb_id: rand(10000..99999),
      poster_url: 'https://image.tmdb.org/t/p/w500/test.jpg'
    )
    @user.diary_entries.create!(
      movie: movie,
      watched_date: Date.parse(row['watched_date']),
      content: 'Great movie!'
    )
  end
end

When('I visit the diary page') do
  visit diary_entries_path
end

Then('I should see a movie poster') do
  expect(page).to have_css('img[src*="image.tmdb.org"]')
end

When('I click {string} for the diary entry') do |link_text|
  within('.grid', match: :first) do
    first('a', text: link_text).click
  end
end
