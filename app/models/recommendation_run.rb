class RecommendationRun < ApplicationRecord
  belongs_to :user

  STATUSES = {
    pending: "pending",
    in_progress: "in_progress",
    completed: "completed",
    failed: "failed"
  }.freeze

  validates :status, inclusion: { in: STATUSES.values }

  scope :recent_first, -> { order(created_at: :desc) }

  def pending?
    status == STATUSES[:pending]
  end

  def in_progress?
    status == STATUSES[:in_progress]
  end

  def completed?
    status == STATUSES[:completed]
  end

  def failed?
    status == STATUSES[:failed]
  end
end
