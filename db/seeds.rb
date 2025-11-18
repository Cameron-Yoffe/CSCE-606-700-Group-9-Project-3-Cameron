# This seed file prepares a richly populated demo profile with hundreds of diary entries
# spanning multiple years, realistic TMDb movie IDs, and credentials for easy login.

require "date"

# Clear existing data to keep the seed idempotent
[Rating, DiaryEntry, Watchlist, Movie, User].each(&:delete_all)

movies_data = [
  {
    title: "The Dark Knight",
    description: "Batman faces the Joker in a fight for Gotham's soul.",
    tmdb_id: 155,
    poster_url: "https://image.tmdb.org/t/p/w500/1hqwGsG1DKJhw6UqJF2CYty217D.jpg",
    vote_average: 9.0,
    vote_count: 28000,
    release_date: Date.parse("2008-07-18"),
    runtime: 152,
    genres: %w[Action Crime Drama],
    director: "Christopher Nolan",
    cast: ["Christian Bale", "Heath Ledger", "Aaron Eckhart"]
  },
  {
    title: "Inception",
    description: "A thief steals corporate secrets through dream-sharing technology.",
    tmdb_id: 27205,
    poster_url: "https://image.tmdb.org/t/p/w500/9gk7adHYeDMPS6QyJQtjwa414Fc.jpg",
    vote_average: 8.8,
    vote_count: 32000,
    release_date: Date.parse("2010-07-16"),
    runtime: 148,
    genres: %w[Action Science Fiction Thriller],
    director: "Christopher Nolan",
    cast: ["Leonardo DiCaprio", "Marion Cotillard", "Elliot Page"]
  },
  {
    title: "Interstellar",
    description: "Explorers travel through a wormhole in space to ensure humanity's survival.",
    tmdb_id: 157336,
    poster_url: "https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg",
    vote_average: 8.6,
    vote_count: 28000,
    release_date: Date.parse("2014-11-07"),
    runtime: 169,
    genres: %w[Adventure Drama Science Fiction],
    director: "Christopher Nolan",
    cast: ["Matthew McConaughey", "Anne Hathaway", "Jessica Chastain"]
  },
  {
    title: "Whiplash",
    description: "A young drummer is pushed to the limit by an abusive instructor.",
    tmdb_id: 244786,
    poster_url: "https://image.tmdb.org/t/p/w500/oPxnRhyAIzJKGUEdSiwTJQBa3NM.jpg",
    vote_average: 8.4,
    vote_count: 18000,
    release_date: Date.parse("2014-10-10"),
    runtime: 107,
    genres: %w[Drama Music],
    director: "Damien Chazelle",
    cast: ["Miles Teller", "J.K. Simmons", "Melissa Benoist"]
  },
  {
    title: "Parasite",
    description: "A poor family schemes to become employed by a wealthy household.",
    tmdb_id: 496243,
    poster_url: "https://image.tmdb.org/t/p/w500/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg",
    vote_average: 8.5,
    vote_count: 19000,
    release_date: Date.parse("2019-05-30"),
    runtime: 133,
    genres: %w[Comedy Drama Thriller],
    director: "Bong Joon-ho",
    cast: ["Song Kang-ho", "Lee Sun-kyun", "Cho Yeo-jeong"]
  },
  {
    title: "Mad Max: Fury Road",
    description: "Max teams up with Furiosa to escape a tyrant and his army.",
    tmdb_id: 76341,
    poster_url: "https://image.tmdb.org/t/p/w500/8tZYtuWezp8JbcsvHYO0O46tFbo.jpg",
    vote_average: 8.1,
    vote_count: 19000,
    release_date: Date.parse("2015-05-15"),
    runtime: 120,
    genres: %w[Action Adventure Science Fiction],
    director: "George Miller",
    cast: ["Tom Hardy", "Charlize Theron", "Nicholas Hoult"]
  },
  {
    title: "La La Land",
    description: "An aspiring actress and a jazz musician fall in love in Los Angeles.",
    tmdb_id: 313369,
    poster_url: "https://image.tmdb.org/t/p/w500/uDO8zWDhfWwoFdKS4fzkUJt0Rf0.jpg",
    vote_average: 8.0,
    vote_count: 18000,
    release_date: Date.parse("2016-12-09"),
    runtime: 128,
    genres: %w[Comedy Drama Romance],
    director: "Damien Chazelle",
    cast: ["Ryan Gosling", "Emma Stone", "John Legend"]
  },
  {
    title: "The Social Network",
    description: "The founding of Facebook brings fame and lawsuits to Mark Zuckerberg.",
    tmdb_id: 37799,
    poster_url: "https://image.tmdb.org/t/p/w500/q0zP5Rf5iwzW5D3PHIdTn6qU3ix.jpg",
    vote_average: 7.9,
    vote_count: 16000,
    release_date: Date.parse("2010-10-01"),
    runtime: 120,
    genres: %w[Drama],
    director: "David Fincher",
    cast: ["Jesse Eisenberg", "Andrew Garfield", "Justin Timberlake"]
  },
  {
    title: "Spirited Away",
    description: "A young girl enters a world of spirits and must save her parents.",
    tmdb_id: 129,
    poster_url: "https://image.tmdb.org/t/p/w500/oRvMaJOmapypFUcQqpgHMZA6qL9.jpg",
    vote_average: 8.5,
    vote_count: 16000,
    release_date: Date.parse("2001-07-20"),
    runtime: 125,
    genres: %w[Animation Family Fantasy],
    director: "Hayao Miyazaki",
    cast: ["Rumi Hiiragi", "Miyu Irino", "Mari Natsuki"]
  },
  {
    title: "The Godfather",
    description: "The aging patriarch of an organized crime dynasty transfers control to his reluctant son.",
    tmdb_id: 238,
    poster_url: "https://image.tmdb.org/t/p/w500/3bhkrj58Vtu7enYsRolD1fZdja1.jpg",
    vote_average: 8.7,
    vote_count: 20000,
    release_date: Date.parse("1972-03-14"),
    runtime: 175,
    genres: %w[Crime Drama],
    director: "Francis Ford Coppola",
    cast: ["Marlon Brando", "Al Pacino", "James Caan"]
  },
  {
    title: "Everything Everywhere All at Once",
    description: "An exhausted laundromat owner discovers parallel universes and must save the world.",
    tmdb_id: 545611,
    poster_url: "https://image.tmdb.org/t/p/w500/wwBzCSnVCeNnEi5VSZVB2WVAiQ0.jpg",
    vote_average: 8.0,
    vote_count: 13000,
    release_date: Date.parse("2022-03-11"),
    runtime: 139,
    genres: %w[Action Adventure Science Fiction],
    director: "Daniel Kwan & Daniel Scheinert",
    cast: ["Michelle Yeoh", "Ke Huy Quan", "Stephanie Hsu"]
  },
  {
    title: "Dune",
    description: "Paul Atreides leads nomadic tribes in a battle for Arrakis.",
    tmdb_id: 438631,
    poster_url: "https://image.tmdb.org/t/p/w500/d5NXSklXo0qyIYkgV94XAgMIckC.jpg",
    vote_average: 8.1,
    vote_count: 14000,
    release_date: Date.parse("2021-10-22"),
    runtime: 155,
    genres: %w[Science Fiction Adventure],
    director: "Denis Villeneuve",
    cast: ["Timothée Chalamet", "Rebecca Ferguson", "Oscar Isaac"]
  },
  {
    title: "Arrival",
    description: "A linguist works with the military to communicate with alien lifeforms.",
    tmdb_id: 329865,
    poster_url: "https://image.tmdb.org/t/p/w500/x2FJsf1ElAgr63Y3PNPtJrcmpoe.jpg",
    vote_average: 7.9,
    vote_count: 16000,
    release_date: Date.parse("2016-11-11"),
    runtime: 116,
    genres: %w[Drama Science Fiction Mystery],
    director: "Denis Villeneuve",
    cast: ["Amy Adams", "Jeremy Renner", "Forest Whitaker"]
  },
  {
    title: "Blade Runner 2049",
    description: "A young blade runner discovers a secret that leads him to Rick Deckard.",
    tmdb_id: 335984,
    poster_url: "https://image.tmdb.org/t/p/w500/ztZ4vw151mw04Bg6rqJLQGBAmvn.jpg",
    vote_average: 8.0,
    vote_count: 13000,
    release_date: Date.parse("2017-10-06"),
    runtime: 164,
    genres: %w[Science Fiction Drama],
    director: "Denis Villeneuve",
    cast: ["Ryan Gosling", "Harrison Ford", "Ana de Armas"]
  },
  {
    title: "The Grand Budapest Hotel",
    description: "The adventures of a legendary concierge and his lobby boy.",
    tmdb_id: 120467,
    poster_url: "https://image.tmdb.org/t/p/w500/nX5XotM9yprCKarRH4fzOq1VM1J.jpg",
    vote_average: 8.1,
    vote_count: 14000,
    release_date: Date.parse("2014-03-28"),
    runtime: 99,
    genres: %w[Comedy Drama],
    director: "Wes Anderson",
    cast: ["Ralph Fiennes", "Tony Revolori", "Saoirse Ronan"]
  },
  {
    title: "Top Gun: Maverick",
    description: "Maverick trains a new generation of Top Gun graduates for a dangerous mission.",
    tmdb_id: 361743,
    poster_url: "https://image.tmdb.org/t/p/w500/62HCnUTziyWcpDaBO2i1DX17ljH.jpg",
    vote_average: 8.2,
    vote_count: 12000,
    release_date: Date.parse("2022-05-27"),
    runtime: 131,
    genres: %w[Action Drama],
    director: "Joseph Kosinski",
    cast: ["Tom Cruise", "Miles Teller", "Jennifer Connelly"]
  }
]

