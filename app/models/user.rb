class User < ApplicationRecord
  # Secure password
  has_secure_password validations: false

  # Associations
  has_many :diary_entries, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :ratings, dependent: :destroy
  has_many :watchlists, dependent: :destroy
  has_many :movies, through: :watchlists
  has_many :favorite_movies, through: :favorites, source: :movie
  has_many :review_reactions, dependent: :destroy
  has_many :top_movies, -> { where.not(top_position: nil).order(:top_position) }, class_name: "Favorite"

  # Follow associations
  has_many :active_follows, class_name: "Follow", foreign_key: "follower_id", dependent: :destroy
  has_many :passive_follows, class_name: "Follow", foreign_key: "followed_id", dependent: :destroy
  has_many :following, -> { where(follows: { status: "accepted" }) }, through: :active_follows, source: :followed
  has_many :followers, -> { where(follows: { status: "accepted" }) }, through: :passive_follows, source: :follower
  has_many :pending_follow_requests, -> { where(status: "pending") }, class_name: "Follow", foreign_key: "followed_id"

  # Notifications
  has_many :notifications, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }
  validates :username, presence: true, uniqueness: true, length: { minimum: 3, maximum: 20, message: "must be between 3 and 20 characters" }
  validates :password, presence: true, length: { minimum: 8, message: "must be at least 8 characters" }, if: :new_record?
  validates :password, confirmation: true, if: -> { password.present? }
  validates :password_confirmation, presence: true, if: -> { password.present? && new_record? }
  validates :first_name, length: { maximum: 50 }, allow_blank: true
  validates :last_name, length: { maximum: 50 }, allow_blank: true
  validates :bio, length: { maximum: 500 }, allow_blank: true
  validates :top_5_movies, length: { maximum: 1000 }, allow_blank: true

  # Custom password strength validation
  validate :password_strength, if: -> { password.present? && new_record? }

  # Follow methods
  def follow(other_user)
    return nil if self == other_user
    return active_follows.find_by(followed: other_user) if following?(other_user) || requested_follow?(other_user)

    status = other_user.is_private? ? "pending" : "accepted"
    active_follows.create(followed: other_user, status: status)
  end

  def unfollow(other_user)
    active_follows.find_by(followed: other_user)&.destroy
  end

  def following?(other_user)
    following.include?(other_user)
  end

  def requested_follow?(other_user)
    active_follows.pending.exists?(followed: other_user)
  end

  def followed_by?(other_user)
    followers.include?(other_user)
  end

  def follow_status(other_user)
    follow = active_follows.find_by(followed: other_user)
    return nil unless follow

    follow.status
  end

  def unread_notifications_count
    notifications.unread.count
  end

  private

  def password_strength
    return if password.blank?

    unless password.match?(/\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
      errors.add(:password, "must include at least one uppercase letter, one lowercase letter, and one number")
    end
  end
end
