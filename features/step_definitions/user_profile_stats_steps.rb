# Step definitions for US-108: User Profile Page + Stats

Given("the following profile user exists:") do |table|
  table.hashes.each do |row|
    @profile_user = User.create!(
      email: row['email'],
      username: row['username'],
      password: row['password'],
      password_confirmation: row['password'],
      bio: row['bio']
    )
  end
end

Given("I am signed in as profile user {string} with password {string}") do |username, password|
  @profile_user = User.find_by(username: username)
  visit sign_in_path
  fill_in 'email', with: @profile_user.email
  fill_in 'password', with: password
  click_button 'Sign In'
end

When("I visit my user profile page") do
  visit profile_path
end

Then("I should see the username {string} on the profile") do |username|
  expect(page).to have_css("h1", text: username)
end

Then("I should see the bio {string} on the profile") do |bio|
  expect(page).to have_content(bio)
end

Then("I should see an avatar placeholder with the letter {string}") do |letter|
  expect(page).to have_css(".rounded-full", text: letter)
end

Given("the profile user has logged {int} diary entries") do |count|
  count.times do |i|
    movie = Movie.create!(
      tmdb_id: 1000 + i,
      title: "Test Movie #{i}",
      description: "A test movie",
      poster_url: "https://example.com/poster#{i}.jpg",
      release_date: Date.today - i.days
    )
    DiaryEntry.create!(
      user: @profile_user,
      movie: movie,
      content: "Watched this movie",
      watched_date: Date.today - i.days
    )
  end
end

Then("I should see {string} stat section") do |section_title|
  expect(page).to have_content(section_title)
end

Then("I should see the diary count {string}") do |count|
  within(".card", text: "Diary entries") do
    expect(page).to have_content(count)
  end
end

Given("the profile user has logged {int} movies this year") do |count|
  count.times do |i|
    movie = Movie.create!(
      tmdb_id: 2000 + i,
      title: "Year Movie #{i}",
      description: "A movie from this year",
      poster_url: "https://example.com/poster#{i}.jpg",
      release_date: Date.today - i.days
    )
    DiaryEntry.create!(
      user: @profile_user,
      movie: movie,
      content: "Watched this year",
      watched_date: Date.today - i.days
    )
  end
end

Then("I should see the yearly count {string}") do |count|
  within(".card", text: "This year") do
    expect(page).to have_content(count)
  end
end

Given("the profile user has rated movies with an average of {float}") do |average|
  # Create movies and ratings to approximate the average
  5.times do |i|
    movie = Movie.create!(
      tmdb_id: 3000 + i,
      title: "Rated Movie #{i}",
      description: "A rated movie",
      poster_url: "https://example.com/poster#{i}.jpg"
    )
    Rating.create!(
      user: @profile_user,
      movie: movie,
      value: (average + (i % 2 == 0 ? 0.5 : -0.5)).round.to_i.clamp(1, 10)
    )
  end
end

Then("I should see the average rating displayed") do
  within(".card", text: "Average rating") do
    expect(page).to have_css(".text-4xl")
  end
end

Given("the profile user has logged movies with genres:") do |table|
  table.hashes.each do |row|
    row['count'].to_i.times do |i|
      movie = Movie.create!(
        tmdb_id: 4000 + rand(10000),
        title: "#{row['genre']} Movie #{i}",
        description: "A #{row['genre'].downcase} movie",
        poster_url: "https://example.com/poster.jpg",
        genres: [ row['genre'] ].to_json,
        director: "Some Director"
      )
      DiaryEntry.create!(
        user: @profile_user,
        movie: movie,
        content: "Watched this #{row['genre'].downcase} movie",
        watched_date: Date.today - i.days
      )
    end
  end
end

Then("I should see {string} section") do |section_title|
  expect(page).to have_content(section_title)
end

Then("I should see {string} in the favorite genres") do |genre|
  within(".card", text: "Favorite genres") do
    expect(page).to have_content(genre)
  end
end

Then("I should see {string} badge") do |badge_text|
  expect(page).to have_css(".badge", text: badge_text)
end

Given("the profile user has logged movies directed by:") do |table|
  table.hashes.each do |row|
    row['count'].to_i.times do |i|
      movie = Movie.create!(
        tmdb_id: 5000 + rand(10000),
        title: "#{row['director']} Film #{i}",
        description: "A film by #{row['director']}",
        poster_url: "https://example.com/poster.jpg",
        director: row['director']
      )
      DiaryEntry.create!(
        user: @profile_user,
        movie: movie,
        content: "Watched this film",
        watched_date: Date.today - i.days
      )
    end
  end
end

Then("I should see {string} in the favorite directors") do |director|
  within(".card", text: "Favorite directors") do
    expect(page).to have_content(director)
  end
end

Given("the profile user has logged movies this year") do
  3.times do |i|
    movie = Movie.create!(
      tmdb_id: 6000 + i,
      title: "This Year Movie #{i}",
      description: "A movie",
      poster_url: "https://example.com/poster.jpg",
      genres: [ "Action" ].to_json
    )
    DiaryEntry.create!(
      user: @profile_user,
      movie: movie,
      content: "Watched",
      watched_date: Date.new(Date.current.year, (i % 12) + 1, 15)
    )
  end
end

Then("I should see a bar chart canvas") do
  expect(page).to have_css("canvas[data-chart-type-value='bar']")
end

Given("the profile user has logged movies with multiple genres") do
  genres = [ "Action", "Drama", "Comedy", "Thriller" ]
  genres.each_with_index do |genre, i|
    movie = Movie.create!(
      tmdb_id: 7000 + i,
      title: "#{genre} Film",
      description: "A #{genre.downcase} film",
      poster_url: "https://example.com/poster.jpg",
      genres: [ genre ].to_json
    )
    DiaryEntry.create!(
      user: @profile_user,
      movie: movie,
      content: "Watched",
      watched_date: Date.today - i.days
    )
  end
end

Then("I should see a pie chart canvas") do
  expect(page).to have_css("canvas[data-chart-type-value='pie']")
end

Given("the profile user has {int} followers") do |count|
  count.times do |i|
    follower = User.create!(
      email: "follower#{i}@example.com",
      username: "follower#{i}",
      password: "Password123",
      password_confirmation: "Password123"
    )
    Follow.create!(follower: follower, followed: @profile_user, status: "accepted")
  end
end

Given("the profile user is following {int} users") do |count|
  count.times do |i|
    followed = User.create!(
      email: "followed#{i}@example.com",
      username: "followed#{i}",
      password: "Password123",
      password_confirmation: "Password123"
    )
    Follow.create!(follower: @profile_user, followed: followed, status: "accepted")
  end
end

Then("I should see {string} followers count") do |count|
  expect(page).to have_css("a", text: /#{count}.*followers/i)
end

Then("I should see {string} following count") do |count|
  expect(page).to have_css("a", text: /#{count}.*following/i)
end

Then("I should see {string} on the profile") do |text|
  expect(page).to have_content(text)
end

Then("I should see an {string} link") do |link_text|
  expect(page).to have_link(link_text)
end
