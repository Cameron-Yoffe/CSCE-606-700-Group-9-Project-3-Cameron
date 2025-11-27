class RatingsController < ApplicationController
  before_action :require_login
  before_action :set_movie, only: [ :create, :update ]
  before_action :set_rating, only: [ :update ]

  def create
    @rating = current_user.ratings.build(rating_params)
    @rating.movie_id = @movie.id

    if @rating.save
      remove_from_watchlist(@movie)

      respond_to do |format|
        format.json { render json: { success: true, rating: @rating }, status: :created }
        format.html { redirect_to movie_path(@movie.tmdb_id), notice: "Rating saved successfully." }
      end
    else
      respond_to do |format|
        format.json { render json: { success: false, errors: @rating.errors.full_messages }, status: :unprocessable_entity }
        format.html { redirect_to movie_path(@movie.tmdb_id), alert: "Error saving rating." }
      end
    end
  end

  def update
    if @rating.update(rating_params)
      remove_from_watchlist(@movie)

      respond_to do |format|
        format.json { render json: { success: true, rating: @rating } }
        format.html { redirect_to movie_path(@movie.tmdb_id), notice: "Rating updated successfully." }
      end
    else
      respond_to do |format|
        format.json { render json: { success: false, errors: @rating.errors.full_messages }, status: :unprocessable_entity }
        format.html { redirect_to movie_path(@movie.tmdb_id), alert: "Error updating rating." }
      end
    end
  end

  private

  def set_movie
    if params[:movie_id].present?
      @movie = Movie.find(params[:movie_id])
    elsif params[:rating]&.fetch(:movie_id, nil).present?
      @movie = Movie.find(params[:rating][:movie_id])
    elsif params[:id].present?
      # For update action, find the rating first then get the movie
      @rating = current_user.ratings.find(params[:id])
      @movie = @rating.movie
    end
  end

  def set_rating
    if @rating.nil?
      @rating = current_user.ratings.find_by!(movie_id: @movie.id)
    end
  end

  def rating_params
    params.require(:rating).permit(:value, :review, :movie_id)
  end

  def require_login
    redirect_to sign_in_path unless logged_in?
  end

  def remove_from_watchlist(movie)
    current_user.watchlists.where(movie_id: movie.id).destroy_all
  end
end
