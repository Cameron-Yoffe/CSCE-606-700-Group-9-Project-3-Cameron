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
end
