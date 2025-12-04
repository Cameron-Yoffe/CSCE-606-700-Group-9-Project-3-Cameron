class RecommendationsController < ApplicationController
  before_action :require_login

  def show
    @run = latest_run

    if @run.nil? || @run.failed?
      @run = start_run!
    elsif (@run.pending? || @run.in_progress?) && @run.job_id.blank?
      enqueue_run(@run)
    end

    @status = @run&.status || RecommendationRun::STATUSES[:pending]
    @recommendations = @run&.completed? ? @run.movies : []
  end

  def refresh
    run = start_run!
    render json: { run_id: run.id, status: run.status }
  end

  def status
    run = params[:run_id].present? ? current_user.recommendation_runs.find_by(id: params[:run_id]) : latest_run
    return head :not_found unless run

    render json: {
      run_id: run.id,
      status: run.status,
      recommendations: run.completed? ? run.movies : []
    }
  end

  private

  def latest_run
    current_user.recommendation_runs.recent_first.first
  end

  def start_run!
    run = current_user.recommendation_runs.create!(status: RecommendationRun::STATUSES[:pending])
    enqueue_run(run)
    run
  end

  def enqueue_run(run)
    GenerateRecommendationsJob.perform_later(run.id)
  end

  def require_login
    redirect_to sign_up_path, alert: "You must be logged in" unless logged_in?
  end
end
