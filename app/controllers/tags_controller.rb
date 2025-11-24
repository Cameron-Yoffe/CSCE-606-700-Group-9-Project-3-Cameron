class TagsController < ApplicationController
  before_action :require_login
  before_action :set_movie, only: [ :create, :destroy ]

  def create
    movie = @movie
    tag_id = params[:tag_id]

    unless tag_id.present?
      respond_to do |format|
        format.json { render json: { success: false, errors: [ "Tag ID is required" ] }, status: :unprocessable_entity }
        format.html { redirect_back fallback_location: movie_path(movie.tmdb_id), alert: "Tag is required." }
      end
      return
    end

    tag = Tag.find(tag_id)

    # Check if tag is already associated with the movie
    if movie.tags.exists?(tag.id)
      respond_to do |format|
        format.json { render json: { success: false, errors: [ "Tag already added" ] }, status: :unprocessable_entity }
        format.html { redirect_back fallback_location: movie_path(movie.tmdb_id), alert: "Tag already added to this movie." }
      end
      return
    end

    if movie.movie_tags.create(tag: tag)
      respond_to do |format|
        format.json { render json: { success: true, tag: { id: tag.id, name: tag.name } }, status: :created }
        format.html { redirect_back fallback_location: movie_path(movie.tmdb_id), notice: "Tag added successfully." }
      end
    else
      respond_to do |format|
        format.json { render json: { success: false, errors: [ "Could not add tag" ] }, status: :unprocessable_entity }
        format.html { redirect_back fallback_location: movie_path(movie.tmdb_id), alert: "Could not add tag." }
      end
    end
  end

  def destroy
    movie = @movie
    tag_id = params[:id]
    
    # Attempt to find and delete the movie_tag record
    movie_tag = movie.movie_tags.find_by(tag_id: tag_id)

    if movie_tag&.destroy
      respond_to do |format|
        format.json { render json: { success: true }, status: :ok }
        format.html { redirect_back fallback_location: movie_path(movie.tmdb_id), notice: "Tag removed successfully." }
      end
    else
      # If movie_tag not found, check if tag exists at all
      tag_exists = Tag.exists?(tag_id)
      error_message = tag_exists ? "Tag is not associated with this movie" : "Tag does not exist"
      
      respond_to do |format|
        format.json { render json: { success: false, errors: [ error_message ] }, status: :unprocessable_entity }
        format.html { redirect_back fallback_location: movie_path(movie.tmdb_id), alert: error_message }
      end
    end
  end

  private

  def set_movie
    movie_id = params[:movie_id]
    @movie = Movie.find(movie_id)
  end

  def require_login
    redirect_to sign_in_path unless logged_in?
  end
end
