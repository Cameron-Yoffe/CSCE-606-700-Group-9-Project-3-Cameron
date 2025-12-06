Given('I have rated the following movies:') do |table|
  @user ||= User.create!(email: 'testuser@example.com', username: 'testuser', password: 'ValidPass123', password_confirmation: 'ValidPass123')
  @user.ratings.destroy_all

  table.hashes.each_with_index do |row, index|
    movie = Movie.find_or_create_by!(title: row['title']) do |m|
      m.tmdb_id = row['tmdb_id'] || 10_000 + index
      m.release_date = Date.new(row['year'].to_i, 1, 1) if row['year']
      m.director = 'Unknown'
    end

    Rating.create!(user: @user, movie: movie, value: row['rating'].to_i)
  end
end

Given('I have recommendations ready:') do |table|
  @user ||= User.create!(email: 'testuser@example.com', username: 'testuser', password: 'ValidPass123', password_confirmation: 'ValidPass123')
  @user.recommendation_runs.destroy_all

  movies = table.hashes.each_with_index.map do |row, index|
    Movie.find_or_create_by!(tmdb_id: row['tmdb_id'] || 20_000 + index) do |movie|
      movie.title = row['title']
      movie.release_date = Date.new(row['year'].to_i, 1, 1) if row['year']
      movie.director = 'Unknown'
      movie.poster_url = 'https://image.tmdb.org/t/p/w500/test.jpg'
    end
  end

  serialized_movies = movies.map { |movie| Recommender::MovieSerializer.call(movie) }

  @user.recommendation_runs.create!(
    status: RecommendationRun::STATUSES[:completed],
    movies: serialized_movies,
    completed_at: Time.current
  )
end

Given('I have a pending recommendation run') do
  @user ||= User.create!(email: 'testuser@example.com', username: 'testuser', password: 'ValidPass123', password_confirmation: 'ValidPass123')
  @user.recommendation_runs.destroy_all
  @user.recommendation_runs.create!(status: RecommendationRun::STATUSES[:pending])
end

When('I visit the recommendations page') do
  visit recommendations_path
end

Then('I should see {int} recommendations in the deck') do |count|
  expect(page).to have_content("#{count} in deck")
end

Then('I should see that recommendations are being prepared') do
  expect(page).to have_content('Finding suggestions for you...')
end

Then('I should see a reload suggestions button') do
  expect(page).to have_button('Reload suggestions')
end
