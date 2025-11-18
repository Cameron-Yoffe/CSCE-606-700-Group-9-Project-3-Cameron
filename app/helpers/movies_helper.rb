module MoviesHelper
  IMAGE_BASE_URL = "https://image.tmdb.org/t/p".freeze

  def poster_url(path, size: "w342")
    return "https://placehold.co/300x450?text=No+Image" if path.blank?

    normalized_path = path.start_with?("/") ? path : "/#{path}"

    "#{IMAGE_BASE_URL}/#{size}#{normalized_path}"
  end

  def release_year(movie_hash)
    release_date = movie_hash["release_date"]
    return "N/A" if release_date.blank?

    Date.parse(release_date).year
  rescue Date::Error
    "N/A"
  end

  def director_name(movie_hash)
    credits = movie_hash.fetch("credits", {})
    crew = credits["crew"] || movie_hash["crew"]

    director_entries = Array(crew).select { |member| member["job"] == "Director" }
    if director_entries.any?
      return director_entries.map { |member| member["name"] }.uniq.join(", ")
    end

    movie_hash["director"].presence || "N/A"
  end
end
