class ReviewReaction < ApplicationRecord
  ALLOWED_EMOJIS = [ "👍", "👎", "💯", "🎉", "🔥", "😂", "😮", "😢", "🤔", "👏", "🤦", "☠️", "💰", "🐐", "🎊", "😭", "🤡", "😊", "🔮" ].freeze

  belongs_to :rating
  belongs_to :user

  validates :rating_id, :user_id, :emoji, presence: true
  validates :emoji, inclusion: { in: ALLOWED_EMOJIS, message: "is not allowed" }
  validates :user_id, uniqueness: { scope: [ :rating_id, :emoji ], message: "can only react once per emoji per review" }
end
