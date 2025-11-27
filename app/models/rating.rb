class Rating < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :movie
  has_many :review_reactions, dependent: :destroy

  # Callbacks
  before_validation :strip_review_whitespace

  # Validations
  validates :user_id, presence: true
  validates :movie_id, presence: true
  validates :value, presence: true, inclusion: { in: (1..10).to_a }
  validates :review, presence: true, length: { minimum: 1, maximum: 5000 }
  validates :user_id, uniqueness: { scope: :movie_id, message: "can only have one rating per movie" }
  validate :review_not_blank_if_present

  private

  def strip_review_whitespace
    if review.present?
      self.review = review.strip
      # Set to empty string if it becomes empty after stripping (will trigger validation)
      self.review = "" if review.empty?
    end
  end

  def review_not_blank_if_present
    # If a review is provided, ensure it's not just whitespace
    review_is_blank = review.present? && review.strip.blank?

    if review_is_blank
      errors.add(:review, "cannot be blank or contain only whitespace")
    end
  end
end
