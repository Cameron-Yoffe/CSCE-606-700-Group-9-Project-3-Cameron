require "json"

class Movie < ApplicationRecord
  attribute :movie_embedding, :json, default: {}

  # Associations
  has_many :diary_entries, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :ratings, dependent: :destroy
  has_many :watchlists, dependent: :destroy
  has_many :users, through: :watchlists
  has_many :list_items, dependent: :destroy
  has_many :lists, through: :list_items
  has_many :movie_tags, dependent: :destroy
  has_many :tags, through: :movie_tags

  # Validations
  validates :title, presence: true, length: { minimum: 1, maximum: 255 }
  validates :tmdb_id, uniqueness: true, allow_nil: true
  validates :vote_average, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }, allow_nil: true
  validates :runtime, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  def genre_names
    raw_genres = genres

    parsed = case raw_genres
    when String
               begin
                 JSON.parse(raw_genres)
               rescue JSON::ParserError
                 raw_genres.split(",").map(&:strip)
               end
    else
               raw_genres
    end

    Array(parsed).filter_map do |genre|
      if genre.is_a?(Hash)
        genre["name"] || genre[:name]
      else
        genre.presence&.to_s
      end
    end
  end

  # Returns the poster URL, fetching from TMDB if missing and tmdb_id is available
  def poster_image_url(size: "w342")
    # If we have a poster_url, return it (will be validated on display)
    return poster_url if poster_url.present?

    # Try to fetch from TMDB if we have a tmdb_id
    if tmdb_id.present?
      fetch_poster_from_tmdb(size)
    else
      nil
    end
  end

  # Force refresh the poster URL from TMDB
  def refresh_poster_url!(size: "w500")
    return nil unless tmdb_id.present?

    fetch_poster_from_tmdb(size)
  end

  def recompute_embedding!(idf_lookup: nil)
    Recommender::MovieEmbedding.build_and_persist!(self, idf_lookup: idf_lookup)
  end

  private

  def fetch_poster_from_tmdb(size = "w342")
    client = Tmdb::Client.new
    movie_data = client.movie(tmdb_id)

    if movie_data["poster_path"].present?
      new_poster_url = "https://image.tmdb.org/t/p/#{size}#{movie_data["poster_path"]}"
      update_column(:poster_url, new_poster_url)
      new_poster_url
    end
  rescue Tmdb::Error => e
    Rails.logger.warn("Failed to fetch poster for movie #{id} (tmdb_id: #{tmdb_id}): #{e.message}")
    nil
  end
end
