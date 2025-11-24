class MovieTag < ApplicationRecord
  # Associations
  belongs_to :movie
  belongs_to :tag

  # Validations
  validates :movie_id, presence: true
  validates :tag_id, presence: true
end
