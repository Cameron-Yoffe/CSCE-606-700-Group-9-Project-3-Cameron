class Follow < ApplicationRecord
  # Status constants
  STATUSES = %w[pending accepted].freeze

  # Associations
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"
  has_many :notifications, as: :notifiable, dependent: :destroy

  # Validations
  validates :follower_id, presence: true
  validates :followed_id, presence: true
  validates :follower_id, uniqueness: { scope: :followed_id, message: "is already following this user" }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :cannot_follow_self

  # Scopes
  scope :accepted, -> { where(status: "accepted") }
  scope :pending, -> { where(status: "pending") }

  # Callbacks
  after_create :create_notification

  def accepted?
    status == "accepted"
  end

  def pending?
    status == "pending"
  end

  def accept!
    update!(status: "accepted")
    create_follow_accepted_notification
  end

  def reject!
    destroy
  end

  private

  def cannot_follow_self
    errors.add(:followed_id, "cannot follow yourself") if follower_id == followed_id
  end

  def create_notification
    Notification.create!(
      user: followed,
      notifiable: self,
      notification_type: pending? ? "follow_request" : "new_follower"
    )
  end

  def create_follow_accepted_notification
    Notification.create!(
      user: follower,
      notifiable: self,
      notification_type: "follow_accepted"
    )
  end
end
