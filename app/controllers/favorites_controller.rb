class FavoritesController < ApplicationController
  before_action :require_login

  def index
    @favorites = current_user.favorites.includes(:movie).order(created_at: :desc)
  end

  def create
    movie = find_movie_from_params

    unless movie
      respond_to do |format|
        format.html { redirect_back fallback_location: movies_path, alert: "Movie not found" }
        format.json { render json: { error: "Movie not found" }, status: :not_found }
      end
      return
    end

    favorite = current_user.favorites.find_or_initialize_by(movie: movie)

    if favorite.persisted? || favorite.save
      respond_to do |format|
        format.html { redirect_back fallback_location: movies_path, notice: "Added to favorites" }
        format.json { render json: { success: true, favorite: favorite.as_json(include: :movie) }, status: :created }
      end
    else
      respond_to do |format|
        format.html { redirect_back fallback_location: movies_path, alert: favorite.errors.full_messages.to_sentence }
        format.json { render json: { error: favorite.errors.full_messages.to_sentence }, status: :unprocessable_entity }
      end
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

  def set_top_position
    favorite = current_user.favorites.find_by(id: params[:id])
    position = params[:position].to_i

    unless favorite
      render json: { error: "Favorite not found" }, status: :not_found
      return
    end

    unless (1..5).include?(position)
      render json: { error: "Position must be between 1 and 5" }, status: :unprocessable_entity
      return
    end

    # Check if position is already taken
    existing = current_user.favorites.find_by(top_position: position)
    if existing && existing.id != favorite.id
      # Swap positions
      existing.update(top_position: nil)
    end

    if favorite.update(top_position: position)
      render json: { success: true, favorite: favorite }
    else
      render json: { error: favorite.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def remove_top_position
    favorite = current_user.favorites.find_by(id: params[:id])

    unless favorite
      render json: { error: "Favorite not found" }, status: :not_found
      return
    end

    if favorite.update(top_position: nil)
      render json: { success: true }
    else
      render json: { error: favorite.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
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
