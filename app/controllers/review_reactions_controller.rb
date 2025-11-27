class ReviewReactionsController < ApplicationController
  before_action :require_login
  before_action :set_rating

  def create
    emoji = params[:emoji]
    existing_reaction = @rating.review_reactions.find_by(user: current_user, emoji: emoji)

    if existing_reaction
      # If same emoji reaction, delete it (toggle off)
      existing_reaction.destroy
    else
      # Create new reaction
      ReviewReaction.create(rating: @rating, user: current_user, emoji: emoji)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "emoji-reactions-#{@rating.id}",
          partial: "emoji_reactions",
          locals: { user_rating: @rating, current_user: current_user }
        )
      end
      format.html { redirect_to movie_path(@rating.movie.tmdb_id), status: :see_other }
    end
  end

  private

  def set_rating
    @rating = Rating.find(params[:rating_id])
  end

  def require_login
    redirect_to sign_in_path unless logged_in?
  end
end
