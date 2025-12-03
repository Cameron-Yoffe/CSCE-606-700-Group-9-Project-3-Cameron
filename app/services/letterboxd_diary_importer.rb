class LetterboxdDiaryImporter < LetterboxdImportBase
  private

  def import_row(row)
    movie_title = safe_string(row["Name"])
    return { status: :skipped } if movie_title.blank?

    watched_date = parse_date(row["Watched Date"]) || parse_date(row["Date"])
    return { status: :skipped } unless watched_date

    movie_year = parse_year(row["Year"])
    movie = find_or_create_movie(movie_title, movie_year)

    return { status: :skipped } unless movie

    if duplicate_entry?(movie, watched_date)
      return { status: :skipped }
    end

    diary_entry = user.diary_entries.build(
      movie: movie,
      watched_date: watched_date,
      rating: parsed_rating(row["Rating"]),
      mood: parsed_tags(row["Tags"]),
      content: build_content(row),
      rewatch: rewatch?(movie, row["Rewatch"])
    )

    if diary_entry.save
      { status: :imported }
    else
      { status: :error, message: diary_entry.errors.full_messages.to_sentence }
    end
  end

  def build_content(row)
    uri = safe_string(row["Letterboxd URI"])
    note = safe_string(row["Tags"]).presence
    base_message = "Imported from Letterboxd diary"

    return "#{base_message}." if uri.blank? && note.blank?
    return "#{base_message}: #{note}." if uri.blank?

    [ "#{base_message} (#{uri})", note.presence ].compact.join(". ")
  end

  def parsed_tags(value)
    value = safe_string(value)
    return if value.blank?

    value.split(",").map(&:strip).reject(&:blank?).join(", ")
  end

  def duplicate_entry?(movie, watched_date)
    user.diary_entries.exists?(movie: movie, watched_date: watched_date)
  end

  def rewatch?(movie, rewatch_column)
    rewatch_from_csv = rewatch_column.to_s.strip.casecmp("yes").zero?
    rewatch_from_history = user.diary_entries.exists?(movie: movie)

    rewatch_from_csv || rewatch_from_history
  end
end
