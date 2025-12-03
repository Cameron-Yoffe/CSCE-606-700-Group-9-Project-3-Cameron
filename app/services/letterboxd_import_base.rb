class LetterboxdImportBase
  TMDB_IMAGE_BASE = "https://image.tmdb.org/t/p".freeze
  DEFAULT_TMDB_COOLDOWN = 0.4

  ImportResult = Struct.new(:imported, :skipped, :errors, keyword_init: true)
  ImportError = Class.new(StandardError)

  def initialize(user, tmdb_cooldown: DEFAULT_TMDB_COOLDOWN)
    @user = user
    @tmdb_cooldown = tmdb_cooldown
    @last_tmdb_request_at = nil
  end

  def import(file)
    csv = ensure_csv_support!
    raise ImportError, "Please upload a CSV export from Letterboxd." unless valid_file?(file)

    imported = 0
    skipped = 0
    errors = []

    content = sanitize_encoding(file.read)

    csv.new(content, headers: true).each do |row|
      next if row.to_h.values.compact.all?(&:blank?)

      result = import_row(row)

      case result[:status]
      when :imported
        imported += 1
      when :skipped
        skipped += 1
      when :error
        errors << result[:message] if result[:message].present?
      end
    end

    ImportResult.new(imported: imported, skipped: skipped, errors: errors)
  rescue ImportError => e
    raise e
  rescue StandardError => e
    if defined?(csv) && e.is_a?(csv::MalformedCSVError)
      raise ImportError, "Could not read the CSV file: #{e.message}"
    end

    raise e
  end

  private

  attr_reader :user, :tmdb_cooldown, :last_tmdb_request_at

  def ensure_csv_support!
    require "csv"

    CSV
  rescue LoadError => e
    raise ImportError, "CSV parsing is unavailable: #{e.message}".strip
  end

  def sanitize_encoding(raw_content)
    return "" if raw_content.nil?

    raw_content.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
  end

  def parse_date(value)
    return if value.blank?

    Date.parse(value)
  rescue ArgumentError
    nil
  end

  def parse_year(value)
    return if value.blank?

    Integer(value, exception: false)
  end

  def safe_string(value)
    value.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "").strip
  rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
    ""
  end

  def parsed_rating(value)
    return nil if value.blank?

    rating = (value.to_f * 2).round
    rating.clamp(0, 10)
  end

  def build_release_date(year)
    return if year.blank?

    Date.new(year, 1, 1)
  rescue ArgumentError
    nil
  end

  def find_or_create_movie(title, year)
    normalized_title = safe_string(title).downcase

    existing = Movie.where("LOWER(title) = ?", normalized_title).find do |movie|
      year.blank? || movie.release_date&.year == year
    end

    if existing
      return enrich_movie_metadata(existing, title, year) if needs_metadata?(existing)

      return existing
    end

    tmdb_result = fetch_tmdb_match(title, year)

    if tmdb_result
      tmdb_id = tmdb_result["id"]
      existing_by_tmdb = tmdb_id.present? ? Movie.find_by(tmdb_id: tmdb_id) : nil

      attrs = build_tmdb_movie_attrs(tmdb_result, title, year)

      if existing_by_tmdb
        existing_by_tmdb.assign_attributes(attrs.compact)
        existing_by_tmdb.save if existing_by_tmdb.changed?
        return existing_by_tmdb
      end

      created = Movie.create(attrs)
      return created if created.persisted?
    end

    new_movie = Movie.create(
      title: safe_string(title),
      release_date: build_release_date(year)
    )

    new_movie if new_movie.persisted?
  end

  def fetch_tmdb_match(title, year)
    return unless tmdb_client

    apply_tmdb_cooldown

    params = { query: safe_string(title), include_adult: false }
    params[:year] = year if year.present?

    response = tmdb_client.get("/search/movie", params)
    Array(response["results"]).first
  rescue Tmdb::Error => e
    Rails.logger&.warn("TMDB lookup failed for '#{title}': #{e.message}")
    nil
  end

  def build_tmdb_movie_attrs(result, fallback_title, year)
    {
      tmdb_id: result["id"],
      title: safe_string(result["title"].presence || fallback_title),
      release_date: parse_tmdb_date(result["release_date"]) || build_release_date(year),
      poster_url: tmdb_image_url(result["poster_path"], size: "w342"),
      backdrop_url: tmdb_image_url(result["backdrop_path"], size: "w780"),
      description: safe_string(result["overview"]),
      vote_average: result["vote_average"],
      vote_count: result["vote_count"]
    }
  end

  def fetch_tmdb_movie(tmdb_id)
    return unless tmdb_client

    apply_tmdb_cooldown

    tmdb_client.get("/movie/#{tmdb_id}")
  rescue Tmdb::Error => e
    Rails.logger&.warn("TMDB detail lookup failed for ID #{tmdb_id}: #{e.message}")
    nil
  end

  def enrich_movie_metadata(movie, title, year)
    tmdb_result = movie.tmdb_id.present? ? fetch_tmdb_movie(movie.tmdb_id) : fetch_tmdb_match(title, year)
    return movie unless tmdb_result

    attrs = build_tmdb_movie_attrs(tmdb_result, movie.title.presence || title, year)
    movie.assign_attributes(attrs.compact)
    movie.save if movie.changed?
    movie
  end

  def needs_metadata?(movie)
    movie.tmdb_id.blank? || movie.poster_url.blank? || movie.backdrop_url.blank?
  end

  def parse_tmdb_date(value)
    return if value.blank?

    Date.parse(value)
  rescue Date::Error
    nil
  end

  def tmdb_image_url(path, size: "w342")
    return if path.blank?

    normalized_path = path.start_with?("/") ? path : "/#{path}"
    "#{TMDB_IMAGE_BASE}/#{size}#{normalized_path}"
  end

  def valid_file?(file)
    file.respond_to?(:read) && file.respond_to?(:size) && file.size.to_i.positive?
  end

  def tmdb_client
    @tmdb_client ||= Tmdb::Client.new
  rescue Tmdb::AuthenticationError => e
    Rails.logger&.warn("TMDB authentication failed: #{e.message}")
    nil
  end

  def apply_tmdb_cooldown
    return if tmdb_cooldown.to_f.negative? || tmdb_cooldown.to_f.zero?

    now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    if last_tmdb_request_at
      elapsed = now - last_tmdb_request_at
      sleep_time = tmdb_cooldown - elapsed
      sleep(sleep_time) if sleep_time.positive?
    end

    @last_tmdb_request_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end
