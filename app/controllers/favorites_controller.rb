class FavoritesController < ApplicationController
  before_action :require_login

  def index
    @favorites = current_user.favorites.includes(:movie).order(created_at: :desc)
  end

  def create
    movie = find_movie_from_params

    unless movie
      redirect_back fallback_location: movies_path, alert: "Movie not found"
      return
    end

    favorite = current_user.favorites.find_or_initialize_by(movie: movie)

    if favorite.persisted? || favorite.save
      redirect_back fallback_location: movies_path, notice: "Added to favorites"
    else
      redirect_back fallback_location: movies_path, alert: favorite.errors.full_messages.to_sentence
    end
  end

  def destroy
    favorite = current_user.favorites.find_by(id: params[:id])

    unless favorite
      redirect_back fallback_location: favorites_path, alert: "Favorite not found"
      return
    end

    favorite.destroy
    redirect_back fallback_location: favorites_path, notice: "Removed from favorites"
  end

  private

  def require_login
    redirect_to sign_in_path, alert: "You must be logged in" unless logged_in?
  end

  def find_movie_from_params
    movie_id = params[:movie_id]
    tmdb_id = params[:tmdb_id]
    title = params[:title]
    poster_url = params[:poster_url]

    return Movie.find_by(id: movie_id) if movie_id.present?

    return unless tmdb_id.present?

    Movie.find_or_create_by(tmdb_id: tmdb_id.to_i) do |movie|
      movie.title = title.presence || "Untitled"
      movie.poster_url = poster_url if poster_url.present?
    end
  end
end
