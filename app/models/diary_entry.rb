class DiaryEntry < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :movie

  # Callbacks
  after_commit :enqueue_embedding_refresh

  # Validations
  validates :user_id, presence: true
  validates :movie_id, presence: true
  validates :content, presence: true, length: { minimum: 1, maximum: 5000 }
  validates :rating, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }, allow_nil: true
  validates :mood, length: { maximum: 50 }, allow_blank: true
  validates :watched_date, presence: true

  # Custom validation
  validate :watched_date_cannot_be_in_future

  private

  def watched_date_cannot_be_in_future
    if watched_date.present? && watched_date > Date.today
      errors.add(:watched_date, "can't be in the future")
    end
  end

  def enqueue_embedding_refresh
    return unless user_id

    RecomputeUserEmbeddingJob.perform_later(user_id)
  end
end
