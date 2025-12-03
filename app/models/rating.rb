class Rating < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :movie
  has_many :review_reactions, dependent: :destroy

  # Callbacks
  before_validation :strip_review_whitespace
  after_commit :enqueue_embedding_refresh

  # Validations
  validates :user_id, presence: true
  validates :movie_id, presence: true
  validates :value, presence: true, inclusion: { in: (1..10).to_a }
  validates :review, length: { maximum: 5000 }, allow_blank: true
  validates :user_id, uniqueness: { scope: :movie_id, message: "can only have one rating per movie" }

  private

  def strip_review_whitespace
    if review.present?
      self.review = review.strip
      self.review = "" if review.empty?
    end
  end

  def enqueue_embedding_refresh
    return unless user_id

    RecomputeUserEmbeddingJob.perform_later(user_id)
  end
end
