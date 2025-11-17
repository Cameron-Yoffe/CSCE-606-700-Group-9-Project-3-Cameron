class Watchlist < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :movie

  # Validations
  validates :user_id, presence: true
  validates :movie_id, presence: true
  validates :status, presence: true, inclusion: { in: %w[to_watch watching watched] }
  validates :user_id, uniqueness: { scope: :movie_id, message: "can only have one entry per movie" }
end
