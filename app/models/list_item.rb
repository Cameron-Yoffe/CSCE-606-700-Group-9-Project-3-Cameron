class ListItem < ApplicationRecord
  belongs_to :list
  belongs_to :movie

  validates :list_id, presence: true
  validates :movie_id, presence: true
  validates :movie_id, uniqueness: { scope: :list_id }
end
