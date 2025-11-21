class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :movie

  validates :user_id, presence: true
  validates :movie_id, presence: true
  validates :user_id, uniqueness: { scope: :movie_id, message: "has already favorited this movie" }
end
