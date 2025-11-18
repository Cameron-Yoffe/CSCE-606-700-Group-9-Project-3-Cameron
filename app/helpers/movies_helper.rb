module MoviesHelper
  IMAGE_BASE_URL = "https://image.tmdb.org/t/p".freeze

  def poster_url(path, size: "w342")
    return "https://placehold.co/300x450?text=No+Image" if path.blank?

    URI.join(IMAGE_BASE_URL, "/#{size}/", path.delete_prefix("/")).to_s
  end

  def release_year(movie_hash)
    release_date = movie_hash["release_date"]
    return "N/A" if release_date.blank?

    Date.parse(release_date).year
  rescue Date::Error
    "N/A"
  end
end
