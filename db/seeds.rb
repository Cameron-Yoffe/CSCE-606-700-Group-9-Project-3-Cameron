# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Clear existing data to ensure idempotency
[Rating, DiaryEntry, Watchlist, Movie, User].each(&:delete_all)

# For development seeding, use a simple password digest (in production, use proper authentication)
# Note: These are for development only. In production, use proper password hashing.
def create_password_digest(password)
  # Simple placeholder for development - in production, use bcrypt
  password
end

# Create sample users
users = [
  User.create!(
    email: 'alice@example.com',
    username: 'alice',
    password_digest: create_password_digest('password123'),
    first_name: 'Alice',
    last_name: 'Johnson',
    bio: 'Movie enthusiast and critic'
  ),
  User.create!(
    email: 'bob@example.com',
    username: 'bob',
    password_digest: create_password_digest('password123'),
    first_name: 'Bob',
    last_name: 'Smith',
    bio: 'Lover of action and sci-fi films'
  ),
  User.create!(
    email: 'charlie@example.com',
    username: 'charlie',
    password_digest: create_password_digest('password123'),
    first_name: 'Charlie',
    last_name: 'Brown',
    bio: 'Documentary and indie film fan'
  )
]

# Create sample movies
movies = [
  Movie.create!(
    title: 'The Shawshank Redemption',
    description: 'Two imprisoned men bond over a number of years, finding solace and eventual redemption through acts of common decency.',
    tmdb_id: 278,
    poster_url: 'https://image.tmdb.org/t/p/w500/q6y0Go1tsGEsmJFQnfezrggcSzX.jpg',
    vote_average: 8.7,
    vote_count: 25000,
    release_date: Date.parse('1994-10-14'),
    runtime: 142,
    genres: ['Drama'],
    director: 'Frank Darabont',
    cast: ['Tim Robbins', 'Morgan Freeman']
  ),
  Movie.create!(
    title: 'The Dark Knight',
    description: 'When the menace known as the Joker wreaks havoc and chaos on the people of Gotham, Batman must accept one of the greatest psychological tests.',
    tmdb_id: 155,
    poster_url: 'https://image.tmdb.org/t/p/w500/1hqwGsG1DKJhw6UqJF2CYty217D.jpg',
    vote_average: 9.0,
    vote_count: 28000,
    release_date: Date.parse('2008-07-18'),
    runtime: 152,
    genres: ['Action', 'Crime', 'Drama'],
    director: 'Christopher Nolan',
    cast: ['Christian Bale', 'Heath Ledger', 'Aaron Eckhart']
  ),
  Movie.create!(
    title: 'Inception',
    description: 'A skilled thief who steals corporate secrets through the use of dream-sharing technology is given the inverse task of planting an idea.',
    tmdb_id: 27205,
    poster_url: 'https://image.tmdb.org/t/p/w500/9gk7adHYeDMPS6QyJQtjwa414Fc.jpg',
    vote_average: 8.8,
    vote_count: 32000,
    release_date: Date.parse('2010-07-16'),
    runtime: 148,
    genres: ['Action', 'Sci-Fi', 'Thriller'],
    director: 'Christopher Nolan',
    cast: ['Leonardo DiCaprio', 'Marion Cotillard', 'Ellen Page']
  ),
  Movie.create!(
    title: 'Forrest Gump',
    description: 'The presidencies of Kennedy and Johnson, the Vietnam War, and other historical events unfold from the perspective of an Alabama man with a low IQ.',
    tmdb_id: 13,
    poster_url: 'https://image.tmdb.org/t/p/w500/clnuiX3ow5dunEmlVoIE8D8TPMd.jpg',
    vote_average: 8.8,
    vote_count: 24000,
    release_date: Date.parse('1994-07-06'),
    runtime: 142,
    genres: ['Drama', 'Romance'],
    director: 'Robert Zemeckis',
    cast: ['Tom Hanks', 'Sally Field', 'Gary Sinise']
  ),
  Movie.create!(
    title: 'Pulp Fiction',
    description: 'The lives of two mob hitmen, a boxer, a gangster and his wife intertwine in four tales of violence and redemption.',
    tmdb_id: 680,
    poster_url: 'https://image.tmdb.org/t/p/w500/plnlrtTVYsGLwUwO0K1OSY3fqVm.jpg',
    vote_average: 8.9,
    vote_count: 27000,
    release_date: Date.parse('1994-10-14'),
    runtime: 154,
    genres: ['Crime', 'Drama'],
    director: 'Quentin Tarantino',
    cast: ['John Travolta', 'Uma Thurman', 'Samuel L. Jackson']
  )
]

# Create sample watchlist entries
watchlist_data = [
  { user: users[0], movie: movies[0], status: 'watched' },
  { user: users[0], movie: movies[1], status: 'watched' },
  { user: users[0], movie: movies[2], status: 'to_watch' },
  { user: users[1], movie: movies[1], status: 'watched' },
  { user: users[1], movie: movies[3], status: 'watching' },
  { user: users[2], movie: movies[4], status: 'watched' },
  { user: users[2], movie: movies[0], status: 'to_watch' }
]

watchlist_data.each do |data|
  Watchlist.create!(
    user: data[:user],
    movie: data[:movie],
    status: data[:status]
  )
end

# Create sample ratings
rating_data = [
  { user: users[0], movie: movies[0], value: 10, review: 'Absolutely masterful. A true masterpiece of cinema.' },
  { user: users[0], movie: movies[1], value: 9, review: 'Heath Ledger\'s performance is unforgettable. Amazing film.' },
  { user: users[1], movie: movies[1], value: 9, review: 'One of the best superhero movies ever made.' },
  { user: users[2], movie: movies[4], value: 8, review: 'Brilliant screenplay and direction by Tarantino.' }
]

rating_data.each do |data|
  Rating.create!(
    user: data[:user],
    movie: data[:movie],
    value: data[:value],
    review: data[:review]
  )
end

# Create sample diary entries
diary_data = [
  {
    user: users[0],
    movie: movies[0],
    content: 'Watched The Shawshank Redemption for the third time today. The cinematography and storytelling are simply perfect. I found myself moved by the ending once again.',
    watched_date: 2.days.ago.to_date,
    mood: 'reflective',
    rating: 10
  },
  {
    user: users[0],
    movie: movies[1],
    content: 'The Dark Knight was intense! Heath Ledger\'s Joker is absolutely terrifying and captivating. This film explores the duality of morality beautifully.',
    watched_date: 5.days.ago.to_date,
    mood: 'excited',
    rating: 9
  },
  {
    user: users[1],
    movie: movies[1],
    content: 'Finally rewatched The Dark Knight. Still holds up remarkably well. The action sequences are top-notch.',
    watched_date: 10.days.ago.to_date,
    mood: 'entertained',
    rating: 9
  },
  {
    user: users[2],
    movie: movies[4],
    content: 'Pulp Fiction is a masterpiece of non-linear storytelling. Every scene is memorable and the dialogue is sharp and witty.',
    watched_date: 7.days.ago.to_date,
    mood: 'inspired',
    rating: 8
  }
]

diary_data.each do |data|
  DiaryEntry.create!(
    user: data[:user],
    movie: data[:movie],
    content: data[:content],
    watched_date: data[:watched_date],
    mood: data[:mood],
    rating: data[:rating]
  )
end

puts "✅ Database seeded successfully!"
puts "Created #{User.count} users"
puts "Created #{Movie.count} movies"
puts "Created #{Watchlist.count} watchlist entries"
puts "Created #{Rating.count} ratings"
puts "Created #{DiaryEntry.count} diary entries"
