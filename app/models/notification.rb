class Notification < ApplicationRecord
  # Notification types
  TYPES = %w[follow_request new_follower follow_accepted].freeze

  # Associations
  belongs_to :user
  belongs_to :notifiable, polymorphic: true, optional: true

  # Validations
  validates :notification_type, presence: true, inclusion: { in: TYPES }

  # Scopes
  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc).limit(20) }

  def mark_as_read!
    update!(read: true)
  end

  def message
    return "This notification is no longer available" if notifiable.nil?

    case notification_type
    when "follow_request"
      "#{notifiable.follower&.username || 'Someone'} requested to follow you"
    when "new_follower"
      "#{notifiable.follower&.username || 'Someone'} started following you"
    when "follow_accepted"
      "#{notifiable.followed&.username || 'Someone'} accepted your follow request"
    else
      "You have a new notification"
    end
  end

  def actionable?
    notification_type == "follow_request" && notifiable&.pending?
  end
end
