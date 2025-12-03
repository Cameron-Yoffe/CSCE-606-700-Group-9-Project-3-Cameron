class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :movie

  validates :user_id, presence: true
  validates :movie_id, presence: true
  validates :user_id, uniqueness: { scope: :movie_id, message: "has already favorited this movie" }
  validates :top_position, inclusion: { in: 1..5 }, allow_nil: true
  validates :top_position, uniqueness: { scope: :user_id }, allow_nil: true

  scope :top_movies, -> { where.not(top_position: nil).order(:top_position) }
  scope :regular_favorites, -> { where(top_position: nil) }
end
