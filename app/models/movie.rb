require "json"

class Movie < ApplicationRecord
  # Associations
  has_many :diary_entries, dependent: :destroy
  has_many :ratings, dependent: :destroy
  has_many :watchlists, dependent: :destroy
  has_many :users, through: :watchlists

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
end
