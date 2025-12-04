class GenerateRecommendationsJob < ApplicationJob
  queue_as :default

  def perform(run_id)
    run = RecommendationRun.find_by(id: run_id)
    return unless run

    run.update(status: RecommendationRun::STATUSES[:in_progress], job_id: job_id, error_message: nil)

    recommendations = Recommender::Recommender.recommend_movies_for(run.user, limit: 20)
    serialized = recommendations.map { |movie| Recommender::MovieSerializer.call(movie) }

    run.update(
      status: RecommendationRun::STATUSES[:completed],
      movies: serialized,
      completed_at: Time.current
    )
  rescue StandardError => error
    run&.update(
      status: RecommendationRun::STATUSES[:failed],
      error_message: error.message
    )
    raise
  end
end
