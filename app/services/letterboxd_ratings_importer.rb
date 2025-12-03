class LetterboxdRatingsImporter < LetterboxdImportBase
  private

  def import_row(row)
    movie_title = safe_string(row["Name"])
    return { status: :skipped } if movie_title.blank?

    rating_value = parsed_rating(row["Rating"])
    return { status: :skipped } unless rating_value&.positive?

    movie_year = parse_year(row["Year"])
    movie = find_or_create_movie(movie_title, movie_year)
    return { status: :skipped } unless movie

    rating = user.ratings.find_or_initialize_by(movie: movie)
    return { status: :skipped } if rating.persisted?

    rating.value = rating_value
    rating.review = build_review(row)

    if rating.save
      { status: :imported }
    else
      { status: :error, message: rating.errors.full_messages.to_sentence }
    end
  end

  def build_review(row)
    uri = safe_string(row["Letterboxd URI"])
    return if uri.blank?

    "Imported from Letterboxd ratings (#{uri})"
  end
end