movies = movies_data.map { |attrs| Movie.create!(attrs) }

test_user = User.create!(
  email: "reveille@example.com",
  username: "reveille",
  password: "Password123",
  password_confirmation: "Password123",
  first_name: "Reveille",
  last_name: "IX",
  bio: "Howdy! I'm the dog and this is my movie diary",
  profile_image_url: "https://upload.wikimedia.org/wikipedia/commons/f/ff/Reveille-TAMU-Mascot.JPG"
)

# Backdate the join date for a more established profile feel
test_user.update_column(:created_at, Date.new(Date.today.year - 6, 11, 18))

# Seed ratings to enrich the average rating calculation
movies.sample(12).each do |movie|
  Rating.create!(
    user: test_user,
    movie: movie,
    value: rand(6..10),
    review: "Enjoyed revisiting #{movie.title}; noting thoughts for charting seeds."
  )
end

moods = %w[nostalgic excited thrilled thoughtful curious amused tense delighted reflective mellow]
current_year = Date.today.year
entries_per_year = 30
max_date = Date.new(current_year, 11, 1)
years = (current_year - 6..current_year).to_a

def random_date_for_year(year, max_date)
  if year == max_date.year
    month = rand(1..max_date.month)
    last_day_of_month = Date.civil(year, month, -1).day
    day_limit = month == max_date.month ? [max_date.day, last_day_of_month].min : last_day_of_month
    Date.new(year, month, rand(1..day_limit))
  else
    month = rand(1..12)
    last_day_of_month = Date.civil(year, month, -1).day
    Date.new(year, month, rand(1..last_day_of_month))
  end
end

diary_dates = years.flat_map do |year|
  Array.new(entries_per_year) { random_date_for_year(year, max_date) }
end.sort

diary_dates.each_with_index do |watched_date, index|
  movie = movies.sample
  DiaryEntry.create!(
    user: test_user,
    movie: movie,
    content: "Entry ##{index + 1}: Rewatched #{movie.title} and spotted new details for the diary.",
    watched_date: watched_date,
    mood: moods.sample,
    rating: rand(5..10)
  )
end

puts "✅ Database seeded successfully!"
puts "Seed login: email=reveille@example.com password=Password123"
puts "Created #{User.count} users"
puts "Created #{Movie.count} movies"
puts "Created #{Rating.count} ratings"
puts "Created #{DiaryEntry.count} diary entries"
