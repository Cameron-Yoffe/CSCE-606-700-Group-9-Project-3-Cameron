class ListsController < ApplicationController
  before_action :require_login

  def create
    @list = current_user.lists.new(list_params)
    movie_params = params[:movies] || []

    if @list.save
      attach_movies(@list, movie_params)
      redirect_to favorites_path(tab: "list-#{@list.id}"), notice: "List created"
    else
      redirect_to favorites_path, alert: @list.errors.full_messages.to_sentence
    end
  rescue ActionController::ParameterMissing
    redirect_to favorites_path, alert: "Please provide a list name"
  end

  def destroy
    list = current_user.lists.find_by(id: params[:id])

    unless list
      redirect_to favorites_path, alert: "List not found"
      return
    end

    list.destroy
    redirect_to favorites_path, notice: "List deleted"
  end

  private

  def require_login
    redirect_to sign_in_path, alert: "You must be logged in" unless logged_in?
  end

  def list_params
    params.require(:list).permit(:name, :description)
  end

  def attach_movies(list, movies_params)
    movies_params.each do |movie_param|
      movie = find_or_create_movie(movie_param)
      list.list_items.find_or_create_by(movie: movie) if movie
    end
  end

  def find_or_create_movie(movie_params)
    movie_id = movie_params[:movie_id]
    tmdb_id = movie_params[:tmdb_id]
    title = movie_params[:title]
    poster_url = movie_params[:poster_url]
    release_date = movie_params[:release_date]

    return Movie.find_by(id: movie_id) if movie_id.present?
    return unless tmdb_id.present?

    Movie.find_or_create_by(tmdb_id: tmdb_id.to_i) do |movie|
      movie.title = title.presence || "Untitled"
      movie.poster_url = poster_url if poster_url.present?
      movie.release_date = release_date if release_date.present?
    end
  end
end
