class Rating < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :movie

  # Validations
  validates :user_id, presence: true
  validates :movie_id, presence: true
  validates :value, presence: true, inclusion: { in: (1..10).to_a }
  validates :review, length: { maximum: 5000 }, allow_blank: true
  validates :user_id, uniqueness: { scope: :movie_id, message: "can only have one rating per movie" }
end
