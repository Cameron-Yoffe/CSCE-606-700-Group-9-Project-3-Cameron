class RecomputeUserEmbeddingJob < ApplicationJob
  queue_as :default

  def perform(user_id, decay: true)
    user = User.find_by(id: user_id)
    return unless user

    Recommender::UserEmbedding.build_and_persist!(user, decay: decay)
  rescue StandardError => e
    Rails.logger.warn("RecomputeUserEmbeddingJob failed for user_id=#{user_id}: #{e.class}: #{e.message}")
  end
end
